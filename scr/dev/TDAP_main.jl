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

using Printf             # to format the output
using JuMP               # Algebraic modeling language to manage a MIP model
#using GLPK               # to use the GLPK MIP solver
using Gurobi            # to use the Gurobi MIP solver
using PyPlot             # to draw graphics
using DataFrames, CSV    # to manage dataframes
using PrettyTables       # to export table (dataframe) in latex

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
IPsolver = Gurobi.Optimizer   # Setup the IP solver with GLPK → GLPK.Optimizer
timeLimit = 600.0             # Setup the time limit (seconds) allowed to the MIP solver
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
    set_silent(modM)
    set_time_limit_sec(modM, timeLimit)

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

    elseif termination_status(modM) == TIME_LIMIT

        display ? println("Formulation M: time limit reached") : nothing
        all_OptSolutionM[iInstance] = Solution(timeLimit, -1, -1, -1, -1, -1, -1.0)

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
    set_silent(modG)
    set_time_limit_sec(modG, timeLimit)

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

    elseif termination_status(modG) == TIME_LIMIT

        display ? println("Formulation G: time limit reached") : nothing
        all_OptSolutionG[iInstance] = Solution(timeLimit, -1, -1, -1, -1, -1, -1.0)

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


# =============================================================================
# Record the results ath the end of a numerical experiment
# =============================================================================

if experiment

    # -------------------------------------------------------------------------
    # Save the results into a DataFrame

    dfM = DataFrame(Dict(n=>[getfield(x, n) for x in all_OptSolutionM] for n in fieldnames(Solution)))
    dfM[!, :fname] = copy(fnames)
    deleteat!(dfM,1)
    CSV.write("allresultsM.csv", dfM[!, [8,4,5,6,7,1,2,3]])

    dfG = DataFrame(Dict(n=>[getfield(x, n) for x in all_OptSolutionG] for n in fieldnames(Solution)))
    dfG[!, :fname] = copy(fnames)
    deleteat!(dfG,1)
    CSV.write("allresultsG.csv", dfG[!, [8,4,5,6,7,1,2,3]])


    # -------------------------------------------------------------------------
    # save the results into latex tables

    open("resM.tex", "w") do f
        pretty_table(f, dfM[!, [8,4,5,6,7,1,2,3]], backend = Val(:latex)) 
    end

    open("resG.tex", "w") do f
        pretty_table(f, dfG[!, [8,4,5,6,7,1,2,3]], backend = Val(:latex)) 
    end

    # -------------------------------------------------------------------------
    # save the results into latex tables

    figure("1. Comparison between formulations M and G", figsize = (12, 7.5))
    title("Optimal value of objective functions collected")
    xticks(rotation = 60, ha = "right")
    tick_params(labelsize = 6, axis = "x")
    xlabel("Name of datafiles")
    ylabel("Optimal value of objective functions")
    plot(dfM[!,:fname],dfM[!,:zOpt], linewidth=1, marker="o", markersize=5, color="r", label ="formulation M")
    plot(dfG[!,:fname],dfG[!,:zOpt], linewidth=1, marker="s", markersize=5, color="b", label ="formulation G")
    legend(loc=2, fontsize ="small")
    grid(color="gray", linestyle=":", linewidth=0.5)
    savefig("resultsMGobjFct.png")


    figure("2. Comparison between formulations M and G", figsize = (12, 7.5))
    title("Number of transfers collected")
    xticks(rotation = 60, ha = "right")
    tick_params(labelsize = 6, axis = "x")
    xlabel("Name of datafiles")
    ylabel("Number of transfers")
    plot(dfM[!,:fname],dfM[!,:nTransfertDone], linewidth=1, marker="o", markersize=5, color="r", label ="formulation M")
    plot(dfG[!,:fname],dfG[!,:nTransfertDone], linewidth=1, marker="s", markersize=5, color="b", label ="formulation G")
    legend(loc=2, fontsize ="small")
    grid(color="gray", linestyle=":", linewidth=0.5)
    savefig("resultsMGnbrTft.png")

    x_values = (String)[]
    y_values = (Int64)[]
    facecolors = (String)[]
    winner = (String)[]
    x_file = copy(dfM[!,:fname])
    y_M = copy(dfM[!,:nTransfertDone])
    y_G = copy(dfG[!,:nTransfertDone])
    for i in 1:length(y_M)
        if y_M[i] != -1 && y_G[i] != -1
            push!(x_values, x_file[i])
            if y_G[i] > y_M[i]
                println(">")
                push!(y_values, y_G[i] - y_M[i])
                push!(facecolors,"blue")
                push!(winner,"G")
            elseif y_G[i] < y_M[i]
                push!(y_values, y_M[i] - y_G[i])
                push!(facecolors,"red")
                push!(winner,"M")
            else
                push!(y_values, 0)
                push!(facecolors,"black")
                push!(winner,"=")
            end
        end
    end
    edgecolors = facecolors
    figure("3. Comparison between formulations M and G", figsize = (12, 7.5))
    title("Positive difference of number of transfers collected")    
    xticks(1:length(x_values), x_values, rotation = 60, ha = "right")
    tick_params(labelsize = 6, axis = "x")
    xlabel("Name of datafiles")
    ylabel("Positive difference of number of transfers")
    yticks(0:maximum(y_values))
    ylim(-1,5)
    bar(x_values, y_values, color=facecolors, edgecolor=edgecolors, alpha=0.5)
    for i=1:length(x_values)
        text(i, y_values[i]+0.075, winner[i], ha = "center")
    end
    savefig("resultsMGdifference.png")

end
