# =============================================================================
# Generation des fenetres de temps dans [8h;19h] pour les 3 types de camion 

function genererFenetreTemps(chargementCamions3essieux::Vector{Int64}, 
                             chargementCamions6essieux::Vector{Int64})

    nbrCamions3essieux = length(chargementCamions3essieux)
    nbrCamions6essieux = length(chargementCamions6essieux)

    # fenetres de temps pour camions 6 essieux (autour de 11h +/-3h) ----------                        
    Camions6essieux = Array{Camion}(undef,nbrCamions6essieux)
    for tr in 1:nbrCamions6essieux
        
        hArr = round(max(8.00, rand(Normal(11,2))), digits=2)
        hDep = round(hArr + 2*chargementCamions6essieux[tr]/60 + 0.25, digits=2) # 2 minutes/palette + 15 min/administratif
        if hDep > 19.00 
            delta = hDep - 19.00
            hDep = 19.00
            hArr = hArr - delta
        end
        println("camion 6 essieux $tr : hArr  : $hArr -> hDep : $hDep")
        Camions6essieux[tr] = Camion(tr, hArr, hDep, [chargementCamions6essieux[tr]])
    end
    
    # fenetres de temps pour camions 3 essieux (autour de 13h +/-3h) ----------      
    Camions3essieux = Array{Camion}(undef,nbrCamions3essieux)
    for tr in 1:nbrCamions3essieux
    
        hArr = round(max(8.00, rand(Normal(12,3))), digits=2)
        hDep = round(hArr + 2*chargementCamions3essieux[tr]/60 + 0.25 + 0.5, digits=2) # 2 min/palette + 15 min/administratif + 30 min/reception
        if hDep > 19.00 
            delta = hDep - 19.00
            hDep = 19.00
            hArr = hArr - delta
        end
        println("camion 3 essieux $tr : hArr  : $hArr -> hDep : $hDep")
        Camions3essieux[tr] = Camion(tr, hArr, hDep, [chargementCamions3essieux[tr]])
    end
    
    # retourne les vct de structure de type camion avec toutes les info
    return Camions3essieux, Camions6essieux
   
end