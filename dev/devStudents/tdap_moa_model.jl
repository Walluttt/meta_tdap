using JuMP,Gurobi,DataFrames, Printf, TexTables, Random,PyPlot,Plots
import MultiObjectiveAlgorithms as MOA
import PyPlot: plot as pyplot_plot,savefig as pyplot_savefig

include("loadTDAP.jl")
include("getfname.jl")
include("texTables.jl")
include("solution_checker.jl")
include("print_graph.jl")


global all     = true
global verbose = false
global table   = true
global stat    = false 

function print_problem_and_variabe(inst::instance,z::Array{Float64, 4})
    for i in 1:inst.n, j in 1:inst.n
            print(i, "---> ",j," ",inst.f[i,j])
            for k in 1:inst.m, l in 1:inst.m
                if z[i,j,k,l] == 1
                    print(" delivery donne from bay ", k, " to bay ", l)
                end
            end
        print("\n")
    end
    println("number_of_delivery : ", number_of_delivery)
    return number_of_delivery
end

function nb_deli(inst::instance)
    number_of_delivery = 0
    for i in 1:inst.n, j in 1:inst.n
        if inst.f[i,j] > 0
            number_of_delivery += 1
        end
    end
    return number_of_delivery
end

function print_z_to_1(z::Array{Float64,4},instance,n,m)
    for i in 1:n, j in 1:n,k in 1:m,l in 1:m
        if (value.(z))[i,j,k,l] == 1
            println("z[$i,$j,$k,$l], f[$i,$j]=",instance.f[i,j])         
        end
    end
end

function z_to_1(z::Array{Float64,4},f,n,m)
    nb_deli_done = 0
    pallets_transfer = 0
    for i in 1:n,j in 1:n
        for k in 1:m,l in 1:m
            if (value.(z))[i,j,k,l] == 1
                pallets_transfer += f[i,j]
                nb_deli_done +=1
            end
        end
    end
    return nb_deli_done,pallets_transfer
end

function graph_with_bi(args,info)
    if length(args) > 0
        ind_t = ["t","tc"]
        ind_c = ["nd","ndp","d"]
        title="model_bi_"*ind_t[args[1]]*"_"*ind_c[args[2]]
        savefig(graph_bi(info,title),"fig/"*title*".png")
    else 
        Plots.savefig(graph_bi(info,"model_bi"),"fig/model_bi.png")
    end
end

function graph_eps(filename)
    k=0
    ratio_deli = []
    ϵ = 0.5:-0.01:0.01
    for eps in ϵ
        results = model_tdap(filename,[1,1],eps)
        nb_delivery = results[1][3]
        nb_done = results[1][4]
        push!(ratio_deli,nb_done/nb_delivery)
        k+=1
    end
    fig_title = split(filename,"/")[4]
    fig = Plots.plot(ϵ,ratio_deli,xlabel="epsilon",ylabel="ratio_delivery",title=fig_title)
    ylims!(0,1)
    Plots.savefig(fig,"fig/epsilon/"*fig_title*".png")
end


function graph_eps_all(data)
    for file in data
        graph_eps(file)
    end
end

