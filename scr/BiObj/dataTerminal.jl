# =============================================================================
# Calcul des distances entre quais sur base d'un terminal cross-dock reel 
#   (1) de conception en I 
#   (2) presentant 14 quais 
#   (3) localise a :
#     CARGOMATIC LAVAL (53)
#     32 rue Bernard Palissy
#     53960 Bonchamp
#     https://www.cargomatic.fr/cargomatic-laval-53

function calculDistancesEntreQuais(m::Int64)

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

    return dist
end

# =============================================================================
# Calcul des temps de deplacement entre quais
function calculTempsEntreQuais(dist, vitesse)

    t = dist.* vitesse/10000 # heure

    return t
end