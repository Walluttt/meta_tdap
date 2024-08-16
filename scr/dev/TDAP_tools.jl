# =============================================================================

function solution_checkerM(instance::Instance, δ::Matrix{Int64}, tr::Vector{Int64}, mod::Model)

    # Splitting the values stored in instances in separated variables (Destructuring Assignment)
    (; name, n,m, a,d, t,f,c,p, C) = instance

    # extracting the optimal values for variables y and z
    y = copy(value.(mod[:y]))
    z = copy(value.(mod[:z]))
    
    for i=1:n
        # Constraint (2)
        if sum(y[i, k] for k in 1:m) > 1
            println("Constraint (2) violated for truck $i: assigned to more than one dock.")
            return false
        end
    end
    
    for i=1:n, j=1:n, k=1:m, l=1:m
        # Constraint (3)
        if z[i, j, k, l] > y[i, k] 
            println("Constraint (3) violated for truck $i and dock $k: pallets transferred without destination dock.")
            return false
        end
    end
    
    for i=1:n, j=1:n, k=1:m, l=1:m
        # Constraint (4)
        if z[i, j, k, l] > y[j, l] 
            println("Constraint (4) violated for truck $j and dock $l: pallets transferred without departure dock.")
            return false
        end
    end
    
    for i=1:n, j=1:n, k=1:m, l=1:m
        # Constraint (5)
        if y[i, k] + y[j, l] - 1 > z[i, j, k, l]
            println("Constraint (5) violated for trucks $i and $j, dock $k and $l.")
            return false
        end
    end
    
    for i in 1:n, j in 1:n, k in 1:m, l in 1:m
        # Contrainte (6)
        if  (i != j)  &&  (δ[i,j] + δ[j,i] < z[i,j,k,k]) 
            println("Constraint (6) violated for trucks $i and $j, dock $k and $l.")
            return false
        end
    end
    
    # Constraint (7)
    for r in 1:2*n
        cargo_in = 0
        cargo_out = 0
        for i=1:n, k=1:m, l=1:m
            if a[i] ≤ tr[r] && tr[r] ≤ d[i]
                cargo_in += sum(f[i,j] * z[i,j,k,l] for j=1:n)
            end
        end
        for j=1:n, k=1:m, l=1:m
            if a[j] ≤ tr[r] && tr[r] ≤ d[j]
                cargo_out += sum(f[i,j] * z[i,j,k,l] for i=1:n)
            end
        end
        if cargo_in - cargo_out > C
            println("Constraint (7) violated for time $r: dock capacity exceeded.")
            return false
        end
    end
    
    # Constraint (8)
    for i=1:n, j=1:n, k=1:m, l=1:m
        if f[i,j] * z[i,j,k,l] * (d[j] - a[i] -  t[k,l]) < 0
            println("Constraint (8) violated for trucks $i and $j, docks $k and $l.")
            return false
        end
    end
    
    print("\n    ")
    println("The optimal solution generated is valid according the formulation M.\n")
    return true
end


# =============================================================================

function solution_checkerValues(instance::Instance, mod::Model)

    y = copy(value.(mod[:y]))

    valide = true
    for i=1:instance.n-1
        dock_i = findfirst(isequal(1),y[i,:])
        if  typeof(dock_i) != Nothing
            for j=i+1:instance.n
                dock_j = findfirst(isequal(1),y[j,:])
                if typeof(dock_j) != Nothing
                    if dock_i == dock_j
                        if instance.d[j] > instance.a[i] && instance.a[j] < instance.d[i]
                            valide = false
                            println(" not valid 1: trucks $i and $j are at the same dock ($dock_i) on the same time")
                            HHa, MMa = convertMinutesHHMM(instance.a[i])
                            HHd, MMd = convertMinutesHHMM(instance.d[i])
                            @printf("        truck %2d ⟶  dock %2d | arrival: %4d (%02d:%02d) ⟶  departure: %4d (%02d:%02d)\n", i, dock_i, instance.a[i], HHa, MMa, instance.d[i], HHd, MMd)
                            HHa, MMa = convertMinutesHHMM(instance.a[j])
                            HHd, MMd = convertMinutesHHMM(instance.d[j])
                            @printf("        truck %2d ⟶  dock %2d | arrival: %4d (%02d:%02d) ⟶  departure: %4d (%02d:%02d)\n", j, dock_j, instance.a[j], HHa, MMa, instance.d[j], HHd, MMd)
                        end
                    end
                end
            end
        end
    end
    if valide
        print("    ")
        println("The optimal solution generated is valid according their values.\n")
        return true
    else
        return false
    end
end