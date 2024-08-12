
# =============================================================================
# solveur TDAP (depuis la generation d'une instance jusqu'a sa resolution)
#
# Hypotheses pour l'instance et la resolution :
#  - topologie du terminal inspiree d'une structure existante
#  - flotte de vehicules composee de 2 types de camions (3 et 6 essieux)
#  - camions entrants (livre des palettes) de type 6 essieux
#  - camions sortants (emporte les palettes) de type 3 essieux
#  - palettes manutentionnees par chariot elevateurs
#  - palettes recues conditionnees pour etre expediees (pas de recombinaison de palettes)
#  - palettes non-livrees retournent avec le camion entrant correspondant

using Luxor, PyPlot   # pour les dessins
using Random, Distributions # pour les chargements et fenetres de temps 
using JuMP, Gurobi


# -----------------------------------------------------------------------------

# --- formulation introduced by Gelareh et al. in 2016 modif XG ---------------------------

mod = Model(Gurobi.Optimizer)

# variables: 1 if truck i is assigned to dock k, 0 otherwise 
@variable(mod, y[1:n,1:m], Bin)

# variables: 1 if truck i is assigned to dock k and truck j to dock l, 0 otherwise
@variable(mod, z[1:n,1:n,1:m,1:m], Bin)
#@assert false "stop"
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
                if !(d[i]<=a[j] || d[j]<=a[i])
                    println("no valid solution: conflict between truck $i and truck $j at dock $k")
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
    if k == nothing
        print("  truck $i NOT ASSIGNED")
    else
        print("  truck $i to dock $k at [$(a[i]),$(d[i])]")
        for j in 1:n
            if i!=j
                l = assignmentTruckDock[j]
                if k==l 
                    if d[i]<=a[j] || d[j]<=a[i]
                        print(" + truck $j at [$(a[j]),$(d[j])]")
                    else
                        println("no valid solution: conflict between truck $i and truck $j at dock $k")
                        @assert false "no valid solution: conflict between truck $i and truck $j at dock $k"
                    end
                end
            end
        end
    end

    println(" ")
end


println("\nDrawing the transferts of pallet(s):")

#Drawing(1000,1000,"Cross-Dock.png")
long=193; larg=100; echelle = 2


function traceFlux(quaiDep::Int64, quaiArr::Int64, nbrQuai::Int64)

    if quaiDep <= Int(nbrQuai/2)

        # cas ou le quai de depart est dans la premiere moitie des quais
        println("quai depart au nord")

        if quaiDep == 1
            sethue("blue")
        elseif quaiDep == 2
            sethue("red3")
        elseif quaiDep == 3
            sethue("green")
        elseif quaiDep == 4
            sethue("darkgoldenrod")
        elseif quaiDep == 5
            sethue("orangered3") 
        elseif quaiDep == 6
            sethue("turquoise3") 
        elseif quaiDep == 7
            sethue("blueviolet")                      
        end 

        if quaiArr <= Int(nbrQuai/2)
            # vers un quai du meme cote du terminal 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            i = quaiArr   
            pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
            Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
        else
            # vers un quai de l'autre cote du terminal 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            i = nbrQuai-quaiArr+1
            pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),90)
            poly([pt0, pt1, pt2, pt3], :stroke)
            Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
        end     
    
    else

        # cas ou le quai de depart est dans la seconde moitie des quais
        println("quai depart au sud")  

        quaiDep = nbrQuai-quaiDep+1 
        if quaiDep == 1
            sethue("royalblue1")
        elseif quaiDep == 2
            sethue("indianred1")
        elseif quaiDep == 3
            sethue("chartreuse")
        elseif quaiDep == 4
            sethue("gold")
        elseif quaiDep == 5
            sethue("orangered1") 
        elseif quaiDep == 6
            sethue("cyan") 
        elseif quaiDep == 7
            sethue("magenta")                      
        end

        if quaiArr > Int(nbrQuai/2)
            # vers un quai du meme cote du terminal 
            #quaiDep = nbrQuai-quaiDep+1 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            i = nbrQuai-quaiArr+1
            if quaiDep!=i  
                pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
                pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,90)
                poly([pt0, pt1, pt2, pt3], :stroke)
                Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
            end

        else
            # vers un quai de l'autre cote du terminal  
            #quaiDep = nbrQuai-quaiDep+1       
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            i = quaiArr
            pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
            Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
        end
    
    end     

    return nothing
end


