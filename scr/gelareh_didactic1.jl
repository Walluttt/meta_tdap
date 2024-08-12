using JuMP, GLPK, PyPlot

# --- given parameters --------------------------------------------------------

# number of trucks / nombre de camions
n = 3 
# number of docks / nombre de quais 
m = 3 
# operational cost per unit time from dock k to dock l 
c = [0.0 1.0 1.0; 
     1.0 0.0 2.0; 
     1.0 2.0 0.0 ]
# operational time for pallets from dock k to dock l  (in minutes, 0<=minutes<=59)
t = [0.00 0.01 0.04; 
     0.01 0.00 0.03; 
     0.04 0.03 0.00 ]

# penalty cost per unit cargo from truck i to truck j
p = [ 0 0 52;
      24 0 0;
      0 23 0 ]

# number of pallets transferring from truck i to truck j 
f = [ 0 0 1;
      1 0 0;
      0 1 0 ]
# capacity of the cross dock terminal (maximum number of cargos the cross dock can hold at a time)
C = 406 # not given into the note

# arrival time of truck i (in hour.minutes, 0<=hour<=23, 0<=minutes<=59)
a = [18.45, 18.30, 19.12]
# departure time of truck i
d = [20.20, 19.46, 20.49]

# --- built parameters --------------------------------------------------------

# 1 iff truck i departs no later than truck j arrives, 0 otherwise
δ=zeros(Int64,n,n)  

for i=1:n, j=1:n
    if i!=j
        if d[i] <= a[j]
            δ[i,j] = 1
        end
    end
end

@show δ

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

# -----------------------------------------------------------------------------

occupation = d.-a

hmin = floor(Int,minimum(a))
hmax = ceil(Int,maximum(d))
hstr = []
colors=[]
for i in hmin:hmax
     push!(hstr,string(i)*":00")
     push!(colors,[rand(),rand(),rand()])
end 
xticks(collect(hmin:hmax), hstr)

#for i in 
#string(round(Int,15.42)) * ":" * string(round(Int,(15.42-floor(15.42))*100))
function hourStr(hourFloat)
     hhStr = string(round(Int,hourFloat))
     mmStr = string(round(Int,(hourFloat-floor(hourFloat))*100))
     if length(mmStr)==1
          mmStr = "0" * mmStr
     end
     return hhStr * ":" * mmStr
end

truckID   =  ["1", "2", "3"]

title("Planning of trucks",fontsize=12)
xlim([hmin-1,hmax+1])

xlabel("time")
ylabel("truck ID")
barh(truckID, left=a, width=occupation, height=0.25, color=colors)
gca().invert_yaxis()

for i in 1:length(a)
     text(a[i],i-1+0.25,fontsize=8, string(round(Int,a[i])) * ":" * string(round(Int,(a[i]-floor(a[i]))*100)))
     text(d[i],i-1+0.25,fontsize=8, string(round(Int,d[i])) * ":" * string(round(Int,(d[i]-floor(d[i]))*100)))
end

for i in 1:length(a)
     xMilieuD = a[i]+(d[i]-a[i])/2
     for j in 1:length(a)    
          if f[i,j] != 0
               xMilieuA = a[j]+(d[j]-a[j])/2 + rand()*0.5 - 0.25
               annotate(".",xy=[xMilieuA;j-1],arrowprops=Dict("arrowstyle"=>"->"),xytext=[xMilieuD;i-1])
          end
     end
end

# --- formulation introduced by Gelareh et al. in 2016 modif XG ---------------------------

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

# constraint (2)          
@constraint(mod, cst2_[i=1:n], sum(y[i,k] for k=1:m) <= 1) 

# constraint (3) 
@constraint(mod, cst3_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])

# constraint (4) 
@constraint(mod, cst4_[i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])

# constraint (5) 
@constraint(mod, cst5_[i=1:n, j=1:n, k=1:m; i!=j], y[i,k] + y[j,k] <= 1 + δ[i,j] + δ[j,i])

