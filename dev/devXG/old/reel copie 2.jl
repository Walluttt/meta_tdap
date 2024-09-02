
#= Real cross-dock terminal located at :
   CARGOMATIC LAVAL (53)
   32 rue Bernard Palissy
   53960 Bonchamp
   https://www.cargomatic.fr/cargomatic-laval-53

   Terminal en I presentant 14 quais

=#

# --- given parameters --------------------------------------------------------

# number of docks / nombre de quais 
m = 14
dist = zeros(Float64,m,m)

for quaiDep in 1:Int(m/2), quaiArr in 1:m
    if quaiArr <= Int(m/2)
        dist[quaiDep,quaiArr] = 2 + (abs(quaiArr-quaiDep))*5.5 + 2
    else
        dist[quaiDep,quaiArr] = 2 + abs(m-quaiArr+1 - quaiDep)*5.5 + 16 + 2
    end
end

for quaiDep in Int(m/2)+1:m, quaiArr in 1:m
    if quaiArr <= Int(m/2)
        dist[quaiDep,quaiArr] = 2 + abs(m-quaiArr+1 - quaiDep)*5.5 + 16 + 2
    else
        dist[quaiDep,quaiArr] = 2 + (abs(quaiArr-quaiDep))*5.5 + 2
    end
end

@show dist

# engin de levage evoluant en moyenne a 5km/h
vitesse = 5 # kilometres/heure
t = dist.* vitesse/10000 # heure

using Luxor
Drawing(1000,1000,"Cross-Dock.png")
long=193; larg=100; echelle = 2

@png begin

    # pose le fond de l'image du terminal -------------------------------------
    sethue("black")
    rect(-200,-100,long*echelle,larg*echelle, :stroke)
    for i in 1:7
        sethue("black")
        rect(-245+i*55,-106,17*echelle,6*echelle, :fill)
        label = string(i)
        sethue("white")
        textcentered(label,-245+i*55+8*echelle,-97)
    end
    for i in 14:-1:8
        sethue("black")
        rect(-245+(14-i+1)*55,94,17*echelle,6*echelle, :fill)
        label = string(i)
        sethue("white")
        textcentered(label,-245+(14-i+1)*55+8*echelle,103)
    end  

    # pose tous les chemins de palettes depuis les quais 1 a 7 ----------------
    for quaiDep = 1:7

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

        # vers un quai du meme cote du terminal 
        pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-90)
        pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
        for i in 1:7
            if quaiDep!=i    
                pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
                pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),-90)
                poly([pt0, pt1, pt2, pt3], :stroke)
            end
        end    
    
        # vers un quai de l'autre cote du terminal 
        pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-90)
        pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
        for i in 1:7
            pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end  

    end
    

    # pose tous les chemins de palettes depuis les quais 8 a 14 ---------------
    for quaiDep = 8:14

        if quaiDep == 8
            sethue("royalblue1")
        elseif quaiDep == 9
            sethue("indianred1")
        elseif quaiDep == 10
            sethue("chartreuse")
        elseif quaiDep == 11
            sethue("gold")
        elseif quaiDep == 12
            sethue("orangered1") 
        elseif quaiDep == 13
            sethue("cyan") 
        elseif quaiDep == 14
            sethue("magenta")                      
        end

        quaiDep = quaiDep-7
    
        # vers un quai du meme cote du terminal 
        pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,90)
        pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
        for i in 1:7
            if quaiDep!=i  
                pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
                pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,90)
                poly([pt0, pt1, pt2, pt3], :stroke)
            end
        end
    
        # vers un quai de l'autre cote du terminal         
        pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,90)
        pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
        for i in 1:7 
            pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    
    end
end

 
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
            #if quaiDep!=i    
                pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
                pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),-90)
                poly([pt0, pt1, pt2, pt3], :stroke)
                Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
            #end
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

        if quaiDep == 8
            sethue("royalblue1")
        elseif quaiDep == 9
            sethue("indianred1")
        elseif quaiDep == 10
            sethue("chartreuse")
        elseif quaiDep == 11
            sethue("gold")
        elseif quaiDep == 12
            sethue("orangered1") 
        elseif quaiDep == 13
            sethue("cyan") 
        elseif quaiDep == 14
            sethue("magenta")                      
        end

        if quaiArr > Int(nbrQuai/2)
            # vers un quai du meme cote du terminal 
            quaiDep = nbrQuai-quaiDep+1 
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
            quaiDep = nbrQuai-quaiDep+1       
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


@png begin

    # pose le fond de l'image du terminal -------------------------------------
    nbrQuai = 14
    sethue("black")
    rect(-200,-100,long*echelle,larg*echelle, :stroke)
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

    traceFlux(2,4,4)
    traceFlux(1,4,4)
    traceFlux(2,1,4)  
end







nbrMaxCamions3essieux = 20
nbrMaxPalettesCamions3essieux = 16
nbrMaxCamions6essieux = 8
nbrMaxPalettesCamions6essieux = 40

