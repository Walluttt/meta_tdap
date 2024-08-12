using JuMP,Gurobi, Printf, TexTables, Random
import MultiObjectiveAlgorithms as MOA

include("../loadTDAP.jl")
include("../getfname.jl")
include("../texTables.jl")
include("../solution_checker.jl")


global all     = true
global verbose = false
global table   = true

function print_problem_and_variabe(instance::instance,z::Array{Float64, 4},time_ratio::Float64)
  number_of_delivery = 0
  for i in 1:instance.n, j in 1:instance.n
    if instance.f[i,j] > 0
      number_of_delivery += 1
      print(i, " ---> ",j," ",instance.f[i,j],",\n")
      for k in 1:instance.m, l in 1:instance.m
        if z[i,j,k,l] == 1
          print(" delivery done from bay ", k, " to bay ", l," time taken ",time_ratio*instance.t[k,l],"\n")
        elseif instance.d[j] - instance.a[i] - time_ratio*instance.t[k,l]<=0
          @printf(" t_%i and t_%i %.2f overlap | %.2f time unite b_%i to b_%i\n",i,j,instance.d[j] - instance.a[i],time_ratio*instance.t[k,l],k,l)
        else 
          @printf("------- t_%i and t_%i %.2f overlap | %.2f time unite b_%i to b_%i\n",i,j,instance.d[j] - instance.a[i],time_ratio*instance.t[k,l],k,l)
        end
       
      end
      print("\n")
    end
  end
  println("number_of_delivery : ", number_of_delivery)
  return number_of_delivery
end

function z_to_1(z::Array{Float64,4},n,m)
    number_of_delivery_done = 0
    for i in 1:n, j in 1:n,k in 1:m,l in 1:m
        if (value.(z))[i,j,k,l] == 1
            println("z[",i,",",j,",",k,",",l,"]") 
            number_of_delivery_done += 1
        end
    end
    println("number of delivery done : " , number_of_delivery_done)
    return number_of_delivery_done
end

