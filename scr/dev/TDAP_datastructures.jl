# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
# data structure storing information describing a single objective instance

struct Instance

    name::String                # name of the instance
    
    n::Int64                    # number of trucks
    m::Int64                    # number of docks

    a::Vector{Int64}            # the arrival time of trucks (format: minutes ∈ [00:00;23:59])
    d::Vector{Int64}            # the departure time of trucks (format: minutes ∈ [00:00;23:59])

    t::Matrix{Int64}            # the operational times from dock k to dock l (format: minutes)
    f::Matrix{Int64}            # the number of pallets to transfert from truck i to truck j
    c::Matrix{Int64}            # the transportation cost (€) from dock k to dock l 
    p::Matrix{Int64}            # the penality (€) from truck i to truck j

    C::Int64                    # the maximum capacity value of the warehouse (number of pallets)
end


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