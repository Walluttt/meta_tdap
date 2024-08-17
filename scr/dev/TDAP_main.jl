# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
# TDAP: solving single objective formulations M and G

println("\n  TDAP: Solving single objective formulations M and G \n")


# =============================================================================
# Load the codes 
# =============================================================================

println("  Load and compile the code...")

using Printf 
using JuMP 
using GLPK 
#using Gurobi
using PyPlot

include("TDAP_datastructures.jl")
include("TDAP_filesManagement.jl")
include("TDAP_display.jl")
include("TDAP_processingInstance.jl")
include("TDAP_formulations.jl")
include("TDAP_graphics.jl")
include("TDAP_tools.jl")

global experiment = true      # true → perform all the instances | false → perform one instance
global display    = false     # true → output information in the terminal | false → nothing 
global graphic    = false     # true → output information graphically  | false → nothing
IPsolver = GLPK.Optimizer     # Setup the IP solver with GLPK → GLPK.Optimizer
#IPsolver = Gurobi.Optimizer  # Setup the IP solver with Gurobi → Gurobi.Optimizer


# =============================================================================
# Get the filenames of the instance(s) to perform
# =============================================================================

if !experiment
    # 1 instance only

    path = "../../data/singleObjective/didactic/"
    fnames = ["contreexemple"]

    #path = "../../data/singleObjective/singleObjectiveGelareh2016/data_10_3/"
    #fnames = ["data_10_3_0"]

else
    # a collection of instances

    path = "../../data/singleObjective/singleObjectiveGelareh2016/"
    fnames = setfname() # vector with all the filenames of instances available in folder given by path

end
nInstances = length(fnames)


# =============================================================================
# Solving instance(s) with formaulation M and G
# =============================================================================

# ----------------------------------------------------------------------------
# Vectors to store the optimal solutions

all_OptSolutionM::Vector{Solution} = Vector{Solution}(undef,nInstances)
all_OptSolutionG::Vector{Solution} = Vector{Solution}(undef,nInstances)

if !display 
    println("\n  Summary:")
    @printf("    fname               " )
    @printf(" | for" )
    @printf(" | time (s)")
    @printf(" |   zOpt")
    @printf(" | zOptCost")
    @printf(" | zOptPenalty")
    @printf(" | nTruckAssigned")
    @printf(" | nTransfertDone")
    @printf(" | pTransfertDone (%%)\n")
end

for iInstance = 1:nInstances

    # -----------------------------------------------------------------------------
    # Load a numerical instance and present it
    instance = loadTDAP_singleObjective(path, fnames[iInstance])
    display ? displayInstance(instance) : nothing
    graphic ? drawGanttInstance(instance) : nothing

    # -----------------------------------------------------------------------------
    # Compute the additionnal information required by the model and display it
    δ, tr, atr, dtr = processingInstance(instance)
    display ? displayProcessing(δ, tr, atr, dtr, instance) : nothing 


    # =============================================================================
    # Formulation M
    # =============================================================================

    display ? nothing : @printf("    %-20s |   M", fnames[iInstance] )

    # -----------------------------------------------------------------------------
    # Setup the model
    modM = formulation_M(instance, δ, atr, dtr, IPsolver)

    # -----------------------------------------------------------------------------
    # Compute the optimal solution
    start  = time()
    optimize!(modM)
    t_elapsed = time()-start

    # -----------------------------------------------------------------------------
    # Query the optimal solution
    if termination_status(modM) == OPTIMAL
        all_OptSolutionM[iInstance] = queryOptimalSolutionMonoObj(t_elapsed, modM, instance)
        display ? displayOptimalSolution("Formulation M", t_elapsed, modM, instance) : nothing
        #@assert solution_checkerM(instance, δ, tr, modM) "Fatal error (with the formulation M) !!!"
        @assert solution_checkerValues(instance, modM) "Fatal error (optimal solution no valid) !!!"
        graphic ? drawLoadTerminal("Formulation M", instance, tr, atr, dtr, modM, :yLim_Off) : nothing 
    else
        @assert false "No optimal solution found!!!"
    end

    if !display
        @printf(" | %8.2f", all_OptSolutionM[iInstance].tElapsed)
        @printf(" | %6d", all_OptSolutionM[iInstance].zOpt)
        @printf(" |   %6d", all_OptSolutionM[iInstance].zOptCost)
        @printf(" |      %6d", all_OptSolutionM[iInstance].zOptPenalty)
        @printf(" |             %2d", all_OptSolutionM[iInstance].nTruckAssigned)
        @printf(" |           %4d", all_OptSolutionM[iInstance].nTransfertDone)
        @printf(" |             %6.2f \n", all_OptSolutionM[iInstance].pTransfertDone)
    end


    # =============================================================================
    # Formulation G
    # =============================================================================

    display ? nothing : @printf("    %-20s |   G", fnames[iInstance] )

    # -----------------------------------------------------------------------------
    # Setup the model
    modG = formulation_G(instance, δ, atr, dtr, IPsolver)

    # -----------------------------------------------------------------------------
    # Compute the optimal solution
    start  = time()
    optimize!(modG)
    t_elapsed = time()-start

    # -----------------------------------------------------------------------------
    # Query the optimal solution
    if termination_status(modG) == OPTIMAL
        all_OptSolutionG[iInstance] = queryOptimalSolutionMonoObj(t_elapsed, modG, instance)
        display ? displayOptimalSolution("Formulation G", t_elapsed, modG, instance) : nothing 
        @assert solution_checkerValues(instance, modG) "Fatal error (optimal solution no valid) !!!"
        graphic ? drawLoadTerminal("Formulation G", instance, tr, atr, dtr, modG, :yLim_Off) : nothing 
    else
        @assert false "No optimal solution found!!!"
    end

    if !display
        @printf(" | %8.2f", all_OptSolutionG[iInstance].tElapsed)
        @printf(" | %6d", all_OptSolutionG[iInstance].zOpt)
        @printf(" |   %6d", all_OptSolutionG[iInstance].zOptCost)
        @printf(" |      %6d", all_OptSolutionG[iInstance].zOptPenalty)
        @printf(" |             %2d", all_OptSolutionG[iInstance].nTruckAssigned)
        @printf(" |           %4d", all_OptSolutionG[iInstance].nTransfertDone)
        @printf(" |             %6.2f \n", all_OptSolutionG[iInstance].pTransfertDone)
    end

end