nbrMaxCamions = nbrMaxCamions3essieux + nbrMaxCamions6essieux

nbrMaxPalettes = 320
nbPalettes = rand(100:nbrMaxPalettes)

nbrCamions3essieux = rand(Int(ceil(nbPalettes/nbrMaxPalettesCamions3essieux)):nbrMaxCamions3essieux)
nbrCamions6essieux = rand(Int(ceil(nbPalettes/nbrMaxPalettesCamions6essieux)):nbrMaxCamions6essieux)

# ventile les palettes sur les camions a 6 essieux
chargementCamions6essieux = min.(nbrMaxPalettesCamions6essieux, Int.(floor.(rand(Dirichlet(nbrCamions6essieux,10)) * nbPalettes)))

# initialise a vide le chargement des camions a 3 essieux
chargementCamions3essieux = zeros(Int, nbrCamions3essieux)

# matrice des flux de palettes entre camions 6 essieux et camions 3 essieux
f = zeros(Int, nbrCamions6essieux+nbrCamions3essieux, nbrCamions6essieux+nbrCamions3essieux)


for tr6 in 1:length(chargementCamions6essieux)

    # assure ventiler sur assez de camions 3 essieux que pour emporter tout le chargement
    divisionChargement = rand(Int(ceil(chargementCamions6essieux[tr6]/nbrMaxPalettesCamions3essieux)):nbrCamions3essieux-1)
    ventilationCamions3essieux = min.(nbrMaxPalettesCamions3essieux, Int.(floor.(rand(Dirichlet(divisionChargement,10)) * chargementCamions6essieux[tr6])))
    if sum(ventilationCamions3essieux) != chargementCamions6essieux[tr6]
        # ramasse le reste (du fait de l'application de floor) => assure gerer tout le chargement
        push!(ventilationCamions3essieux, chargementCamions6essieux[tr6] - sum(ventilationCamions3essieux))
    end

    # supprime des flux nuls
    deleteat!(ventilationCamions3essieux,findall(x->x==0,ventilationCamions3essieux))

    println("Chargement des camions 3 essieux :", chargementCamions3essieux)

    println("Camion 6 essieux numero >> $tr6 << ")
    println("                ventile >>",chargementCamions6essieux[tr6], "<< palettes")
    println("                   vers >>",ventilationCamions3essieux,"<< camions 3 essieux")
    

    # considere tous les camions 3 essieux dans un ordre quelconque
    iCamion=shuffle(collect(1:nbrCamions3essieux))

    for jNbPal in 1:length(ventilationCamions3essieux)
        println("Lot >>$jNbPal<< de ", ventilationCamions3essieux[jNbPal], " palettes :")
        affecte = false

        # tente de trouver une affection valide sur les camions a 3 essieux
        tr3 = 1
        while !affecte && tr3<= length(iCamion) 
            if chargementCamions3essieux[iCamion[tr3]] + ventilationCamions3essieux[jNbPal] <= nbrMaxPalettesCamions3essieux
                chargementCamions3essieux[iCamion[tr3]] += ventilationCamions3essieux[jNbPal]
                println("Camions 3 essieux numero >>", iCamion[tr3], "<< recoit ", ventilationCamions3essieux[jNbPal], " palettes")
                f[tr6,nbrCamions6essieux+iCamion[tr3]] = ventilationCamions3essieux[jNbPal]
                affecte = true
                deleteat!(iCamion,tr3)
            else
                tr3+=1
            end

            @assert !(!affecte && tr3>length(iCamion)) "non realisable"
        end
    end
    println("--------------------------------------")
end

@show f

# supprime les camions a 3 essieux qui n'auraient pas recu de palette
global supp=0
global c=nbrCamions6essieux+1
while c<=size(f,2)
    if iszero(f[:,c])
        f[:,c:end-1] = f[:,c+1:end]
        global supp+=1
    else
        global c+=1
    end
end
f=f[:,1:end-supp]
nbrCamions3essieux-=supp

println("\nChargement initial des camions 6 essieux :", chargementCamions6essieux)
println("\nChargement final des camions 3 essieux   :", chargementCamions3essieux)
@show f



mutable struct Camion
    numero     :: Int64
    hArr       :: Float64
    hDep       :: Float64
    nPalettes  :: Vector{Int64}
end

Camions6essieux = Array{Camion}(undef,nbrCamions6essieux)
for tr in 1:nbrCamions6essieux
    
    # Generation des fenetres de temps ----------------------------------------
    hArr = max(8.00, rand(Normal(11,3)))
    hDep = hArr + 2*chargementCamions6essieux[tr]/60 + 0.25
    if hDep > 19.00 
        delta = hDep - 19.00
        hDep = 19.00
        hArr = hArr - delta
    end
    println("camion 6 essieux $tr : hArr  : $hArr -> hDep : $hDep")
    Camions6essieux[tr] = Camion(tr, hArr, hDep, [chargementCamions6essieux[tr]])
