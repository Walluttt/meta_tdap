# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
# Examine an instance to build the parameters required by IP models

function processingInstance(instance::Instance)

    # -------------------------------------------------------------------------
    # Identify temporal relations between trucks

    # 1 iff truck i departs no later than truck j arrives, 0 otherwise --------
    δ::Matrix{Int64} = zeros(Int, instance.n, instance.n)
    #= previous construction
    for i=1:instance.n-1, j=i+1:instance.n
        if instance.d[i] <= instance.a[j]
            δ[i,j] = 1
            #δ[j,i] = 1
        end
    end
    =#

    # new construction: checking if 2 intervals of time are empty (no conflit) or not (conflict between trucks)
    for i=1:instance.n-1, j=i+1:instance.n
        if instance.d[j] > instance.a[i] && instance.a[j] < instance.d[i] 
            # intersection of temporal periods not empty
            δ[i,j] = 0
            δ[j,i] = 0
        else
            # intersection of temporal periods empty
            δ[i,j] = 1
            δ[j,i] = 1
        end
    end


    # -------------------------------------------------------------------------
    # Build the list of markers times sorted by incresing values,
    # identify the trucks arriving at a given marker time,
    # identify the trucks leaving at a given marker time.

    # time corresponding to arrivals and departures, merged and sorted
    tr = sort(vcat(instance.a,instance.d))

    # trucks arriving at a given marker time
    atr = Vector{Int64}[]
    for r=1:2*instance.n
        #println("r = $r")
        v = (Int64)[]
        for i=1:instance.n
            #print("  $(instance.a[i])  $(tr[r]) : ")
            if instance.a[i]<=tr[r]
                #println("$i")
                push!(v,i)
            #else
                #println(" ")
            end
        end
        push!(atr,v)
    end

    # trucks leaving at a given marker time
    dtr = Vector{Int64}[]
    for r=1:2*instance.n
        #println("r = $r")
        v = (Int64)[]
        for j=1:instance.n
            #print("  $(instance.d[j])  $(tr[r]) : ")
            if instance.d[j]<=tr[r]
                #println("$j")
                push!(v,j)            
            #else
                #println(" ")
            end
        end
        push!(dtr,v)
    end

    return δ, tr, atr, dtr
end