function model_tdap(filename,args,ϵ)  
    
    println("\nModel_with_Julia : \n")
    
    model     = Model(Gurobi.Optimizer)
    results = Any[]

    v::Int64 = 1

    if (all) 
        v = length(filename)
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
        @expression(model,time,sum(instance.t[k,l]*z[i,j,k,l] for i in 1:n, j in 1:n,k in 1:m,l in 1:m))
        @expression(model, non_delivered,sum((sum(instance.f[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n))
        
        # objectives functoins with monetary transformation :
        @expression(model,time_cost,sum(instance.c[k,l]*instance.f[i,j]*instance.t[k,l]*z[i,j,k,l] for i in 1:n, j in 1:n,k in 1:m,l in 1:m))
        @expression(model, non_delivered_penality,sum((sum(instance.f[i,j] * instance.p[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n))

        # differentes try :
        #this expression must be on maximisation thus the minus
        @expression(model, delivered, -sum((sum(instance.f[i,j]* (sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n))
        
        expression_time = [time,time_cost]
        expression_cost = [non_delivered,non_delivered_penality,delivered]

        @objective(model, Min, [expression_cost[args[1]], expression_time[args[2]]]) 





        # constraint (2)
        @constraint(model, cst2_[i=1:n], sum(y[i,k] for k=1:m) <= 1)
        # constraint (3)
        @constraint(model, cst3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])
        # constraint (4)
        @constraint(model, cst4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])
        # constraint (5)
        @constraint(model, cst5_[i=1:n, j=1:n, k=1:m; i!=j], y[i,k] + y[j,k] <= 1 + instance.x[i,j] + instance.x[j,i])
        # constraint (6)
        @constraint(model, cst6_[i=1:n, j=1:n, k=1:m; i!=j],z[i,j,k,k] <= instance.x[i,j] )
        # constraint (7)
        @constraint(model, cst7_[r=1:2*n], sum(instance.f[i,j] * z[i,j,k,l] for i in arr_t[r], j=1:n, k=1:m, l=1:m)-sum(instance.f[i,j] * z[i,j,k,l] for i=1:n, j in dep_t[r], k=1:m, l=1:m)<= instance.C)
        # constraint (8)
        @constraint(model, cst8_[i=1:n, j=1:n, k=1:m, l=1:m; i!=j && (instance.d[j] - instance.a[i] - instance.f[i,j] *instance.t[k,l])<=0 ], z[i,j,k,l] == 0)
        
        set_optimizer_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())
        set_optimizer_attribute(model, MOA.EpsilonConstraintStep(),1)
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

        println("Z optimal : ", z_sol)
        println("Time      : ", trunc(t_TDAP, digits=3), "sec")

        println(" la solution est admisible : ", solution_checker(instance, value.(y),value.(z)))

        #print_z_to_1(value.(z),instance,n,m)
        number_of_delivery = nb_deli(instance)
        number_of_delivery_done,pallets_transfer = z_to_1(value.(z),instance.f,n,m)
        

        push!(results, (z_sol,trunc(t_TDAP, digits=3),number_of_delivery,number_of_delivery_done,pallets_transfer))

        empty!(model)
        println(" ------------------- ")
    end

    return results
end

function main(all,stat,table,args,data,ϵ)
    if (all) 
        if length(args) > 0
            results = model_tdap(data,args,ϵ)
        else 
            results = model_tdap(data,[1,1],ϵ)
        end

        data_comp = [split(data[i],"/")[4] for i in eachindex(data)]

        
        println("\nEdition of results ----------------------------------------------")
        println("Nb instances : ", length(results))
        
        t_time = Any[]
        t_value_1 = Any[]
        t_value_2 = Any[]
        t_delivery = []
        t_delivery_done = []
        t_pallets = []

        for i in eachindex(results)
            push!(t_value_1, results[i][1][1])
            push!(t_value_2, results[i][1][2])
            push!(t_time, results[i][2])
            push!(t_delivery,results[i][3])
            push!(t_delivery_done,results[i][4])
            push!(t_pallets,results[i][5])
        end
        
        ratio_delivery = []
        for i in eachindex(t_delivery)
            push!(ratio_delivery,trunc(t_delivery_done[i]/t_delivery[i],digits=3))
        end
        
        # Editing a clean table to present the results
        if table
            latex = to_table_moa(data_comp , t_value_1, t_value_2, t_time,t_delivery,t_delivery_done,t_pallets)
            latex |> print
            to_tex(latex) |> print
        end
        @show ϵ
            
        if stat
            info = [data_comp,t_value_1,t_value_2,t_delivery,t_delivery_done,ratio_delivery,t_time]
            graph_with_bi(args,info)
            return 
        end
        
    else
        data = "./data/inst_reel/inst_reel_5"
        results = model_tdap(data,[1,1],ϵ)
        return results
    end
    
end


## ====================================================================================
## Main program
args = []
for i in eachindex(ARGS)
    push!(args, parse(Int64,ARGS[i]))
end

#filename = "./data/data_10_3/data_10_3"
data = ["./data/data_10_3/data_10_3_$i" for i in 0:4]
real = ["./data/inst_reel/inst_reel_$i" for i in 1:10]

data_all = ["./data/data_10_3/data_10_3_0",
            "./data/data_10_3/data_10_3_1",
            "./data/data_10_3/data_10_3_2",
            "./data/data_12_4/data_12_4_0",
            "./data/data_12_4/data_12_4_1",
            "./data/data_12_4/data_12_4_2",
            "./data/data_12_6/data_12_6_0",
            "./data/data_12_6/data_12_6_1",
            "./data/data_12_6/data_12_6_2",
            "./data/data_14_4/data_14_4_0",
            "./data/data_14_4/data_14_4_1",
            "./data/data_14_4/data_14_4_2",
            "./data/data_14_6/data_14_6_0",
            "./data/data_14_6/data_14_6_1",
            "./data/data_14_6/data_14_6_2",
            "./data/data_16_4/data_16_4_0",
            "./data/data_16_4/data_16_4_1",
            "./data/data_16_4/data_16_4_2",
            "./data/data_16_6/data_16_6_0",
            "./data/data_16_6/data_16_6_1",
            "./data/data_16_6/data_16_6_2",
            "./data/data_18_4/data_18_4_0",
            "./data/data_18_4/data_18_4_1",
            "./data/data_18_4/data_18_4_2",
            "./data/data_18_6/data_18_6_0",
            "./data/data_18_6/data_18_6_1",
            "./data/data_18_6/data_18_6_2",
            "./data/data_20_6/data_20_6_0",
            "./data/data_20_6/data_20_6_1",
            "./data/data_20_6/data_20_6_2",
            "./data/data_20_8/data_20_8_0",
            "./data/data_20_8/data_20_8_1",
            "./data/data_20_8/data_20_8_2",
            "./data/data_25_6/data_25_6_0",
            "./data/data_25_6/data_25_6_1",
            "./data/data_25_6/data_25_6_2",
            "./data/data_25_8/data_25_8_0",
            "./data/data_25_8/data_25_8_1",
            "./data/data_25_8/data_25_8_2",
            "./data/data_30_6/data_30_6_0",
            "./data/data_30_6/data_30_6_1",
            "./data/data_30_6/data_30_6_2",
            "./data/data_30_8/data_30_8_0",
            "./data/data_30_8/data_30_8_1",
            "./data/data_30_8/data_30_8_2",
            #"./data/data_35_8/data_35_8_0",
            #"./data/data_35_8/data_35_8_1",
            #"./data/data_35_8/data_35_8_2",
            #"./data/data_40_8/data_40_8_0",
            #"./data/data_40_8/data_40_8_1",
            #"./data/data_40_8/data_40_8_2",
            ]

ϵ = 1

main(all,stat,table,args,real,ϵ)