println("\nDrawing transferts of pallet(s):")
@png begin

    # pose le fond de l'image du terminal -------------------------------------
    nbrQuai = m
    sethue("black")
    rect(-200,-100,(10+17.5*Int(nbrQuai/2)+10*(Int(nbrQuai/2)-1))*echelle,larg*echelle, :stroke)
    for i in 1:Int(nbrQuai/2)
        sethue("black")
        rect(-245+i*55, -106, 17*echelle, 6*echelle, :fill)
        rect(-245+i*55, 94,   17*echelle, 6*echelle, :fill)
        sethue("white")
        label = string(i)
        textcentered(label, -245+i*55+8*echelle, -97)
        label = string(nbrQuai-i+1)
        textcentered(label, -245+i*55+8*echelle, 103)
    end 

    #sethue("black")

    for i=1:n, j=1:n, k=1:m, l=1:m
        if value.(z[i,j,k,l])==1
             print("i=$i j=$j k=$k l=$l :   between truck/dock ($i,$k) and truck/dock ($j,$l)")
             if f[i,j]>0
               println(" -> ", f[i,j], " pallet(s)")
               traceFlux(Int(k),Int(l),nbrQuai)
             else
               println(" ")
             end
        end
    end
 
end

# ==========================================
# Represente l'evolution de la charge du terminal en nombre de palettes

for r=1:2*n
    sommeIN = 0
    for i in atr[r], j=1:n, k=1:m, l=1:m
        if value.(z[i,j,k,l])==1
            sommeIN+=f[i,j]
            println("i=$i j=$j k=$k l=$l :   entree de ",f[i,j]," palettes between truck/dock ($i,$k) and truck/dock ($j,$l)")
        end
    end
    sommeOUT = 0
    for i=1:n, j in dtr[r], k=1:m, l=1:m
        if value.(z[i,j,k,l])==1
            sommeOUT+=f[i,j]
            println("i=$i j=$j k=$k l=$l :   sortie de ",f[i,j]," palettes between truck/dock ($i,$k) and truck/dock ($j,$l)")
        end
    end    
    println("au temps r=$r on a $sommeIN palettes entrees le terminal")
    println("                   $sommeOUT palettes sorties du terminal")
    println("              soit ", sommeIN-sommeOUT," palettes ≤ $C\n")    
end


function hourStr(hourFloat)
    hhStr = string(floor(Int,hourFloat))
    mmStr = string(round(Int,(hourFloat-floor(hourFloat))*60))
    if length(mmStr)==1
         mmStr = "0" * mmStr
    end
    return hhStr * ":" * mmStr
end

x=[hourStr(tr[i]) for i in 1:length(tr)]
y1 = zeros(Int,length(tr))
y2 = zeros(Int,length(tr))
y3 = zeros(Int,length(tr))
y4 = zeros(Int,length(tr))
y5 = zeros(Int,length(tr))
y6 = zeros(Int,length(tr))
y7 = zeros(Int,length(tr))
y8 = zeros(Int,length(tr))
for r=1:2*n
    for i in atr[r], j=1:n, k=1:m, l=1:m
        if value.(z[i,j,k,l])==1
            if i == 1
                y1[r] += f[i,j]
            elseif i==2
                y2[r] += f[i,j]
            elseif i==3
                y3[r] += f[i,j] 
            elseif i==4
                y4[r] += f[i,j]    
            elseif i==5
                y5[r] += f[i,j]  
            elseif i==6
                y6[r] += f[i,j]     
            elseif i==7
                y7[r] += f[i,j]    
            elseif i==8
                y8[r] += f[i,j]
            end
            println("i=$i j=$j k=$k l=$l :   entree de ",f[i,j]," palettes between truck/dock ($i,$k) and truck/dock ($j,$l)")
        end
    end
    for i=1:n, j in dtr[r], k=1:m, l=1:m
        if value.(z[i,j,k,l])==1
            if i == 1
                y1[r] -= f[i,j]
            elseif i==2
                y2[r] -= f[i,j]
            elseif i==3
                y3[r] -= f[i,j] 
            elseif i==4
                y4[r] -= f[i,j]    
            elseif i==5
                y5[r] -= f[i,j]  
            elseif i==6
                y6[r] -= f[i,j]     
            elseif i==7
                y7[r] -= f[i,j]    
            elseif i==8
                y8[r] -= f[i,j]
            end           
            println("i=$i j=$j k=$k l=$l :   sortie de ",f[i,j]," palettes between truck/dock ($i,$k) and truck/dock ($j,$l)")
        end
    end    
end

xticks(ha="right")
bar(x, y1, color="blue")
bar(x, y2, bottom=y1, color="red")
bar(x, y3, bottom=y1+y2, color="green")
bar(x, y4, bottom=y1+y2+y3, color="orange")
bar(x, y5, bottom=y1+y2+y3+y4, color="magenta")
bar(x, y6, bottom=y1+y2+y3+y4+y5, color="turquoise")
bar(x, y7, bottom=y1+y2+y3+y4+y5+y6, color="blueviolet")
bar(x, y8, bottom=y1+y2+y3+y4+y5+y6+y7, color="chocolate")
xlabel("heure")
ylabel("nombre de palettes")
title("Evolution du nombre de palettes dans le terminal")

