# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
# Convert a number of minutes in hh:mm

function convertMinutesHHMM(minutes::Int64)
    hhFloat = minutes/60
    hh = Int(floor(hhFloat))
    mmFloat = hhFloat - hh
    mm = Int(round(mmFloat*60))
    return hh,mm
end


# -----------------------------------------------------------------------------
# Display all information of an instance

function displayInstance(instance::Instance)

    println("")
    println("  instance ............. $(instance.name)")
    println("  number of trucks...... $(instance.n)")
    println("  number of docks....... $(instance.m)")
    println("  maximum capacity ..... $(instance.C)")
    println("")

    println("  arrival and departure time of trucks in minutes in [00:00;23:59] (hh.mm):")
    for i in 1:instance.n
        print("    ")
        HHa, MMa = convertMinutesHHMM(instance.a[i])
        HHd, MMd = convertMinutesHHMM(instance.d[i])
        @printf("%3d   %4d (%02d:%02d)   %4d (%02d:%02d) \n", i, instance.a[i], HHa, MMa, instance.d[i], HHd, MMd)
    end
    println("")

    println("  operational times (minutes) from k to l:")
    for k in 1:instance.m
        print("   ")
        for l in 1:instance.m
            @printf("%4d", instance.t[k,l])
        end
        println("")
    end
    println("")

    println("  number of pallets to transfert from i to j:")
    for i in 1:instance.n
        print("   ")
        for j in 1:instance.n
            instance.f[i,j]==0 ? @printf("   .") : @printf("%4d", instance.f[i,j])            
        end
        println("")
    end
    println("")

    println("  transportation cost (€) from k to l:")
    for k in 1:instance.m
        print("   ")
        for l in 1:instance.m
            @printf("%4d", instance.c[k,l])
        end
        println("")
    end
    println("")

    println("  penalities (€) from i to j:")
    for k in 1:instance.n
        print("   ")
        for l in 1:instance.n
            instance.p[k,l]==0 ? @printf("   .") : @printf("%4d", instance.p[k,l])
        end
        println("")
    end
    println("")

    return nothing
end


# -----------------------------------------------------------------------------
# Display information deduced from the processing of the instance

function displayProcessing(δ::Matrix{Int64}, tr::Vector{Int64}, atr::Vector{Vector{Int64}}, dtr::Vector{Vector{Int64}}, instance::Instance)

    # -------------------------------------------------------------------------
    # temporal relations between trucks

    #@show δ 

    println("  1 iff truck i departs no later than truck j arrives, 0 otherwise:")
    for i in 1:instance.n
        print("   ")
        for j in 1:instance.n
            @printf("%4d",δ[i,j])
        end
        println("")
    end
    println("")


    # -------------------------------------------------------------------------
    # list of markers,
    # trucks arriving at a given marker time,
    # trucks leaving at a given marker time.

    #@show tr
    #@show atr  
    #@show dtr  

    println("  Arrivals and departures of trucks at a time marker:")
    for r=1:2*instance.n
        print("   ")
        HHtr, MMtr = convertMinutesHHMM(tr[r])
        @printf("%4d    %4d (%02d:%02d)    ", r, tr[r], HHtr, MMtr)
        println("$(atr[r])     $(dtr[r])" )
    end

    return nothing
end


# -----------------------------------------------------------------------------
# Display the details for the optimal solution obtained

