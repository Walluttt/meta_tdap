
# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
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


# -----------------------------------------------------------------------------
# Formulation introduced by Gelareh et al. in 2015 after having fixed issues in 2024 (see Forget et al, 2024) 

function formulation_G(instance::Instance, δ::Matrix{Int64}, atr::Vector{Vector{Int64}}, dtr::Vector{Vector{Int64}}, IPsolver::DataType)

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
    @constraint(mod, cst2_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 

    # constraint (3): 
    @constraint(mod, cst3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])

    # constraint (4): 
    @constraint(mod, cst4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])

    # constraint (5): 
    @constraint(mod, cst5_[i=1:n, j=1:n, k=1:m; i!=j], y[i,k] + y[j,k] <= 1 + δ[i,j] + δ[j,i])

    # constraint (6): 
    @constraint(mod, cst6_[i=1:n, j=1:n, k=1:m; i!=j],z[i,j,k,k] <= δ[i,j] )

    # constraint (7): 
    @constraint(mod, cst7_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                    - 
                                    sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                    <= C
                )

    # constraint (8): 
    @constraint(mod, cst8_[i=1:n, j=1:n, k=1:m, l=1:m; i!=j && (d[j] - a[i] - t[k,l])<=0 ],  z[i,j,k,l] == 0)

    return mod
end