function model_tdap(filename)  
    
    println("\nModel_with_Julia : \n")
    
    model     = Model(Gurobi.Optimizer)
    results = Any[]
    time_ratio = 1.0

    v::Int64 = 1

    if (all) 
        v = length(data)
    end

    for w = 1:v

        if(all)
            println("Instance : ", filename[w])
            instance = loadTDAP(filename[w])
        else
            println("Instance : ", filename)
            instance = loadTDAP(filename)
        end


        n = instance.n
        m = instance.m


        tr = Float64[]
        append!(tr, instance.a, instance.d)
        sort!(tr)

        dep_t = Any[]
        for r in 1:2n
            current = Int64[]
            for i in 1:n
                if instance.d[i] <= tr[r]
                    push!(current, i)
                end
            end
            push!(dep_t, current)
        end
    
        arr_t = Any[]
        for r in 1:2n
            current = Int64[]
            for i in 1:n
                if instance.a[i] <= tr[r]
                    push!(current, i)
                end
            end
            push!(arr_t, current)
        end    

        model = Model(() -> MOA.Optimizer(Gurobi.Optimizer))
        @variable(model, y[1:n,1:m],Bin)
        @variable(model, z[1:n,1:n,1:m,1:m], Bin)

        println("number of pallets to delivered : ",sum(instance.f[i,j] for i in 1:n, j in 1:n))
        
        # objective function without monetary transformation
        @expression(model,time,sum(instance.f[i,j]*instance.t[k,l]*z[i,j,k,l] for i in 1:n, j in 1:n,k in 1:m,l in 1:m))
        @expression(model, non_delivered,sum((sum(instance.f[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n))
        
        # objectives functoins with monetary transformation :
        @expression(model,time_cost,sum(instance.c[k,l]*instance.f[i,j]*instance.t[k,l]*z[i,j,k,l] for i in 1:n, j in 1:n,k in 1:m,l in 1:m))
        @expression(model, non_delivered_penality,sum((sum(instance.f[i,j] * instance.p[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n))

        # differentes try :
        @expression(model, delivered, sum((sum(instance.f[i,j]* (sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n))
        
        @objective(model, Min, [time, non_delivered]) 

        # constraint (2)
        @constraint(model, cst2_[i=1:n], sum(y[i,k] for k=1:m) <= 1)
        ## constraint (3)
        @constraint(model, cst3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])
        ## constraint (4)
        @constraint(model, cst4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])
        # constraint (5)
        #@constraint(model, cst5_[i=1:n, j=1:n, k=1:m; i!=j], y[i,k] + y[j,k] <= 1 + instance.x[i,j] + instance.x[j,i])
        # constraint (6)
        #@constraint(model, cst6_[i=1:n, j=1:n, k=1:m; i!=j],z[i,j,k,k] <= instance.x[i,j] )
        # constraint (7)
        #@constraint(model, cst7_[r=1:2*n], sum(instance.f[i,j] * z[i,j,k,l] for i in arr_t[r], j=1:n, k=1:m, l=1:m)-sum(instance.f[i,j] * z[i,j,k,l] for i=1:n, j in dep_t[r], k=1:m, l=1:m)<= instance.C)
        # constraint (8)
        @constraint(model, cst8_[i=1:n, j=1:n, k=1:m, l=1:m; i!=j && (instance.d[j] - instance.a[i] - time_ratio * instance.t[k,l])<=0 ], z[i,j,k,l] == 0)

        @constraint(model,cst9_[i=1:n, j=1:n, k=1:m],z[i,j,k,k]==0)

        set_optimizer_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())
        set_optimizer_attribute(model, MOA.EpsilonConstraintStep(), 0.5)
        set_silent(model)
        
        t_TDAP = @elapsed(optimize!(model))
        solution_summary(model)


        if (verbose)
            @show instance
            @show instance.x
            @show instance.C
            @show instance.t
            @show instance.c
            @show instance.f
            @show instance.p
            @show instance.a 
            @show instance.d
            @show tr
            @show dep_t
            @show arr_t
            @show termination_status(model)
            @show objective_value(model)
        end

        z_sol = objective_value(model)
        # I put this here because it's the number of delivery done 
        #and it's positive 
        #z_sol[2] = - z_sol[2] 

        println("Z optimal : ", z_sol)
        println("Time      : ", trunc(t_TDAP, digits=3), "sec")

        println(" la solution est admisible : ", solution_checker(instance, value.(y),value.(z)))
        #@show value.(y)
        #@show value.(z)
        number_of_delivery = print_problem_and_variabe(instance,value.(z),time_ratio)
        number_of_delivery_done = z_to_1(value.(z),n,m)
        

        push!(results, (z_sol,trunc(t_TDAP, digits=3),number_of_delivery,number_of_delivery_done))

        empty!(model)
        println(" ------------------- ")
    end

    return results
end

## ====================================================================================
## Main program

if (all) 
    #filename = "./data/data_10_3/data_10_3"
    data = ["../exemple","../data/data_10_3/data_10_3_0","../data/data_10_3/data_10_3_1","../data/data_10_3/data_10_3_2","../data/data_10_3/data_10_3_3","../data/data_10_3/data_10_3_4"]
    results = model_tdap(data)

    # Editing a clean table to present the results
    if (table)
        println("\nEdition of results ----------------------------------------------")
        println("Nb instances : ", length(results))
    
        t_time = Any[]
        t_value_1 = Any[]
        t_value_2 = Any[]
        t_delivery = []
        t_delivery_done = []
    
        for i in eachindex(results)
            push!(t_value_1, results[i][1][1])
            push!(t_value_2, results[i][1][2])
            push!(t_time, results[i][2])
            push!(t_delivery,results[i][3])
            push!(t_delivery_done,results[i][4])
        end

        ratio_delivery = []
        for i in eachindex(t_delivery)
            push!(ratio_delivery,trunc(t_delivery_done[i]/t_delivery[i],digits=2))
        end

        latex = to_table_moa(data , t_value_1, t_value_2, t_time,t_delivery,t_delivery_done)
        latex |> print
        #to_tex(latex) |> print
        @show ratio_delivery
    end
    return

else
    data = "../exemple"
    results = model_tdap(data)
    return
end


#function print_problem(instance::instance)
#    for i in 1:n, j in 1:n
#        println("[o=o,",i,"] --->"," ",instance.f[i,j] ," [o=o,",j,"]")
#    end
#end