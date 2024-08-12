using JuMP, GLPK, Printf, TexTables, Gurobi, DataFrames, Plots

include("loadTDAP.jl")
include("getfname.jl")
include("texTables.jl")
include("solution_checker.jl")


global all     = false
global verbose = true
global table   = true
global cpt     = 0


function model_tdap(filename)  
    
    println("\nModel_with_Julia : \n")
    
    results = Any[]
    yn1 = []
    yn2 = []
    yfiltred1 = []
    yfiltred2 = []
    t_time = 0

    v::Int64 = 1

    if (all) 
        v = length(filename)
    end

    for w = 1:v

        if all
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

        mod = Model(Gurobi.Optimizer)
        @variable(mod, y[1:n,1:m], Bin)
        @variable(mod, z[1:n,1:n,1:m,1:m], Bin)
        @objective(mod, Min, sum( instance.t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m)) 
                             #+sum( (sum( instance.p[i,j] * instance.f[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n))        
        
        # constraint (2)
        @constraint(mod, cst2_[i=1:n], sum(y[i,k] for k=1:m) <= 1)
        # constraint (3)
        @constraint(mod, cst3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])
        # constraint (4)
        @constraint(mod, cst4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])
        # constraint (5)
        @constraint(mod, cst5_[i=1:n, j=1:n, k=1:m; i!=j], y[i,k] + y[j,k] <= 1 + instance.x[i,j] + instance.x[j,i])
        # constraint (6)
        @constraint(mod, cst6_[i=1:n, j=1:n, k=1:m; i!=j],z[i,j,k,k] <= instance.x[i,j] )
        # constraint (7)
        @constraint(mod, cst7_[r=1:2*n], sum(instance.f[i,j] * z[i,j,k,l] for i in arr_t[r], j=1:n, k=1:m, l=1:m)-sum(instance.f[i,j] * z[i,j,k,l] for i=1:n, j in dep_t[r], k=1:m, l=1:m)<= instance.C)
        # constraint (8)
        @constraint(mod, cst8_[i=1:n, j=1:n, k=1:m, l=1:m; i!=j && (instance.d[j] - instance.a[i] - instance.f[i,j] * instance.t[k,l])<=0 ], z[i,j,k,l] == 0)


        @variable(mod, const_term)
        @constraint(mod,e_constraint,sum( (sum(  instance.f[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n) <= const_term)

        set_silent(mod)

        t_TDAP = @elapsed(optimize!(mod))


        if (false)
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
            @show termination_status(mod)
            @show objective_value(mod)
        end

        z_sol = objective_value(mod)

        println("Z optimal : ", z_sol)
        
        println(" la solution est admisible : ", solution_checker(instance, value.(y),value.(z)))

        nb_palletes = 0
        deli_to_do = 0
        cpt = 0
        for i in 1:n
            for j in 1:n
                if instance.f[i,j] > 0
                    deli_to_do +=1
                end
                for k in 1:m
                    for l in 1:m
                        if (value(z[i,j,k,l]) == 1)
                            nb_palletes += instance.f[i,j]
                            if verbose
                                println(i, ", ",j, ", ", k,", ", l, ": ", instance.f[i,j] )
                            end
                            cpt += 1
                        end
                    end
                end
            end
        end
        println("nb palettes deli ",nb_palletes)
        p_to_deli = sum(instance.f[i,j] for i in 1:n,j in 1:n)
        
        z_opt = value.(z)
        println("objectif time : ", sum(instance.t[k,l]*z_opt[i,j,k,l] for i in 1:n, j in 1:n,k in 1:m,l in 1:m))
        println("objectif pallets : ",sum((sum(instance.f[i,j] * ( 1 - sum( z_opt[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n))
        
        
        while termination_status(mod) == OPTIMAL
            z_opt = value.(z)
            f1 = sum(instance.t[k,l]*z_opt[i,j,k,l] for i in 1:n, j in 1:n,k in 1:m,l in 1:m)
            f2 = sum((sum(instance.f[i,j] * ( 1 - sum( z_opt[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n)
            push!(yn1,trunc(f1,digits=3))
            push!(yn2,f2)
            
            #println(trunc(f1,digits=3)," ",f2)
            
            fix(const_term, f2 - 1)
            t_time += @elapsed(optimize!(mod))
        end
        println("Time      : ", trunc(t_TDAP, digits=3), "sec")
        
        

        n_d = false
        cond = true
        for i in eachindex(yn1)
            for j in eachindex(yn2)
                if i!=j
                    if !(yn1[j] <= yn1[i] && yn2[j] <= yn2[i])         
                        n_d = true                    
                    else
                        n_d = false
                        break
                    end
                end
            end
            if n_d
                push!(yfiltred1,yn1[i])
                push!(yfiltred2,yn2[i])
            end
            n_d = false
            cond = true
        end
        
        #println(yfiltred1)
        #println(yfiltred2)
        println("pareto front cardinal ",length(yfiltred1))
        println("XwE cardinal ",length(yn1))
        
        push!(results, (z_sol,trunc(t_TDAP, digits=3),cpt,nb_palletes,deli_to_do,p_to_deli),length(yfiltred1))
        empty!(mod)
        println(" ------------------- ")
    end

    return results,yfiltred1,yfiltred2
end

## ====================================================================================
## Main program

if (all) 

    data = ["exemple",
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
            "./data/data_16_6/d(ata_16_6_1",
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
    real = ["./data/inst_reel/inst_reel_$i" for i in 1:10]
    results = model_tdap(real)

    # Editing a clean table to present the results
    if (table)
        println("\nEdition of results ----------------------------------------------")
        println("Nb instances : ", length(results))
        
        t_time = Any[]
        t_value = Any[]
        t_cpt = Any[]
        t_pallets = Any[]
        t_deli_to_do = Any[]
        t_p_to_deli = []
        t_cardinal_pareto = []
    
        for i in eachindex(results)
            push!(t_time, results[i][2])
            push!(t_value, results[i][1])
            push!(t_cpt, results[i][3])
            push!(t_pallets, results[i][4])
            push!(t_deli_to_do, results[i][5])
            push!(t_p_to_deli, results[i][6])
            push!(t_cardinal_pareto,results[i][7])
        end
        

        latex = to_table2(real, t_value, t_time, t_cpt,t_pallets,t_deli_to_do,t_p_to_deli,t_cardinal_pareto)
        latex |> print
        to_tex(latex) |> print
    end
    return

else
    data = "./data/inst_reel/inst_reel_5" #"./data/data_10_3/data_10_3_0" #
    results,y1,y2 = model_tdap(data)
    p = Plots.scatter(y1,y2,color=:blue,label=false,xlabel="Time taken",ylabel="Non delivered pallets") 
    p |> display
    Plots.savefig(p,"fig/Pareto_front_for_"*string(split(data,"/")[4])*".svg")
    Plots.savefig(p,"fig/Pareto_front_for_"*string(split(data,"/")[4])*".png")
    return p 
end
