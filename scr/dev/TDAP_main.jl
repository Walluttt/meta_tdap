
using Printf 
using JuMP, GLPK

include("TDAP_datastructures.jl")
include("TDAP_filesManagement.jl")
include("TDAP_display.jl")
include("TDAP_processingInstance.jl")
include("TDAP_formulations.jl")
include("TDAP_graphics.jl")
include("TDAP_tools.jl")

# -----------------------------------------------------------------------------
path = "../../data/singleObjective/didactic/"
#file = "exemple"
file = "contreexempleM"

#path = "../../data/singleObjective/singleObjectiveGelareh2016/data_10_3/"
#file = "data_10_3_4"
#path = "../../data/singleObjective/singleObjectiveGelareh2016/data_12_4/"
#file = "data_12_4_2"

# -----------------------------------------------------------------------------
# Load a numerical instance and output it
instance = loadTDAP_singleObjective(path, file)
displayInstance(instance)
drawGanttInstance(instance)

# -----------------------------------------------------------------------------
# Compute the additionnal information required by the model and display it
δ, tr, atr, dtr = processingInstance(instance)
displayProcessing(δ, tr, atr, dtr)

# -----------------------------------------------------------------------------
# Setup the model
IPsolver = GLPK.Optimizer
mod = formulation_M(instance, δ, atr, dtr, IPsolver)

# -----------------------------------------------------------------------------
# Compute the optimal solution
start  = time()
optimize!(mod)
t_formulationM = time()-start

# -----------------------------------------------------------------------------
# Query the optimal solution
if termination_status(mod) == OPTIMAL
    displayOptimalSolution(t_formulationM, mod, instance)
    @assert solution_checkerM(instance, δ, tr, mod) "Fatal error (with the formulation M) !!!"
    @assert solution_checkerValues(instance, mod) "Fatal error (optimal solution no valid) !!!"
    drawLoadTerminal(instance, tr, atr, dtr, mod, :yLim_Off)
else
    @assert false "No optimal solution found!!!"
end

# -----------------------------------------------------------------------------

