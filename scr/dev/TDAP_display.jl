using Printf

# --------------------------------------------------------------------------- #
# Display all information of an instance

function displayInstance(instance)

    println("")
    println("instance <<< $(instance.name) >>>\n")
    println("  number of trucks.........: $(instance.n)")
    println("  number of docks..........: $(instance.m)")
    println("  maximum capacity ........: $(instance.C)")
    println("")

    println("  arrival and departure time (hh.mm) of trucks:")
    for i in 1:instance.n
        print("    ")
        @printf("%3d   %4.2f   %4.2f \n", i, instance.a[i], instance.d[i])
    end
    println("")

    println("  operational times from k to l (hh.mm):")
    for k in 1:instance.m
        print("    ")
        for l in 1:instance.m
            @printf("%5.2f ", instance.t[k,l])
#            print(instance.t[k,l]," ")
        end
        println("")
    end
    println("")

    println("  number of pallets to transfert from i to j:")
    for i in 1:instance.n
        print("    ")
        for j in 1:instance.n
            @printf("%5d ",instance.f[i,j])
        end
        println("")
    end
    println("")

    println("  transportation cost (€) from k to l:")
    for k in 1:instance.m
        print("    ")
        for l in 1:instance.m
            @printf("%5d ", instance.c[k,l])
        end
        println("")
    end
    println("")

    println("  penalities (€) from i to j:")
    for k in 1:instance.n
        print("    ")
        for l in 1:instance.n
            @printf("%5d ", instance.p[k,l])
        end
        println("")
    end
    println("")

    return nothing
end


# --------------------------------------------------------------------------- #
# Display information deduced from the processing of the instance

function displayProcessing(δ::Matrix{Int64}, tr::Vector{Float64}, atr::Vector{Vector{Int64}}, dtr::Vector{Vector{Int64}})

    # -------------------------------------------------------------------------
    # temporal relations between trucks

    #@show δ  #x

    println("  1 iff truck i departs no later than truck j arrives, 0 otherwise:")
    for i in 1:instance.n
        print("    ")
        for j in 1:instance.n
            @printf("%5d ",δ[i,j])
        end
        println("")
    end
    println("")


    # -------------------------------------------------------------------------
    # list of markers,
    # trucks arriving at a given marker time,
    # trucks leaving at a given marker time.

    #@show tr
    #@show atr  #arr_t
    #@show dtr  #dep_t

    println("  Arrivals and departures of trucks at a time marker:")
    for r=1:2*instance.n
        print("    ")
        @printf("%2d  %4.2f     ", r, tr[r])
        println("$(atr[r])     $(dtr[r])" )
    end

    return nothing
end