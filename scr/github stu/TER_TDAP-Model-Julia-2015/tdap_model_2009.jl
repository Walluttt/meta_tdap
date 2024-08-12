using JuMP, Printf, Gurobi

include("loadTDAP.jl")
include("getfname.jl")
include("texTables.jl")
include("print_graph.jl")

global all     = true
global verbose = false
global table   = true
global cpt     = 0

function model2009(filename)

    println("\nModel_2009_with_Julia : \n")

    model = Model(Gurobi.Optimizer)
    results = Any[]

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

        
        @variable(model, y[1:n,1:m], Bin)
        @variable(model, z[1:n,1:n,1:m,1:m], Bin)

        @expression(model, cost, sum(instance.c[k,l]*instance.t[k,l]*z[i,j,k,l] for k in 1:m, l in 1:m, i in 1:n, j in 1:n))
        @expression(model, penality, sum(sum(instance.p[i,j]*instance.f[i,j]*(1-sum(z[i,j,k,l] for l in 1:m, k in 1:m )) for j in 1:n ) for i in 1:n ))

        @objective(model, Min, cost + penality)

        @constraint(model, affectation[i in 1:n] ,sum(y[i,k] for k in 1:m) <= 1)
        @constraint(model, logicZ1[i in 1:n,j in 1:n, k in 1:m, l in 1:m; i!=j], z[i,j,k,l] <= y[i,k])
        @constraint(model, logicZ2[i in 1:n,j in 1:n, k in 1:m, l in 1:m; i!=j], z[i,j,k,l] <= y[j,l])
        @constraint(model, penalty[i in 1:n, j in 1:n,k in 1:m, l in 1:m; i!=j], y[i,k] + y[j,l] - 1 <= z[i,j,k,l])
        @constraint(model, dock[i in 1:n, j in 1:n, k in 1:m; i!=j], instance.x[i,j] + instance.x[j,i] >= z[i,j,k,k])
        @constraint(model, pallets[r in 1:2n], sum(sum( instance.f[i,j]*z[i,j,k,l] for i in arr_t[r], j in 1:n ) for k in 1:m,l in 1:m) - sum(sum( instance.f[i,j]*z[i,j,k,l] for i in 1:n, j in dep_t[r] ) for k in 1:m,l in 1:m) <= instance.C )
        @constraint(model, time_window[i in 1:n, j in 1:n,k in 1:m, l in 1:m; i!=j], instance.f[i,j]*z[i,j,k,l]*(instance.d[j]-instance.a[i]-instance.t[k,l]) >= 0)

        t_TDAP = 0.0
        start     = time()
        optimize!(model)
        t_TDAP = time()-start
        

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

        obj = objective_value(model)

        println("Z optimal : ", obj)
        println("Time      : ", trunc(t_TDAP, digits=3), "sec")

        delivery_done = 0
        for i in 1:n
            for j in 1:n
                if instance.f[i,j] > 0
                    for k in 1:m
                        for l in 1:m
                            if (value(z[i,j,k,l]) == 1)
                                if verbose
                                    println(i, ", ",j, ", ", k,", ", l, ": ", value(z[i,j,k,l]) )
                                end
                                delivery_done += 1
                            end
                        end
                    end
                end
            end
        end

        push!(results, (obj,trunc(t_TDAP, digits=3),delivery_done))

        empty!(model)
        println(" ------------------- ")
    end
    
    return results
end

## ====================================================================================
## Main program

if (all) 
    #filename = "./data/data_10_3/data_10_3"
    data = ["exemple","./data/data_10_3/data_10_3_0","./data/data_10_3/data_10_3_1","./data/data_10_3/data_10_3_2","./data/data_10_3/data_10_3_3","./data/data_10_3/data_10_3_4"]
    data_comp = ["example","10_3_0","10_3_1","10_3_2","10_3_3","10_3_4"]


    data_all = ["exemple",
            "./data/data_10_3/data_10_3_0",
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


    results = model2009(data)

    if (table)
        println("\nEdition of results ----------------------------------------------")
        println("Nb instances : ", length(results))
        
        t_time = Any[]
        t_value = Any[]
        t_delivery_done = []
        ratio_delivery = []
        
        for i in eachindex(results)
            push!(t_time, results[i][2])
            push!(t_value, results[i][1])
            push!(t_delivery_done,results[i][3])        
        end
        
        #for i in eachindex(t_delivery)
        #    push!(ratio_delivery,trunc(t_delivery_done[i]/t_delivery[i],digits=3))
        #end
        #info = [data_comp,t_value,t_delivery,t_delivery_done,ratio_delivery,t_time]
        
        #savefig(graph_mono(info,"model_mono_2009"),"fig/model_mono_2009.png")


        latex = to_table(data_comp, t_value, t_time, t_delivery_done)
        latex |> print
        to_tex(latex) |> print
    end
    return

else
    data = "didactique3"
    results = model2009(data)
    return
end
