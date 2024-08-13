# =============================================================================
# Examine an instance to build the parameters required by IP models

function processingInstance(instance::Instance)

    # -------------------------------------------------------------------------
    # Identify temporal relations between trucks

    # 1 iff truck i departs no later than truck j arrives, 0 otherwise --------
    δ::Matrix{Int64} = zeros(Int, instance.n, instance.n)
    for i=1:instance.n, j=1:instance.n
        if i!=j
            if instance.d[i] <= instance.a[j]
                δ[i,j] = 1
            end
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

    # ***

    x=zeros(Int, instance.n, instance.n)
    for i=1:instance.n
        for j=1:instance.n
            if instance.d[i] <= instance.a[j]
                x[i,j] = 1
            end
        end
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

    @assert x==δ "divergence x==δ"
    @assert atr==arr_t "divergence atr==arr_t"
    @assert dtr==dep_t "divergence dtr==dep_t"

    return δ, tr, atr, dtr
end