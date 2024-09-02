# =============================================================================

function genereChargementsTransporter(nbrMaxCamions3essieux, 
                                      nbrMaxCamions6essieux, 
                                      nbrMaxPalettesCamions3essieux, 
                                      nbrMaxPalettesCamions6essieux,
                                      nbrMaxPalettes)

    nbrMaxCamions = nbrMaxCamions3essieux + nbrMaxCamions6essieux
    
    # fixe aleatoirement le nombre de palettes a transporter
    nbPalettes = rand(50:nbrMaxPalettes)
    
    # fixe le nombre de camions 3 et 6 essieux pour cette instance numerique
    nbrCamions3essieux = rand(Int(ceil(nbPalettes/nbrMaxPalettesCamions3essieux)):nbrMaxCamions3essieux)
    nbrCamions6essieux = rand(Int(ceil(nbPalettes/nbrMaxPalettesCamions6essieux)):nbrMaxCamions6essieux)
    
    # initialise a vide le chargement des camions a 3 essieux
    chargementCamions3essieux = zeros(Int, nbrCamions3essieux)
    # ventile aleatoirement les palettes a transporter sur les camions a 6 essieux
    chargementCamions6essieux = min.(nbrMaxPalettesCamions6essieux, Int.(floor.(rand(Dirichlet(nbrCamions6essieux,10)) * nbPalettes)))
    
    # matrice des flux de palettes entre camions 6 essieux et camions 3 essieux
    f = zeros(Int, nbrCamions6essieux+nbrCamions3essieux, nbrCamions6essieux+nbrCamions3essieux)
    
    # pour chaque camion 6 essieu, ventile son chargement sur des camions 3 essieux
    for tr6 in 1:length(chargementCamions6essieux)
    
        # -------------------------------------------------------------------------
        # 1) split le chargement d'un camion 6 essieu 
        #    en s'assurant de ventiler sur assez de camions 3 essieux que pour emporter tout le chargement
    
        divisionChargement = rand(Int(ceil(chargementCamions6essieux[tr6]/nbrMaxPalettesCamions3essieux)):nbrCamions3essieux-1)
        ventilationCamions3essieux = min.(nbrMaxPalettesCamions3essieux, Int.(floor.(rand(Dirichlet(divisionChargement,10)) * chargementCamions6essieux[tr6])))
        if sum(ventilationCamions3essieux) != chargementCamions6essieux[tr6]
            # ramasse le reste (du fait de l'application de floor) => assure gerer tout le chargement
            push!(ventilationCamions3essieux, chargementCamions6essieux[tr6] - sum(ventilationCamions3essieux))
        end
    
        # supprime des flux nuls (pas de camion fantome)
        deleteat!(ventilationCamions3essieux,findall(x->x==0,ventilationCamions3essieux))
    
        # resume :
        println("\nCharge actuelle des camions 3 essieux :", chargementCamions3essieux)
        println("Camion 6 essieux numero >> $tr6 << ")
        println("                ventile >> ", chargementCamions6essieux[tr6], " << palettes")
        println("                   vers >> ", ventilationCamions3essieux,     " << camions 3 essieux")
        
    
        # -------------------------------------------------------------------------
        # 2) affecte la ventilation etablie des palettes aux camions 3 essieux
    
        # considere tous les camions 3 essieux dans un ordre quelconque
        iCamion = shuffle(collect(1:nbrCamions3essieux))
    
        for jNbPal in 1:length(ventilationCamions3essieux)
            println("Lot >>$jNbPal<< de ", ventilationCamions3essieux[jNbPal], " palettes :")
            affecte = false
    
            # tente de trouver une affection valide du lot de palettes sur les camions a 3 essieux
            tr3 = 1
            while !affecte && tr3<= length(iCamion) 
                if chargementCamions3essieux[iCamion[tr3]] + ventilationCamions3essieux[jNbPal] <= nbrMaxPalettesCamions3essieux
    
                    chargementCamions3essieux[iCamion[tr3]] += ventilationCamions3essieux[jNbPal]
                    println("Camions 3 essieux numero >>", iCamion[tr3], "<< recoit ", ventilationCamions3essieux[jNbPal], " palettes")
                    # note dans la matrice f le flot de i (camion 6 essieu) vers j (camion 3 essieu)
                    f[tr6,nbrCamions6essieux+iCamion[tr3]] = ventilationCamions3essieux[jNbPal]
                    affecte = true
    
                    # empeche d'avoir au plus 1 flot de palettes d'un meme camion 6 essieux vers un meme camion 3 essieux
                    deleteat!(iCamion,tr3)
    
                else
                    tr3+=1
                end
    
                # ATTENTION : 
                # le caractere aleatoire des affectation des palettes des camions 6 essieux vers 3 essieux
                # peut emietter les capacites residuelles des camions 3 essieux et donc rendre impossible 
                # l'affectation d'un lot de palettes si celui-ci est important (plus de capa residuelle suffisante)
                # dans ce cas, on arrete sur ECHEC de la generation de l'instance.
                @assert !(!affecte && tr3>length(iCamion)) "non realisable"
            end
        end
        println("--------------------------------------")
    end
    
    
    # supprime les camions a 3 essieux qui n'auraient pas recu de palette (pas de camion fantome)
    supp = 0
    c = nbrCamions6essieux+1
    while c<=size(f,2)
        if iszero(f[:,c])
            f[:,c:end-1] = f[:,c+1:end]
            supp+=1
        else
            c+=1
        end
    end
    f=f[:,1:end-supp]
    nbrCamions3essieux-=supp

    return chargementCamions3essieux, chargementCamions6essieux, f
end