function displayOptimalSolution(formulationID::String, t_elapsed::Float64, mod::Model, instance::Instance)

    println(" ")
    println("  Optimal solution found ($formulationID):")

    # -------------------------------------------------------------------------
    print("    ")
    println("CPUTime consumed: ", trunc(t_elapsed, digits=3), " sec\n")

    # -------------------------------------------------------------------------
    zOpt = objective_value(mod)
    print("    ")
    println("zOptimal................ ", Int(round(zOpt)))

    n = instance.n
    m = instance.m
    cost = 0.0
    for i=1:n, j=1:n, k=1:m, l=1:m
        cost =  cost + instance.c[k,l] * instance.t[k,l] * value(mod[:z][i,j,k,l])
    end
    println("      -> operational cost... ",  Int(round(cost)) )

    penality = 0.0
    for i=1:n
        for j=1:n
            som = 0
            for k=1:m, l=1:m
                som = som + value(mod[:z][i,j,k,l])
            end
            penality = penality + instance.p[i,j] * instance.f[i,j] * (1-som)
        end
    end
    println("      -> penalty cost....... ",  Int(round(penality)), "\n")

    # -------------------------------------------------------------------------
    # measure using the definition of 2R (time transfert & quantity transfered)

    objFct1 = 0.0
    for i=1:n, j=1:n, k=1:m, l=1:m
        objFct1 =  objFct1 + instance.t[k,l] * value(mod[:z][i,j,k,l])
    end
    sol_zOpt1 = Int(round(objFct1))
    
        
    objFct2 = 0.0
    for i=1:n
        for j=1:n
            som = 0
            for k=1:m, l=1:m
                som = som + value(mod[:z][i,j,k,l])
            end
            objFct2 = objFct2 + instance.f[i,j] * som
        end
    end
    sol_zOpt2 = Int(round(objFct2))

    println("      -> total time transfert........ $sol_zOpt1")
    println("      -> total quantity transfered... $sol_zOpt2 \n")   

   # -------------------------------------------------------------------------
    print("    ")
    println("Assigment truck to dock:")

    y = copy(value.(mod[:y]))
    for i=1:n
        k = findfirst(isequal(1),y[i,:])
        if  typeof(k) != Nothing
            HHa, MMa = convertMinutesHHMM(instance.a[i])
            HHd, MMd = convertMinutesHHMM(instance.d[i])
            @printf("      truck %2d ⟶  dock %2d | arrival: %4d (%02d:%02d) ⟶  departure: %4d (%02d:%02d)\n", i, k, instance.a[i], HHa, MMa, instance.d[i], HHd, MMd)
        else
            @printf("      truck %2d ⟶  not assigned \n", i)
        end
    end

    print("\n    ")
    println("Transfert of pallets:")
    delivery_done = 0
    for i=1:n, j=1:n
        if instance.f[i,j] > 0
            for k=1:m, l=1:m
                if value(mod[:z][i,j,k,l])==1
                    @printf("      truck %2d ⟶  truck %2d   from   dock %2d ⟶  dock %2d   of   %2d pallets\n", i, j, k, l, instance.f[i,j])
                    delivery_done += 1
                end
            end
        end
    end
    totalNumberTransfertsPlanned = count(!iszero, instance.f)
    print("\n    ")
    println("  Number of transferts achieved: $delivery_done | total transferts expected: $totalNumberTransfertsPlanned i.e. ",round(delivery_done/totalNumberTransfertsPlanned*100 ; digits=2),"%")    

    return nothing
end



# -----------------------------------------------------------------------------
# Display the details for the optimal solution obtained

function displayOptimalSolution2obj(formulationID::String, t_elapsed::Float64, mod::Model, instance::Instance)

    println(" ")
    println("  Optimal solution found ($formulationID):")

    # -------------------------------------------------------------------------
    print("    ")
    println("CPUTime consumed: ", trunc(t_elapsed, digits=3), " sec\n")

    # -------------------------------------------------------------------------
    zOpt = objective_value(mod)
    print("    ")
    println("zOptimal:")#................ "), Int(round(zOpt)))

    n = instance.n
    m = instance.m

    objFct1 = 0.0
    for i=1:n, j=1:n, k=1:m, l=1:m
        objFct1 =  objFct1 + instance.t[k,l] * value(mod[:z][i,j,k,l])
    end
    println("      -> objFct1 time....... ",  Int(round(objFct1)) )

    objFct2 = 0.0
    for i=1:n
        for j=1:n
            som = 0
            for k=1:m, l=1:m
                som = som + value(mod[:z][i,j,k,l])
            end
            objFct2 = objFct2 + instance.f[i,j] * som
        end
    end
    println("      -> objFct2 transfert.. ",  Int(round(objFct2)), "\n")

   # -------------------------------------------------------------------------
    print("    ")
    println("Assigment truck to dock:")

    y = copy(value.(mod[:y]))
    for i=1:n
        k = findfirst(isequal(1),y[i,:])
        if  typeof(k) != Nothing
            HHa, MMa = convertMinutesHHMM(instance.a[i])
            HHd, MMd = convertMinutesHHMM(instance.d[i])
            @printf("      truck %2d ⟶  dock %2d | arrival: %4d (%02d:%02d) ⟶  departure: %4d (%02d:%02d)\n", i, k, instance.a[i], HHa, MMa, instance.d[i], HHd, MMd)
        else
            @printf("      truck %2d ⟶  not assigned \n", i)
        end
    end

    print("\n    ")
    println("Transfert of pallets:")
    delivery_done = 0
    for i=1:n, j=1:n
        if instance.f[i,j] > 0
            for k=1:m, l=1:m
                if value(mod[:z][i,j,k,l])==1
                    @printf("      truck %2d ⟶  truck %2d   from   dock %2d ⟶  dock %2d   of   %2d pallets\n", i, j, k, l, instance.f[i,j])
                    delivery_done += 1
                end
            end
        end
    end
    totalNumberTransfertsPlanned = count(!iszero, instance.f)
    print("\n    ")
    println("  Number of transferts achieved: $delivery_done | total transferts expected: $totalNumberTransfertsPlanned i.e. ",round(delivery_done/totalNumberTransfertsPlanned*100 ; digits=2),"%")    

    return nothing
end