end

Camions3essieux = Array{Camion}(undef,nbrCamions3essieux)
for tr in 1:nbrCamions3essieux

    # Generation des fenetres de temps ----------------------------------------
    hArr = max(8.00, rand(Normal(13,3)))
    hDep = hArr + 2*chargementCamions3essieux[tr]/60 + 0.25 + 0.5
    if hDep > 19.00 
        delta = hDep - 19.00
        hDep = 19.00
        hArr = hArr - delta
    end
    println("camion 3 essieux $tr : hArr  : $hArr -> hDep : $hDep")
    Camions3essieux[tr] = Camion(tr, hArr, hDep, [chargementCamions3essieux[tr]])
end


#
# Dessin du Gantt =============================================================
#
using Luxor

long=600; larg=600; echelle = 1

function traceCamionQuai(hArr, hDep, iCamion)
    tempsArr = hArr*60 - 8*60
    tempsDep = (hDep-hArr)*60
    if iCamion <=8 
        if iCamion == 1
            sethue("blue")
        elseif iCamion == 2
            sethue("red")
        elseif iCamion == 3
            sethue("green")
        elseif iCamion == 4
            sethue("orange")
        elseif iCamion == 5
            sethue("magenta") 
        elseif iCamion == 6
            sethue("turquoise3") 
        elseif iCamion == 7
            sethue("blueviolet")   
        elseif iCamion == 8
            sethue("sienna4")                      
        end 

    else
        sethue("black")  
    end      
    rect(-250+tempsArr*45/60, -280+(iCamion-1)*20-5, tempsDep*45/60, 10, :fill)
end


@png begin

    # pose le fond de l'image du Gantt ----------------------------------------
    sethue("black")
    rect(-300,-300,long*echelle,larg*echelle, :stroke)
    for i in 1:8
        pt1 = Point(-250,-280+(i-1)*20)
        pt2 = Point(245,-280+(i-1)*20)
        line(pt1, pt2, :stroke)
        label = string(i)
        textcentered(label, -260, -280+(i-1)*20)
    end
    for i in 9:28
        pt1 = Point(-250,-280+(i-1)*20)
        pt2 = Point(245,-280+(i-1)*20)
        line(pt1, pt2, :stroke)
        label = string(i-8)
        textcentered(label, -260, -280+(i-1)*20)
    end    
    for i in 1:12
        pt1 = Point(-250+(i-1)*45,270)
        pt2 = Point(-250+(i-1)*45,280)
        line(pt1, pt2, :stroke)
        label = string(i+7)
        textcentered(label, -250+(i-1)*45,295)
    end   

    # trace les camions -------------------------------------------------------
    for tr in 1:nbrCamions6essieux
        traceCamionQuai(Camions6essieux[tr].hArr, Camions6essieux[tr].hDep, tr)
    end
    for tr in 1:nbrCamions3essieux
        traceCamionQuai(Camions3essieux[tr].hArr, Camions3essieux[tr].hDep, tr+8)
    end

    for tr6 in 1:nbrCamions6essieux
        if tr6 == 1
            sethue("blue")
        elseif tr6 == 2
            sethue("red")
        elseif tr6 == 3
            sethue("green")
        elseif tr6 == 4
            sethue("orange")
        elseif tr6 == 5
            sethue("magenta") 
        elseif tr6 == 6
            sethue("turquoise3") 
        elseif tr6 == 7
            sethue("blueviolet")   
        elseif tr6 == 8
            sethue("sienna4")                      
        end 
        
        label = string(chargementCamions6essieux[tr6])
        textcentered(label, -250+(((Camions6essieux[tr6].hArr*60)- 8*60)*45/60) +3, -280+(tr6-1)*20-6)
    end 

for tr3 in 1:nbrCamions3essieux

    pas = 0
    for tr6 in 1:nbrCamions6essieux
        if tr6 == 1
            sethue("blue")
        elseif tr6 == 2
            sethue("red")
        elseif tr6 == 3
            sethue("green")
        elseif tr6 == 4
            sethue("orange")
        elseif tr6 == 5
            sethue("magenta") 
        elseif tr6 == 6
            sethue("turquoise3") 
        elseif tr6 == 7
            sethue("blueviolet")   
        elseif tr6 == 8
            sethue("sienna4")                      
        end 
        

        if f[tr6,tr3+nbrCamions6essieux] != 0 
            print(f[tr6,tr3+nbrCamions6essieux], " ")
            label = string(f[tr6,tr3+nbrCamions6essieux])
            println(">>>", Camions3essieux[tr3].hArr *45/60)
            textcentered(label, -250+(((Camions3essieux[tr3].hArr*60)- 8*60)*45/60) +pas+3, -280+(tr3-1+8)*20-6)
            pas+=15
        end
    end
    println(" ")
end

end