# constraint (6) 
@constraint(mod, cst6_[i=1:n, j=1:n, k=1:m; i!=j],z[i,j,k,k] <= δ[i,j] )

# constraint (7) 
@constraint(mod, cst7_[r=1:2*n], sum(f[i,j] * z[i,j,k,l] for i in atr[r], j=1:n, k=1:m, l=1:m)
                                 - 
                                 sum(f[i,j] * z[i,j,k,l] for i=1:n, j in dtr[r], k=1:m, l=1:m)
                                 <= C
            )

# constraint (8) 
@constraint(mod, cst8_[i=1:n, j=1:n, k=1:m, l=1:m; i!=j && (d[j] - a[i] -  f[i,j] * t[k,l])<=0 ],  z[i,j,k,l] == 0)


# --- Resolution --------------------------------------------------------

optimize!(mod)

# --- Results --------------------------------------------------------

global cout = 0
global penalite = 0

if termination_status(mod) == OPTIMAL
    println("\nOptimal value of the objective function: ", objective_value(mod))

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


    println("\nAssignment truck to dock:")
    for i=1:n,k=1:m
         if value.(y[i,k])==1
              println("  truck $i ⟶ dock $k | arrival: ", a[i]," ⟶ departure: ", d[i])
         end
    end

    println("\nFeasible transferts of pallet(s):")
    for i=1:n, j=1:n, k=1:m, l=1:m
         if value.(z[i,j,k,l])==1
              print("i=$i j=$j k=$k l=$l :   between truck/dock ($i,$k) and truck/dock ($j,$l)")
              if f[i,j]>0
                println(" -> ", f[i,j], " pallet(s)")
              else
                println(" ")
              end
         end
    end
end

#println("Demand in term of transfert of pallets:")
#for i=1:n, j=1:n, k=1:m, l=1:m
#     if f[i,j]!=0
#          println("i=$i j=$j k=$k l=$l : d[j]=$(d[j]) a[i]=$(a[i])  t[k,l])=$(t[k,l])  d[j]-a[i]-t[k,l]= ", (d[j] - a[i] - f[i,j] * t[k,l]))
#     end
#end

#for i=1:n, j=1:n, k=1:m
#    if i!=j
#        res = value.(y[i,k])+value.(y[j,k]) ≤ 1+ δ[i,j]+δ[j,i]
#        println("(i=$i k=$k) (j=$j k=$k) $(δ[i,j])  $(δ[j,i]) : $(value.(y[i,k]))  $(value.(y[j,k])) :", res)
#    end
#end    


yOpt=copy(value.(y)) 

# Activity at the docks
println("\nActivity at the docks: ")
trucksAtDock = [findall(>(0.0),yOpt[:,k]) for k in 1:m]
for k in 1:m
    print("  dock $k :")
    for i in trucksAtDock[k]
        print("truck $i at [$(a[i]),$(d[i])]  ")
        for j in trucksAtDock[k]
            if i!=j
                if !(d[i]<a[j] || d[j]<a[i])
                    @assert false "no valid solution: conflict between truck $i and truck $j at dock $k"
                end
            end
        end
    end
    println(" ")
end
println(" ")

# Assignment trucks to docks
println("Assignment of the trucks: ")
assignmentTruckDock = [findfirst(>(0.0),yOpt[i,:]) for i in 1:n]
for i in 1:n
    k = assignmentTruckDock[i]
    print("  truck $i to dock $k at [$(a[i]),$(d[i])]")
    for j in 1:n
        if i!=j
            l = assignmentTruckDock[j]
            if k==l 
                if d[i]<a[j] || d[j]<a[i]
                    print(" + truck $j at [$(a[j]),$(d[j])]")
                else
                    @assert false "no valid solution: conflict between truck $i and truck $j at dock $k"
                end
            end
        end
    end
    println(" ")
end
