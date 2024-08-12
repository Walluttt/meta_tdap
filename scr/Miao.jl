using JuMP, GLPK

# --- given parameters --------------------------------------------------------

# number of trucks / nombre de camions
n = 4 
# number of docks / nombre de quais 
m = 2 
# operational cost per unit time from dock k to dock l 
c = [1 1;  
     1 1]
# operational time for pallets from dock k to dock l 
t = [1 1; 
     1 1]
t=fill(0.25,2,2)
     
# penalty cost per unit cargo from truck i to truck j
p = [0 1 1 1 ;
     1 0 1 1 ;
     1 1 0 1 ;
     0 1 1 0]
# number of pallets transferring from truck i to truck j 
f = [0 2 2 2; 
     2 0 2 2;
     2 2 0 2;
     0 2 2 0]
# capacity of the cross dock terminal (maximum number of cargos the cross dock can hold at a time)
C = 1000 # not given into the note
# arrival time of truck i
a = [15.42, 15.50, 17.00, 16.52]
# departure time of truck i
d = [16.41, 16.41, 18.00, 17.57]

# --- built parameters --------------------------------------------------------

# 1 iff truck i departs no later than truck j arrives, 0 otherwise
x=zeros(Int64,n,n)  

for i=1:n, j=1:n
    if i!=j
        if d[i] <= a[j]
            x[i,j] = 1
        end
    end
end

@show x

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

# --- formulation introduced by Miao et al. in 2009 ---------------------------

mod = Model(GLPK.Optimizer)

# variables: 1 if truck i is assigned to dock k, 0 otherwise 
@variable(mod, y[1:n,1:m], Bin)

# variables: 1 if truck i is assigned to dock k and truck j to dock l, 0 otherwise
@variable(mod, z[1:n,1:n,1:m,1:m], Bin)

# objective: total operational cost + total penalty cost
@objective(mod, Min, sum(c[k,l] * t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m)
                     +
                     sum( (sum( p[i,j] * f[i,j] * ( 1 - sum( z[i,j,k,l] for k=1:m, l=1:m) ) for j=1:n) ) for i=1:n)
          )

# constraint (1)          
@constraint(mod, cst1_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 

# constraint (2) 
@constraint(mod, cst2_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])

# constraint (3) 
@constraint(mod, cst3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])

# constraint (4) 
@constraint(mod, cst4_[i=1:n, j=1:n, k=1:m, l=1:m], y[i,k] + y[j,l] - 1 <= z[i,j,k,l])

# constraint (5) 
@constraint(mod, cst5_[i=1:n, j=1:n, k=1:m; i!=j], x[i,j] + x[j,i] >= z[i,j,k,k])

# constraint (6) 
@constraint(mod, cst6_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                 - 
                                 sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                 <= C
            )

# constraint (7) 
@constraint(mod, cst7_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] * (d[j] - a[i] -  f[i,j] * t[k,l]) >= 0)

# --- Resolution --------------------------------------------------------

optimize!(mod)

# --- Results --------------------------------------------------------

global cout = 0
global penalite = 0

if termination_status(mod) == OPTIMAL
    println("Optimal value of the objective function: ", objective_value(mod))

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


    println("Assigment truck to dock:")
    for i=1:n,k=1:m
         if value.(y[i,k])==1
              println("  truck $i ⟶ dock $k | arrival: ", a[i]," ⟶ departure: ", d[i])
         end
    end

    for i=1:n, j=1:n, k=1:m, l=1:m
         if value.(z[i,j,k,l])==1
              println("transfert of pallets between truck/dock ($i,$k) and ($j,$l)")
         end
    end
end