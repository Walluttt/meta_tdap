
# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
# Formulation introduced by Miao et al. in 2009 

function formulation_M(instance::Instance, δ::Matrix{Int64}, atr::Vector{Vector{Int64}}, dtr::Vector{Vector{Int64}}, IPsolver::DataType)

    # Splitting the values stored in instances in separated variables (Destructuring Assignment)
    (; fname, n,m, a,d, t,f,c,p, C) = instance

    # create a model
    mod = Model(IPsolver)

    @variable(mod, 0 <= y[1:n, 1:m] <= 1)  # Relaxation de y[i,k]
    @variable(mod, 0 <= z[1:n, 1:n, 1:m, 1:m] <= 1)  # Relaxation de z[i,j,k,l]

    # expression: total operational cost
    @expression(mod, cost, sum(c[k,l] * t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m))

    # expression: total penalty cost
    @expression(mod, penality, sum( p[i,j] * f[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for i=1:n, j=1:n) )

    # objective: total operational cost + total penalty cost
    @objective(mod, Min, cost + penality)

    # constraint (M.2):          
    @constraint(mod, cstM2_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 

    # constraint (M.3): 
    @constraint(mod, cstM3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])

    # constraint (M.4):  
    @constraint(mod, cstM4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])

    # constraint (M.5): 
    @constraint(mod, cstM5_[i=1:n, j=1:n, k=1:m, l=1:m], y[i,k] + y[j,l] - 1 <= z[i,j,k,l])

    # constraint (M.6):  
    @constraint(mod, cstM6_[i=1:n, j=1:n, k=1:m; i!=j], δ[i,j] + δ[j,i] >= z[i,j,k,k])

    # constraint (M.7):  
    @constraint(mod, cstM7_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                    - 
                                    sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                    <= C
                )

    # constraint (M.8):  
    @constraint(mod, cstM8_[i=1:n, j=1:n, k=1:m, l=1:m], f[i,j] * z[i,j,k,l] * (d[j] - a[i] - t[k,l]) >= 0)

    return mod
end


# -----------------------------------------------------------------------------
# Formulation introduced by Gelareh et al. in 2015 after having fixed issues in 2024 (see Forget et al, 2024) 

function formulation_G(instance::Instance, δ::Matrix{Int64}, atr::Vector{Vector{Int64}}, dtr::Vector{Vector{Int64}}, IPsolver::DataType)

    # Splitting the values stored in instances in separated variables (Destructuring Assignment)
    (; fname, n,m, a,d, t,f,c,p, C) = instance

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

    # constraint (G.2):          
    @constraint(mod, cstG2_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 

    # constraint (G.3): 
    @constraint(mod, cstG3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])

    # constraint (G.4): 
    @constraint(mod, cstG4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])

    # constraint (G.5): 
    @constraint(mod, cstG5_[i=1:n, j=1:n, k=1:m; i!=j], y[i,k] + y[j,k] <= 1 + δ[i,j] + δ[j,i])

    # constraint (G.6): 
    @constraint(mod, cstG6_[i=1:n, j=1:n, k=1:m; i!=j],z[i,j,k,k] <= δ[i,j] )

    # constraint (G.7): 
    @constraint(mod, cstG7_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                    - 
                                    sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                    <= C
                )

    # constraint (G.8): 
    @constraint(mod, cstG8_[i=1:n, j=1:n, k=1:m, l=1:m; i!=j && (d[j] - a[i] - t[k,l])<=0 ],  z[i,j,k,l] == 0)

    return mod
end


# -----------------------------------------------------------------------------
# Formulation 2M 

