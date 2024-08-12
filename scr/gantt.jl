using PyPlot

c = [1 1; 
     1 1]

t = [1 1; 
     1 1]

p = [0 1 1 1 ;
     1 0 1 1 ;
     1 1 0 1 ;
     0 1 1 0]

f = [0 2 2 2; 
     2 0 2 2;
     2 2 0 2;
     0 2 2 0]

a = [15.42, 15.50, 17.00, 16.52]
d = [16.41, 16.41, 18.00, 17.57]
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

truckID   =  ["A", "B", "C", "D"]

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

t = [0 1 2 1 ;
     1 0 1 2 ;
     2 1 0 1 ;
     1 2 1 0 ]

t=t./10.0

c = [1 1 1 1; 
     1 1 1 1; 
     1 1 1 1; 
     1 1 1 1 ]     

using JuMP, GLPK

mod = Model(GLPK.Optimizer)

n = 4 # number of trucks / nombre de camions
m = 2 # number of docks / nombre de quais #quais pairs + 1 dummy quai

@variable(mod, y[1:n,1:m], Bin)
@variable(mod, dock[1:m], Bin)
@variable(mod, z[1:n,1:n,1:m,1:m], Bin)
@variable(mod, ϕ[1:n,1:n], Bin )

#@objective(mod, Max, sum(y[t,q] for t=1:n, q=1:m))
@objective(mod, Min, sum(c[k,l] * t[k,l] * z[i,j,k,l] for i=1:n, j=1:n, k=1:m, l=1:m))

# ----- un seul camion (sans superposition de presence) a la fois sur un quai libre
@constraint(mod, [t=1:n], sum(y[t,q] for q=1:m) == 1) # !!! gerer les affectations impossibles avec dummy quais
K = [[1,2],[2,1],[3,4],[4,3]]
for i in 1:4
     @constraint(mod, [q=1:m, i=1:n], sum(y[t,q] for t in K[i]) <= dock[q])
end
# ----- echange possible de marchandises entre (i,k) et (j,l)

C = [[2], [1], [4], [3]] # ensembles compatibles entre produit i et j

@constraint(mod, [i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[i,k])
@constraint(mod, [i=1:n, j=1:n, k=1:m, l=1:m], z[i,j,k,l] <= y[j,l])
@constraint(mod, [i=1:n, j in C[i], k=1:m, l=1:m; i!=j], z[i,j,k,l] >= y[i,k] + y[j,l] -1)

#@constraint(mod, [i=1:n, j in C[i], k=1:m, l=1:m; i!=j], z[i,j,k,l] * (d[j] - a[i] - f[i,j] * t[k,l]) >= 0)

@constraint(mod, [i=1:n, j in C[i], k=1:m, l=1:m; i!=j], z[i,j,k,l] * (d[j] - a[i] - f[i,j] * t[k,l]) <= 100*ϕ[i,j])

optimize!(mod)





if termination_status(mod) == OPTIMAL
     println("Optimal value of the objective function: ", objective_value(mod))
     println("Assigment truck to dock:")
     for t=1:n,q=1:m
          if value.(y[t,q])==1
               println("  truck $t ⟶ dock $q | arrival: ", hourStr(a[t])," ⟶ departure: ", hourStr(d[t]))
          end
     end

     for i=1:n, j=1:n, k=1:m, l=1:m
          if value.(z[i,j,k,l])==1
               println("echange possible entre camion/quai ($i,$k) et ($j,$l)")
          end
     end
end

for i=1:n, j in C[i], k=1:m, l=1:m
     if i!=j
          print("$i  $j  $k  $l : $(d[j])  $(a[i])  $(f[i,j] * t[k,l]) | ")
          println( 1 * (d[j] - a[i] - f[i,j] * t[k,l]) )
     end
end

for i=1:n, j=1:n
          print("$i  $j  | ")
          println( value(ϕ[i,j]) )
end
