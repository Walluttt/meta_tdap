using JuMP, Gurobi, Printf
import MultiObjectiveAlgorithms as MOA

include("../../loadTDAP.jl")
include("../../getfname.jl")
include("../../texTables.jl")
include("../../print_graph.jl")

global all     = true
global verbose = false
global table   = true

function model_moa_2009(filename)

    println("\nModel_2009_with_Julia : \n")

    results = Any[]

    v::Int64 = 1

    if (all) 
        v = length(filename)
    end

    for w = 1:v

        #=
        if (all)
            println("Instance : ", filename, "_", i)
            instance = loadTDAP(string(filename,"_",i)) 
        else
            instance = loadTDAP(filename)

            if (verbose)
                println("Instance : ", instance)
            end
        end
        =#

        if(all)
            println("Instance : ", filename[w])
            instance = loadTDAP(filename[w])
        else
            println("Instance : ", filename)
            instance = loadTDAP(filename)
        end


        n = instance.n  # n number of trucks
        m = instance.m  # m number of docks

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
        
        @variable(model, y[1:n,1:m], Bin)
        @variable(model, z[1:n,1:n,1:m,1:m], Bin)

        @expression(model, cost, sum(instance.c[k,l]*instance.t[k,l]*z[i,j,k,l] for k in 1:m, l in 1:m, i in 1:n, j in 1:n))
        @expression(model, penality, sum(sum(instance.p[i,j]*instance.f[i,j]*(1-sum(z[i,j,k,l] for l in 1:m, k in 1:m )) for j in 1:n ) for i in 1:n ))

        @objective(model, Min, [cost,penality])

        @constraint(model, affectation[i in 1:n] ,sum(y[i,k] for k in 1:m) <= 1)
        @constraint(model, logicZ1[i in 1:n,j in 1:n, k in 1:m, l in 1:m; i!=j], z[i,j,k,l] <= y[i,k])
        @constraint(model, logicZ2[i in 1:n,j in 1:n, k in 1:m, l in 1:m; i!=j], z[i,j,k,l] <= y[j,l])
        @constraint(model, penalty[i in 1:n, j in 1:n,k in 1:m, l in 1:m; i!=j], y[i,k] + y[j,l] - 1 <= z[i,j,k,l])
        @constraint(model, dock[i in 1:n, j in 1:n, k in 1:m; i!=j], instance.x[i,j] + instance.x[j,i] >= z[i,j,k,k])
        @constraint(model, pallets[r in 1:2n], sum(sum( instance.f[i,j]*z[i,j,k,l] for i in arr_t[r], j in 1:n ) for k in 1:m,l in 1:m) - sum(sum( instance.f[i,j]*z[i,j,k,l] for i in 1:n, j in dep_t[r] ) for k in 1:m,l in 1:m) <= instance.C )
        @constraint(model, time_window[i in 1:n, j in 1:n,k in 1:m, l in 1:m; i!=j], instance.f[i,j]*z[i,j,k,l]*(instance.d[j]-instance.a[i]-instance.t[k,l]) >= 0)


        set_optimizer_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())
        set_optimizer_attribute(model, MOA.EpsilonConstraintStep(), rand())
        set_silent(model)

        t_TDAP = @elapsed(optimize!(model))
        

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

        println("Z optimal : ", z_sol)
        println("Time      : ", trunc(t_TDAP, digits=3), "sec")

        deli_cpt = 0
        deli_done_cpt = 0
        for i in 1:n , j in 1:n
            if instance.f[i,j] > 0
                deli_cpt += 1
                for k in 1:m,l in 1:m
                    if (value.(z))[i,j,k,l] == 1 
                        println("z[$i,$j,$k,$l] and f[$i,$j]=",instance.f[i,j])
                        deli_done_cpt +=1
                    end
                end
            end
        end

        push!(results, (z_sol,trunc(t_TDAP, digits=3),deli_cpt,deli_done_cpt))

        empty!(model)
        println(" ------------------- ")
    end

    
    return results
end

function data_dir(filename::String)
    files = readdir(filename)
    data = Set("")
    for file in files
        str  = split(file,".")
        union!(data,String(str[1])) 
    end
    @show data
    return data
end

## ====================================================================================
## Main program

if (all) 
    #filename = "./data/data_10_3/data_10_3"
    data = ["../../exemple","../../data/data_10_3/data_10_3_0","../../data/data_10_3/data_10_3_1","../../data/data_10_3/data_10_3_2","../../data/data_10_3/data_10_3_3","../../data/data_10_3/data_10_3_4"]
    data_comp = ["example","10_3_0","10_3_1","10_3_2","10_3_3","10_3_4"]
    real = ["../../data/inst_reel/inst_reel_$i" for i in 1:10]
    real_comp = [split(real[i],"/")[5] for i in eachindex(real)]

    results = model_moa_2009(data)

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

        latex = to_table_moa(data_comp , t_value_1, t_value_2, t_time,t_delivery,t_delivery_done,ratio_delivery)
        latex |> print
        to_tex(latex) |> print
        info=[data_comp,t_value_1,t_value_2,t_delivery,t_delivery_done,ratio_delivery,t_time]
        #savefig(graph_bi(info,"model_bi_2009"),"../../fig/model_bi_2009.png")
    end
    return

else
    data = "../exemple"
    results = model2009(data)
    return
end