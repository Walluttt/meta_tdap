
# =============================================================================
# Formulation introduced by Miao et al. in 2009 

function formulation_M(instance::Instance, δ::Matrix{Int64}, atr::Vector{Vector{Int64}}, dtr::Vector{Vector{Int64}}, IPsolver::DataType)

    # Splitting the values stored in instances in separated variables (Destructuring Assignment)
    (; name, n,m, a,d, t,f,c,p, C) = instance

    # create a model
    mod = Model(IPsolver)

    # variables: 1 if truck i is assigned to dock k, 0 otherwise 
    @variable(mod, y[1:n,1:m], Bin)

    # variables: 1 if truck i is assigned to dock k and truck j to dock l, 0 otherwise
    @variable(mod, z[1:n,1:n,1:m,1:m], Bin)

    # expression: total operational cost
    @expression(mod, cost, sum(c[k,l] * t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m))

    # expression: total penalty cost
    @expression(mod, penality, sum( p[i,j] * f[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for i=1:n, j=1:n) )

    # objective: total operational cost + total penalty cost
    @objective(mod, Min, cost + penality)

    # constraint (2):          
    @constraint(mod, exp2_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 

    # constraint (3): 
    @constraint(mod, exp3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])

    # constraint (4):  
    @constraint(mod, exp4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])

    # constraint (5): 
    @constraint(mod, exp5_[i=1:n, j=1:n, k=1:m, l=1:m], y[i,k] + y[j,l] - 1 <= z[i,j,k,l])

    # constraint (6):  
    @constraint(mod, exp6_[i=1:n, j=1:n, k=1:m; i!=j], δ[i,j] + δ[j,i] >= z[i,j,k,k])

    # constraint (7):  
    @constraint(mod, exp7_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                    - 
                                    sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                    <= C
                )

    # constraint (8):  
    @constraint(mod, exp8_[i=1:n, j=1:n, k=1:m, l=1:m], f[i,j] * z[i,j,k,l] * (d[j] - a[i] - t[k,l]) >= 0)

    return mod
end


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
    
    print("    ")
    println("The optimal solution generated is valid according the formulation M.")
    return true
end