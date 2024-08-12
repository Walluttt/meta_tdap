#=  Generateur d'instances de TDAP
    Scenario dans lequel on a des camions a 6 essieux qui amenent des palettes a ventiler sur des camions a 3 essieux.
=#

using Random, Distributions

#
# Generation de la flotte de vehicules et des quantites de palettes transportees
#

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


#
# Generation des fenetres de temps ============================================
#

for tr in 1:nbrCamions6essieux
    hArrivee = max(8.00, rand(Normal(11,3)))
    hDepart = hArrivee + 2*chargementCamions6essieux[tr]/60 + 0.25
    if hDepart > 19.00 
        delta = hDepart - 19.00
        hDepart = 19.00
        hArrivee = hArrivee - delta
    end
    println("camion 6 essieux $tr : hArrivee  : $hArrivee -> hDepart : $hDepart")
end

for tr in 1:nbrCamions3essieux
    hArrivee = max(8.00, rand(Normal(13,3)))
    hDepart = hArrivee + 2*chargementCamions3essieux[tr]/60 + 0.25 + 0.5
    if hDepart > 19.00 
        delta = hDepart - 19.00
        hDepart = 19.00
        hArrivee = hArrivee - delta
    end
    println("camion 3 essieux $tr : hArrivee  : $hArrivee -> hDepart : $hDepart")
end
