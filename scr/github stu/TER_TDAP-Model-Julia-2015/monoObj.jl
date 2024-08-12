
using JuMP, Gurobi
include("loadTDAP.jl")


mutable struct Camion
    numero     :: Int64
    hArr       :: Float64
    hDep       :: Float64
    nPalettes  :: Vector{Int64}
end

function monoObj(instancefile)

    if false
        # === Parametres ==============================================================

        # nombre de quais du terminal (nombre obligatoirement pair)
        m = 8#14

        # vitesse (km/h) moyenne des engins de levage 
        vitesse = 5  # 5km/h en moyenne 

        # Nombre et chargement max des camions a 3 essieux
        nbrMaxCamions3essieux = 12#20
        nbrMaxPalettesCamions3essieux = 16

        # Nombre et chargement max des camions a 6 essieux
        nbrMaxCamions6essieux = 6#8
        nbrMaxPalettesCamions6essieux = 40

        # Nombre maximum de palettes a considerer
        nbrMaxPalettes = 240#320

        # === Calcul des donnees relatives au terminal ================================
        dist = [4.0 9.5 15.0 20.5 36.5 31.0 25.5 20.0; 9.5 4.0 9.5 15.0 31.0 25.5 20.0 25.5; 15.0 9.5 4.0 9.5 25.5 20.0 25.5 31.0; 20.5 15.0 9.5 4.0 20.0 25.5 31.0 36.5; 36.5 31.0 25.5 20.0 4.0 9.5 15.0 20.5; 31.0 25.5 20.0 25.5 9.5 4.0 9.5 15.0; 25.5 20.0 25.5 31.0 15.0 9.5 4.0 9.5; 20.0 25.5 31.0 36.5 20.5 15.0 9.5 4.0]
        temps = [0.002 0.00475 0.0075 0.01025 0.01825 0.0155 0.01275 0.01; 0.00475 0.002 0.00475 0.0075 0.0155 0.01275 0.01 0.01275; 0.0075 0.00475 0.002 0.00475 0.01275 0.01 0.01275 0.0155; 0.01025 0.0075 0.00475 0.002 0.01 0.01275 0.0155 0.01825; 0.01825 0.0155 0.01275 0.01 0.002 0.00475 0.0075 0.01025; 0.0155 0.01275 0.01 0.01275 0.00475 0.002 0.00475 0.0075; 0.01275 0.01 0.01275 0.0155 0.0075 0.00475 0.002 0.00475; 0.01 0.01275 0.0155 0.01825 0.01025 0.0075 0.00475 0.002]

        chargementCamions3essieux = [7, 15, 9, 16, 14, 11, 9]
        chargementCamions6essieux = [40, 19, 22]
        f = [0 0 0 0 8 2 10 5 7 8; 0 0 0 2 0 6 6 0 4 1; 0 0 0 5 7 1 0 9 0 0; 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0]

        println("\nChargement initial des camions 6 essieux :", chargementCamions6essieux)
        println("\nChargement final des camions 3 essieux   :", chargementCamions3essieux)

        Camions3essieux = Camion[Camion(1, 9.01, 9.99, [7]), Camion(2, 11.88, 13.13, [15]), Camion(3, 9.82, 10.87, [9]), Camion(4, 11.7, 12.98, [16]), Camion(5, 10.94, 12.16, [14]), Camion(6, 13.71, 14.83, [11]), Camion(7, 10.9, 11.95, [9])]
        Camions6essieux = Camion[Camion(1, 8.41, 9.99, [40]), Camion(2, 11.53, 12.41, [19]), Camion(3, 12.96, 13.94, [22])]


        #traceFenetresTempsCamionsCharges(Camions3essieux, Camions6essieux, chargementCamions6essieux, f)


        # --- given parameters --------------------------------------------------------

        # number of trucks / nombre de camions
        nbrCamions3essieux = length(chargementCamions3essieux)
        nbrCamions6essieux = length(chargementCamions6essieux)
        n = nbrCamions3essieux+nbrCamions6essieux

        # number of docks / nombre de quais 
        #m = 4 

        # operational cost per unit time from dock k to dock l 
        c = dist.-4.0
        #=
        c = [0.0 10.0 20.0 10.0; 
            10.0 0.0 10.0 20.0; 
            20.0 10.0 0.0 10.0;
            10.0 20.0 10.0 0.0]
        =#

        # operational time for pallets from dock k to dock l  (in minutes, 0<=minutes<=59)
        t = temps
        

        # penalty cost per unit cargo from truck i to truck j
        p = fill(100,n,n)
        for i in 1:n
            p[i,i]=0
        end

        # number of pallets transferring from truck i to truck j 


        # capacity of the cross dock terminal (maximum number of cargos the cross dock can hold at a time)
        C = 100 

        a = []
        d = []
        for i in 1:length(Camions6essieux)
            push!(a,Camions6essieux[i].hArr)
            push!(d,Camions6essieux[i].hDep)
        end 
        for i in 1:length(Camions3essieux)
            push!(a,Camions3essieux[i].hArr)
            push!(d,Camions3essieux[i].hDep)
        end 


        # arrival time of truck i (in hour.minutes, 0<=hour<=23, 0<=minutes<=59)
        #a = [12.40, 09.10, 09.10, 14.30, 10.12, 08.25]
        # departure time of truck i
        #d = [17.13, 16.10, 14.00, 17.53, 16.05, 13.10]

        # --- built parameters --------------------------------------------------------

        # 1 iff truck i departs no later than truck j arrives, 0 otherwise
        δ=zeros(Int64,n,n)  

        for i=1:n, j=1:n
            if i!=j
                if d[i] <= a[j]
                    δ[i,j] = 1
                end
            end
        end

        @show δ

        # time corresponding to arrivals and departures, merged and sorted
        tr = sort(vcat(a,d))

        atr = Vector{Int64}[]
        for r=1:2*n
            println("r = $r")
            v = (Int64)[]
            for i=1:n
                print("  $(a[i])  $(tr[r]) : ")
                if a[i]<=tr[r]
                    println("$i")
                    push!(v,i)
                else
                    println(" ")
                end
            end
            push!(atr,v)
        end

        dtr = Vector{Int64}[]
        for r=1:2*n
            println("r = $r")
            v = (Int64)[]
            for j=1:n
                print("  $(d[j])  $(tr[r]) : ")
                if d[j]<=tr[r]
                    println("$j")
                    push!(v,j)            
                else
                    println(" ")
                end
            end
            push!(dtr,v)
        end

        @show atr
        @show dtr


    else 
        @show instancefile
        # read instance 
        data::instance = loadTDAP(instancefile)

        n = data.n
        m = data.m
        
        t = data.t
        f = data.f
        p = data.p
        C = data.C
        c = data.c

        a = data.a
        d = data.d

        tr = sort(vcat(a,d))
        
        atr = Vector{Int64}[]
        for r=1:2*n
            println("r = $r")
            v = (Int64)[]
            for i=1:n
                print("  $(a[i])  $(tr[r]) : ")
                if a[i]<=tr[r]
                    println("$i")
                    push!(v,i)
                else
                    println(" ")
                end
            end
            push!(atr,v)
        end

        dtr = Vector{Int64}[]
        for r=1:2*n
            println("r = $r")
            v = (Int64)[]
            for j=1:n
                print("  $(d[j])  $(tr[r]) : ")
                if d[j]<=tr[r]
                    println("$j")
                    push!(v,j)            
                else
                    println(" ")
                end
            end
            push!(dtr,v)
        end

        δ=zeros(Int64,n,n)  
        for i=1:n, j=1:n
            if i!=j
                if d[i] <= a[j]
                    δ[i,j] = 1
                end
            end
        end
    end

    # -----------------------------------------------------------------------------

    # --- formulation introduced by Gelareh et al. in 2016 modif XG ---------------------------

    mod = Model(Gurobi.Optimizer)

    # variables: 1 if truck i is assigned to dock k, 0 otherwise 
    @variable(mod, y[1:n,1:m], Bin)

    # variables: 1 if truck i is assigned to dock k and truck j to dock l, 0 otherwise
    @variable(mod, z[1:n,1:n,1:m,1:m], Bin)
    #@assert false "stop"
    # objective: total operational cost + total penalty cost
    @objective(mod, Min, sum(c[k,l] * t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m)
                        +
                        sum( (sum( p[i,j] * f[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n)
            )

    # contrainte sur obj 1 :
    #@constraint(mod, cstF1, sum(1000 * t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m) <= 60) 
    # constraint (2)          
    @constraint(mod, cst2_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 
    # constraint (3) 
    @constraint(mod, cst3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])
    # constraint (4) 
    @constraint(mod, cst4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])
    # constraint (5) 
    @constraint(mod, cst5_[i=1:n, j=1:n, k=1:m; i!=j], y[i,k] + y[j,k] <= 1 + δ[i,j] + δ[j,i])
    # constraint (6) 
    @constraint(mod, cst6_[i=1:n, j=1:n, k=1:m; i!=j],z[i,j,k,k] <= δ[i,j] )
    # constraint (7) 
    @constraint(mod, cst7_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                    - 
                                    sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                    <= C
                )

    # constraint (8) 
    @constraint(mod, cst8_[i=1:n, j=1:n, k=1:m, l=1:m; i!=j && (d[j] - a[i] -  f[i,j] * t[k,l])<=0 ],  z[i,j,k,l] == 0)


    # --- Resolution --------------------------------------------------------

    optimize!(mod)

    # --- Results --------------------------------------------------------

    global cout = 0
    global penalite = 0

    if termination_status(mod) == OPTIMAL
        println("\nOptimal value of the objective function: ", objective_value(mod))

        for i=1:n, j=1:n, k=1:m, l=1:m
            global cout =  cout + c[k,l] * t[k,l] * value(z[i,j,k,l])
        end
        println("  -> total operational cost :", cout)

        for i=1:n
            for j=1:n
                global som = 0
                for k=1:m, l=1:m
                    som = som + value(z[i,j,k,l])
                end
                global penalite = penalite + p[i,j] * f[i,j] * (1-som)
            end
        end
        println("  -> total penalty cost :", penalite)


        println("\nAssignment truck to dock:")
        for i=1:n,k=1:m
            if value.(y[i,k])==1
                println("  truck $i ⟶ dock $k | arrival: ", a[i]," ⟶ departure: ", d[i])
            end
        end

        println("\nFeasible transferts of pallet(s):")
        for i=1:n, j=1:n, k=1:m, l=1:m
            if value.(z[i,j,k,l])==1
                print("i=$i j=$j k=$k l=$l :   between truck/dock ($i,$k) and truck/dock ($j,$l)")
                if f[i,j]>0
                    println(" -> ", f[i,j], " pallet(s)")
                else
                    println(" ")
                end
            end
        end
    end   


    yOpt=copy(value.(y)) 


    global f1 = 0.0
    for i=1:n, j=1:n, k=1:m, l=1:m
        global f1 +=  1000 * t[k,l] * value.(z[i,j,k,l])
    end

    global f2 = 0.0
    for i=1:n, j=1:n
        f2interne = 0.0

        for k=1:m, l=1:m
            f2interne +=  value.(z[i,j,k,l])
        end

        global f2 +=  f[i,j] * ( 1 - f2interne)
    end

    @show f1
    @show f2

    # Activity at the docks
    println("\nActivity at the docks: ")
    trucksAtDock = [findall(>(0.0),yOpt[:,k]) for k in 1:m]
    for k in 1:m
        print("  dock $k :")
        for i in trucksAtDock[k]
            print("truck $i at [$(a[i]),$(d[i])]  ")
            for j in trucksAtDock[k]
                if i!=j
                    if !(d[i]<=a[j] || d[j]<=a[i])
                        println("no valid solution: conflict between truck $i and truck $j at dock $k")
                        @assert false "no valid solution: conflict between truck $i and truck $j at dock $k"
                    end
                end
            end
        end
        println(" ")
    end
    println(" ")

    # Assignment trucks to docks
    println("Assignment of the trucks: ")
    assignmentTruckDock = [findfirst(>(0.0),yOpt[i,:]) for i in 1:n]
    for i in 1:n
        k = assignmentTruckDock[i]
        if k == nothing
            print("  truck $i NOT ASSIGNED")
        else
            print("  truck $i to dock $k at [$(a[i]),$(d[i])]")
            for j in 1:n
                if i!=j
                    l = assignmentTruckDock[j]
                    if k==l 
                        if d[i]<=a[j] || d[j]<=a[i]
                            print(" + truck $j at [$(a[j]),$(d[j])]")
                        else
                            println("no valid solution: conflict between truck $i and truck $j at dock $k")
                            @assert false "no valid solution: conflict between truck $i and truck $j at dock $k"
                        end
                    end
                end
            end
        end

        println(" ")
    end
    return (f1,f2)
end


global data_all = ["exemple", 
                "./data/data_10_3/data_10_3_0",
                "./data/inst_reel/inst_reel_1",
                "./data/inst_reel/inst_reel_2",
                "./data/inst_reel/inst_reel_3",
                "./data/inst_reel/inst_reel_4",
                "./data/inst_reel/inst_reel_5",
                "./data/inst_reel/inst_reel_6",
                "./data/inst_reel/inst_reel_7",
                "./data/inst_reel/inst_reel_8",
                "./data/inst_reel/inst_reel_9",
                "./data/inst_reel/inst_reel_10"
                ]

results = []
for i in data_all
    push!(results, monoObj(i))
end
for i in results
    @show i
end
