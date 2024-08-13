
using Printf 
using JuMP, GLPK

include("TDAP_datastructures.jl")
include("TDAP_filesManagement.jl")
include("TDAP_display.jl")
include("TDAP_processingInstance.jl")
include("TDAP_formulations.jl")
include("TDAP_graphics.jl")

# -----------------------------------------------------------------------------
#path = "../../data/singleObjective/didactic/"
#file = "exemple"
path = "../../data/singleObjective/singleObjectiveGelareh2016/data_10_3/"
file = "data_10_3_0"

# -----------------------------------------------------------------------------
instance = loadTDAP_singleObjective(path, file)
displayInstance(instance)
displayGanttInstance(instance)

# -----------------------------------------------------------------------------
δ, tr, atr, dtr = processingInstance(instance)
displayProcessing(δ, tr, atr, dtr)

# -----------------------------------------------------------------------------
IPsolver = GLPK.Optimizer
mod = formulation_M(instance, δ, atr, dtr, IPsolver)

# -----------------------------------------------------------------------------
start  = time()
optimize!(mod)
t_formulationM = time()-start

# -----------------------------------------------------------------------------
if termination_status(mod) == OPTIMAL
    displayOptimalSolution(t_formulationM, mod, instance)
    @assert solution_checkerM(instance, δ, tr, mod) "Fatal error!!!"
else
    @assert false "No optimal solution found!!!"
end

#if instance.d[j] > instance.a[i] && instance.a[j] < instance.d[i]
#    println(" erreur: intersection non vide")
#end

