using JuMP

function solution_checker(inst::instance, y::Matrix{Float64}, z::Array{Float64,4})
    m = inst.m
    n = inst.n
    a = inst.a
    d = inst.d
    t = inst.t
    f = inst.f
    C = inst.C

    tr = Float64[]
    sort!(append!(tr, inst.a, inst.d))
    
    # constraint checking
    for i in 1:n
        # Contrainte 1
        if sum(y[i, k] for k in 1:m) > 1
            println("Constraint 1 violated for truck $i: assigned to more than one dock.")
            return false
        end
    end
    
    for i in 1:n,j in 1:n, k in 1:m, l in 1:m
        # Contrainte 2
        if z[i, j, k, l] > y[i, k] 
            println("Constraint 2 violated for truck $i and dock $k: pallets transferred without destination dock.")
            return false
        end
    end
    
    for i in 1:n, j in 1:n, k in 1:m, l in 1:m
        # Contrainte 3
        if z[i, j, k, l] > y[j, l] 
            println("Constraint 3 violated for truck $j and dock $l: pallets transferred without departure dock.")
            return false
        end
    end
    
    for i in 1:n, j in 1:n, k in 1:m
        # Contrainte 4
        if y[i, k] + y[j, k] > 1 + inst.x[i, j] + inst.x[j, i] && i!=j
            println("Constraint 4 violated for trucks $i and $j, dock $k.")
            return false
        end
    end
    
    for i in 1:n, j in 1:n, k in 1:m, l in 1:m
        # Contrainte 5
        if z[i, j, k, l] > inst.x[i, j] && i!=j
            println("Constraint 5 violated for trucks $i and $j, dock $k and $l.")
            return false
        end
    end
    
    # Contrainte 6
    for r in 1:2*n
        cargo_in = 0
        cargo_out = 0
        for i in 1:n, k in 1:m, l in 1:m
            if a[i] ≤ tr[r] && tr[r] ≤ d[i]
                cargo_in += sum(f[i, j] * z[i, j, k, l] for j in 1:n)
            end
        end
        for j in 1:n, k in 1:m, l in 1:m
            if a[j] ≤ tr[r] && tr[r] ≤ d[j]
                cargo_out += sum(f[i, j] * z[i, j, k, l] for i in 1:n)
            end
        end
        if cargo_in - cargo_out > C
            println("Constraint 6 violated for time $r: dock capacity exceeded.")
            return false
        end
    end
    
    # Contrainte 7'
    for i in 1:n, j in 1:n, k in 1:m, l in 1:m
        if j ≠ i && z[i, j, k, l] * (d[j] - a[i] - f[i, j] * t[k, l]) < 0
            println("Constraint 7' violated for trucks $i and $j, docks $k and $l.")
            return false
        end
    end
    
    println("The proposed solution is valid.")
    return true
end
