# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
# data structure storing information describing a single objective instance
module Datastructures

export Instance, Solution, Solution2R


# Définition de la structure Instance
mutable struct Instance
    fname::String
    n::Int           # Nombre de camions
    m::Int           # Nombre de quais
    a::Vector{Int64} # Heures d'arrivée des camions
    d::Vector{Int64} # Heures de départ des camions
    t::Matrix{Int64} # Temps opérationnel entre quais
    f::Matrix{Int64} # Nombre de palettes
    c::Matrix{Int64} # Coûts de transport
    p::Matrix{Int64} # Pénalités
    C::Int64         # Capacité du quai
end

end  # module Datastructures


# -----------------------------------------------------------------------------
# data structure storing information describing an optimal solution + information derived

struct Solution

    tElapsed::Float64           # time consumed for computing the optimal solution

    zOpt::Int64                 # value of the aggregated objective function at the optimum 
    zOptCost::Int64             # value of the operational cost in the objective function at the optimum 
    zOptPenalty::Int64          # value of the penality cost in the  objective function at the optimum  
    
    totalTimeTransfert::Int64       # measure without operational cost
    totalQuantityTransfered::Int64  # measure without penalty cost

    nTruckAssigned::Int64       # number of trucks assigned to docks at the optimum 
    nTransfertDone::Int64       # number of transferts of pallets done between docks at the optimum
    pTransfertDone::Float64     # percentage of transferts of pallets done between docks at the optimum
    
end


# -----------------------------------------------------------------------------
# data structure storing information describing an optimal solution + information derived

struct Solution2R

    tElapsed::Float64           # time consumed for computing the optimal solution

    z1TransfertTime::Int64      # objFct1: value of total transfert time taken by the optimal solution     
    z2QuantityTransfered::Int64 # objFct2: value of the quantity of goods transfered by the optimal solution 
        
    nTruckAssigned::Int64       # number of trucks assigned to docks at the optimum 
    nTransfertDone::Int64       # number of transferts of pallets done between docks at the optimum
    pTransfertDone::Float64     # percentage of transferts of pallets done between docks at the optimum
    
end