function formulation_2M(instance::Instance, δ::Matrix{Int64}, atr::Vector{Vector{Int64}}, dtr::Vector{Vector{Int64}}, IPsolver::DataType, obj::Symbol)

    # Splitting the values stored in instances in separated variables (Destructuring Assignment)
    (; fname, n,m, a,d, t,f,c,p, C) = instance

    # create a model
    mod = Model(IPsolver)

    # variables: 1 if truck i is assigned to dock k, 0 otherwise 
    @variable(mod, y[1:n,1:m], Bin)

    # variables: 1 if truck i is assigned to dock k and truck j to dock l, 0 otherwise
    @variable(mod, z[1:n,1:n,1:m,1:m], Bin)

    # objective (1.1): objFct1 → total transfert time of the pallets in the cross-dock
    @expression(mod, objFct1_transfertTime, sum(t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m))

    # objective (1.2): objFct2 → total quantity transferred
    @expression(mod, objFct2_quantitytransferred, sum(f[i,j] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m))

    # objectives: 
    if obj == :obj1
        # :obj1 => objFct1_transfertTime
        @objective(mod, Min, objFct1_transfertTime)
    else
        # :obj2 => objFct2_quantitytransferred
        @objective(mod, Max, objFct2_quantitytransferred)
    end

    # constraint (M.2):          
    @constraint(mod, cstM2_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 

    # constraint (M.3): 
    @constraint(mod, cstM3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])

    # constraint (M.4):  
    @constraint(mod, cstM4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])

    # constraint (M.5): 
    @constraint(mod, cstM5_[i=1:n, j=1:n, k=1:m, l=1:m], y[i,k] + y[j,l] - 1 <= z[i,j,k,l])

    # constraint (M.6):  
    @constraint(mod, cstM6_[i=1:n, j=1:n, k=1:m; i!=j], δ[i,j] + δ[j,i] >= z[i,j,k,k])

    # constraint (M.7):  
    @constraint(mod, cstM7_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                    - 
                                    sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                    <= C
                )

    # constraint (M.8):  
    @constraint(mod, cstM8_[i=1:n, j=1:n, k=1:m, l=1:m], f[i,j] * z[i,j,k,l] * (d[j] - a[i] - t[k,l]) >= 0)

    return mod
end


# -----------------------------------------------------------------------------
# Formulation 2G

function formulation_2G(instance::Instance, δ::Matrix{Int64}, atr::Vector{Vector{Int64}}, dtr::Vector{Vector{Int64}}, IPsolver::DataType, obj::Symbol)

    # Splitting the values stored in instances in separated variables (Destructuring Assignment)
    (; fname, n,m, a,d, t,f,c,p, C) = instance

    # create a model
    mod = Model(IPsolver) 

    # variables: 1 if truck i is assigned to dock k, 0 otherwise 
    @variable(mod, y[1:n,1:m], Bin)

    # variables: 1 if truck i is assigned to dock k and truck j to dock l, 0 otherwise
    @variable(mod, z[1:n,1:n,1:m,1:m], Bin)

    # objective (1.1): objFct1 → total transfert time of the pallets in the cross-dock
    @expression(mod, objFct1_transfertTime, sum(t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m))

    # objective (1.2): objFct2 → total quantity transferred
    @expression(mod, objFct2_quantitytransferred, sum(f[i,j] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m))

    # objectives:
    if obj == :obj1
        # :obj1 => objFct1_transfertTime
        @objective(mod, Min, objFct1_transfertTime)
    else
        # :obj2 => objFct2_quantitytransferred
        @objective(mod, Max, objFct2_quantitytransferred)
    end

    # constraint (G.2):          
    @constraint(mod, cstG2_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 

    # constraint (G.3): 
    @constraint(mod, cstG3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])

    # constraint (G.4): 
    @constraint(mod, cstG4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])

    # constraint (G.5): 
    @constraint(mod, cstG5_[i=1:n, j=1:n, k=1:m; i!=j], y[i,k] + y[j,k] <= 1 + δ[i,j] + δ[j,i])

    # constraint (G.6): 
    @constraint(mod, cstG6_[i=1:n, j=1:n, k=1:m; i!=j],z[i,j,k,k] <= δ[i,j] )

    # constraint (G.7): 
    @constraint(mod, cstG7_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                    - 
                                    sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                    <= C
                )

    # constraint (G.8): 
    @constraint(mod, cstG8_[i=1:n, j=1:n, k=1:m, l=1:m; i!=j && (d[j] - a[i] - t[k,l])<=0 ],  z[i,j,k,l] == 0)

    return mod
end