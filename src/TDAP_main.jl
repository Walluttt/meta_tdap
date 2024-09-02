# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
# TDAP: solving single objective formulations M and G

println("\n  TDAP: Solving formulations M, G, 2M, and 2G \n")


# =============================================================================
# Load the codes 
# =============================================================================

println("  Load and compile the code...")

using Printf             # to format the output
using JuMP               # Algebraic modeling language to manage a MIP model
using GLPK               # to use the GLPK MIP solver
#using Gurobi            # to use the Gurobi MIP solver
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


global experiment = false     # true → perform all the instances | false → perform one instance
global display = false        # true → output information in the terminal | false → nothing 
global graphic = false        # true → output information graphically  | false → nothing
IPsolver = GLPK.Optimizer     # Setup the IP solver with GLPK → GLPK.Optimizer
#IPsolver = Gurobi.Optimizer  # Setup the IP solver with Gurobi → Gurobi.Optimizer
timeLimit = 600.0             # Setup the time limit (seconds) allowed to the MIP solver


# =============================================================================
# Get the filenames of the instance(s) to perform
# =============================================================================

if !experiment
    # 1 instance only

    path = "../data/singleObjective/didactic/"
    fnames = ["didactic"]

    #path = "../data/singleObjective/singleObjectiveGelareh2016/"
    #fnames = ["data_18_4_0"]#["data_10_3_0"]

else
    # a collection of instances

    path = "../data/singleObjective/singleObjectiveGelareh2016/"
    fnames = setfname() # vector with all the filenames of instances available in folder given by path

end
nInstances = length(fnames)


# =============================================================================
# Solving instance(s) with formaulation M and G
# =============================================================================

# ----------------------------------------------------------------------------
# Vectors to store the optimal solutions

all_OptSolutionM::Vector{Solution} = Vector{Solution}(undef, nInstances)
all_OptSolutionG::Vector{Solution} = Vector{Solution}(undef, nInstances)

all_OptSolution2M::Vector{Solution2R} = Vector{Solution2R}(undef, nInstances)
all_OptSolution2G::Vector{Solution2R} = Vector{Solution2R}(undef, nInstances)

if !display
    println("\n  Summary:")
    @printf("    fname               ")
    @printf(" | for")
    @printf(" | time (s)")
    @printf(" |   zOpt")
    @printf(" | zOptCost")
    @printf(" | zOptPenalty")
    @printf(" | totTimeTransfert")
    @printf(" | totQtyTransfered")
    @printf(" | nTruckAssigned")
    @printf(" | nTransfertDone")
    @printf(" | %%TransfertDone (%%)\n")
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
    # Formulation M (single objective)
    # =============================================================================

    display ? nothing : @printf("    %-20s |   M", fnames[iInstance])

    # -----------------------------------------------------------------------------
    # Setup the model
    modM = formulation_M(instance, δ, atr, dtr, IPsolver)
    set_silent(modM)
    set_time_limit_sec(modM, timeLimit)

    # -----------------------------------------------------------------------------
    # Compute the optimal solution
    start = time()
    optimize!(modM)
    t_elapsed = time() - start

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
        all_OptSolutionM[iInstance] = Solution(timeLimit, -1, -1, -1, -1, -1, -1, -1, -1.0)

    else

        @assert false "No optimal solution found (modM)!!!"

    end

    if !display
        @printf(" | %8.2f", all_OptSolutionM[iInstance].tElapsed)
        @printf(" | %6d", all_OptSolutionM[iInstance].zOpt)
        @printf(" |   %6d", all_OptSolutionM[iInstance].zOptCost)
        @printf(" |      %6d", all_OptSolutionM[iInstance].zOptPenalty)
        @printf(" |         %8d", all_OptSolutionM[iInstance].totalTimeTransfert)
        @printf(" |       %10d", all_OptSolutionM[iInstance].totalQuantityTransfered)
        @printf(" |             %2d", all_OptSolutionM[iInstance].nTruckAssigned)
        @printf(" |           %4d", all_OptSolutionM[iInstance].nTransfertDone)
        @printf(" |             %6.2f \n", all_OptSolutionM[iInstance].pTransfertDone)
    end



    # =============================================================================
    # Formulation G (single objective)
    # =============================================================================

    display ? nothing : @printf("    %-20s |   G", fnames[iInstance])

    # -----------------------------------------------------------------------------
    # Setup the model
    modG = formulation_G(instance, δ, atr, dtr, IPsolver)
    set_silent(modG)
    set_time_limit_sec(modG, timeLimit)

    # -----------------------------------------------------------------------------
    # Compute the optimal solution
    start = time()
    optimize!(modG)
    t_elapsed = time() - start

    # -----------------------------------------------------------------------------
    # Query the optimal solution
    if termination_status(modG) == OPTIMAL

        all_OptSolutionG[iInstance] = queryOptimalSolutionMonoObj(t_elapsed, modG, instance)
        display ? displayOptimalSolution("Formulation G", t_elapsed, modG, instance) : nothing
        @assert solution_checkerValues(instance, modG) "Fatal error (optimal solution no valid) !!!"
        graphic ? drawLoadTerminal("Formulation G", instance, tr, atr, dtr, modG, :yLim_Off) : nothing

    elseif termination_status(modG) == TIME_LIMIT

        display ? println("Formulation G: time limit reached") : nothing
        all_OptSolutionG[iInstance] = Solution(timeLimit, -1, -1, -1, -1, -1, -1, -1, -1.0)

    else

        @assert false "No optimal solution found (modG)!!!"

    end

    if !display
        @printf(" | %8.2f", all_OptSolutionG[iInstance].tElapsed)
        @printf(" | %6d", all_OptSolutionG[iInstance].zOpt)
        @printf(" |   %6d", all_OptSolutionG[iInstance].zOptCost)
        @printf(" |      %6d", all_OptSolutionG[iInstance].zOptPenalty)
        @printf(" |         %8d", all_OptSolutionG[iInstance].totalTimeTransfert)
        @printf(" |       %10d", all_OptSolutionG[iInstance].totalQuantityTransfered)
        @printf(" |             %2d", all_OptSolutionG[iInstance].nTruckAssigned)
        @printf(" |           %4d", all_OptSolutionG[iInstance].nTransfertDone)
        @printf(" |             %6.2f \n", all_OptSolutionG[iInstance].pTransfertDone)
    end



    # =============================================================================
    # Formulation 2M "
    # =============================================================================

    display ? nothing : @printf("    %-20s |  2M", fnames[iInstance])

    #=
    # -----------------------------------------------------------------------------
    # Setup the model / obj1
    modObj1 = formulation_2M(instance, δ, atr, dtr, IPsolver, :obj1)
    set_silent(modObj1)
    set_time_limit_sec(modObj1, timeLimit)

    # -----------------------------------------------------------------------------
    # Compute the optimal solution
    start  = time()
    optimize!(modObj1)
    t_elapsed = time()-start

    if termination_status(modObj1) == OPTIMAL
        display ? displayOptimalSolution2obj("Formulation obj1", t_elapsed, modObj1, instance) : nothing  
    else
        @assert false "No optimal solution found!!!"
    end
    =#


    # -----------------------------------------------------------------------------
    # Setup the model / obj2
    modObj2M = formulation_2M(instance, δ, atr, dtr, IPsolver, :obj2)
    set_silent(modObj2M)
    set_time_limit_sec(modObj2M, timeLimit)

    # -----------------------------------------------------------------------------
    # Compute the optimal solution
    start = time()
    optimize!(modObj2M)
    t_elapsed1 = time() - start

    # -----------------------------------------------------------------------------
    # Query the optimal solution
    if termination_status(modObj2M) == OPTIMAL
        display ? displayOptimalSolution2obj("Formulation 2M/obj2", t_elapsed1, modObj2M, instance) : nothing
        @assert solution_checkerValues(instance, modObj2M) "Fatal error (optimal solution no valid) !!!"

        # -----------------------------------------------------------------------------
        # Setup the model / lex(obj2→obj1)
        zOptObj2 = Int(floor(objective_value(modObj2M)))

        modObjLex21M = formulation_2M(instance, δ, atr, dtr, IPsolver, :obj1)
        @constraint(modObjLex21M, obj2cst, sum((sum(instance.f[i, j] * modObjLex21M[:z][i, j, k, l] for k = 1:instance.m, l = 1:instance.m)) for i = 1:instance.n, j = 1:instance.n) == zOptObj2)
        set_silent(modObjLex21M)
        set_time_limit_sec(modObjLex21M, timeLimit)

        # -----------------------------------------------------------------------------
        # Compute the optimal solution
        start = time()
        optimize!(modObjLex21M)
        t_elapsed2 = time() - start

        if termination_status(modObjLex21M) == OPTIMAL
            all_OptSolution2M[iInstance] = queryOptimalSolutionMultiObj(t_elapsed1 + t_elapsed2, modObjLex21M, instance)
            display ? displayOptimalSolution2obj("Formulation 2M lex21", t_elapsed2, modObjLex21M, instance) : nothing
            @assert solution_checkerValues(instance, modObjLex21M) "Fatal error (optimal solution no valid) !!!"
            graphic ? drawLoadTerminal("Formulation 2M", instance, tr, atr, dtr, modObjLex21M, :yLim_Off) : nothing

        elseif termination_status(modObjLex21M) == TIME_LIMIT

            display ? println("Formulation 2M/obj 1: time limit reached") : nothing
            all_OptSolution2M[iInstance] = Solution2R(timeLimit, -1, -1, -1, -1, -1.0)

        else

            @assert false "No optimal solution found!!! (modObjLex21M)"

        end

    elseif termination_status(modObj2M) == TIME_LIMIT

        display ? println("Formulation 2M/obj 2: time limit reached") : nothing
        all_OptSolution2M[iInstance] = Solution2R(timeLimit, -1, -1, -1, -1, -1.0)

    else

        @assert false "No optimal solution found!!! (modObj2M)"

    end

    if !display
        @printf(" | %8.2f", all_OptSolution2M[iInstance].tElapsed)
        @printf(" |      . |        . |           . | ")
        @printf("        %8d", all_OptSolution2M[iInstance].z1TransfertTime)
        @printf(" |       %10d", all_OptSolution2M[iInstance].z2QuantityTransfered)
        @printf(" |             %2d", all_OptSolution2M[iInstance].nTruckAssigned)
        @printf(" |           %4d", all_OptSolution2M[iInstance].nTransfertDone)
        @printf(" |             %6.2f \n", all_OptSolution2M[iInstance].pTransfertDone)
    end




    # =============================================================================
    # Formulation 2G "
    # =============================================================================

    display ? nothing : @printf("    %-20s |  2G", fnames[iInstance])

    #=
    # -----------------------------------------------------------------------------
    # Setup the model / obj1
    modObj1 = formulation_2G(instance, δ, atr, dtr, IPsolver, :obj1)
    set_silent(modObj1)
    set_time_limit_sec(modObj1, timeLimit)

    # -----------------------------------------------------------------------------
    # Compute the optimal solution
    start  = time()
    optimize!(modObj1)
    t_elapsed = time()-start

    if termination_status(modObj1) == OPTIMAL
        display ? displayOptimalSolution2obj("Formulation obj1", t_elapsed, modObj1, instance) : nothing  
    else
        @assert false "No optimal solution found!!!"
    end
    =#


    # -----------------------------------------------------------------------------
    # Setup the model / obj2
    modObj2G = formulation_2G(instance, δ, atr, dtr, IPsolver, :obj2)
    set_silent(modObj2G)
    set_time_limit_sec(modObj2G, timeLimit)

    # -----------------------------------------------------------------------------
    # Compute the optimal solution
    start = time()
    optimize!(modObj2G)
    t_elapsed1 = time() - start

    # -----------------------------------------------------------------------------
    # Query the optimal solution
    if termination_status(modObj2G) == OPTIMAL
        display ? displayOptimalSolution2obj("Formulation 2G/obj2", t_elapsed1, modObj2G, instance) : nothing
        @assert solution_checkerValues(instance, modObj2G) "Fatal error (optimal solution no valid) !!!"

        # -----------------------------------------------------------------------------
        # Setup the model / lex(obj2→obj1)
        zOptObj2 = Int(floor(objective_value(modObj2G)))

        modObjLex21G = formulation_2G(instance, δ, atr, dtr, IPsolver, :obj1)
        @constraint(modObjLex21G, obj2cst, sum((sum(instance.f[i, j] * modObjLex21G[:z][i, j, k, l] for k = 1:instance.m, l = 1:instance.m)) for i = 1:instance.n, j = 1:instance.n) == zOptObj2)
        set_silent(modObjLex21G)
        set_time_limit_sec(modObjLex21G, timeLimit)

        # -----------------------------------------------------------------------------
        # Compute the optimal solution
        start = time()
        optimize!(modObjLex21G)
        t_elapsed2 = time() - start

        if termination_status(modObjLex21G) == OPTIMAL
            all_OptSolution2G[iInstance] = queryOptimalSolutionMultiObj(t_elapsed1 + t_elapsed2, modObjLex21G, instance)
            display ? displayOptimalSolution2obj("Formulation 2G lex21", t_elapsed2, modObjLex21G, instance) : nothing
            @assert solution_checkerValues(instance, modObjLex21G) "Fatal error (optimal solution no valid) !!!"
            graphic ? drawLoadTerminal("Formulation 2G", instance, tr, atr, dtr, modObjLex21G, :yLim_Off) : nothing

        elseif termination_status(modObjLex21G) == TIME_LIMIT

            display ? println("Formulation 2G/obj 1: time limit reached") : nothing
            all_OptSolution2G[iInstance] = Solution2R(timeLimit, -1, -1, -1, -1, -1.0)

        else

            @assert false "No optimal solution found (modObjLex21G)!!!"

        end

    elseif termination_status(modObj2G) == TIME_LIMIT

        display ? println("Formulation 2G/obj 2: time limit reached") : nothing
        all_OptSolution2G[iInstance] = Solution2R(timeLimit, -1, -1, -1, -1, -1.0)

    else

        @assert false "No optimal solution found (modObj2G)!!!"

    end

    if !display
        @printf(" | %8.2f", all_OptSolution2G[iInstance].tElapsed)
        @printf(" |      . |        . |           . | ")
        @printf("        %8d", all_OptSolution2G[iInstance].z1TransfertTime)
        @printf(" |       %10d", all_OptSolution2G[iInstance].z2QuantityTransfered)
        @printf(" |             %2d", all_OptSolution2G[iInstance].nTruckAssigned)
        @printf(" |           %4d", all_OptSolution2G[iInstance].nTransfertDone)
        @printf(" |             %6.2f \n", all_OptSolution2G[iInstance].pTransfertDone)
    end

end



# =============================================================================
# Record the results ath the end of a numerical experiment
# =============================================================================

if experiment

    # -------------------------------------------------------------------------
    # Save the results into a DataFrame

    dfM = DataFrame(Dict(n => [getfield(x, n) for x in all_OptSolutionM] for n in fieldnames(Solution)))
    dfM[!, :fname] = copy(fnames)
    deleteat!(dfM, 1)
    CSV.write("allresultsM.csv", dfM[!, [10, 4, 7, 8, 9, 6, 5, 2, 1, 3]])

    dfG = DataFrame(Dict(n => [getfield(x, n) for x in all_OptSolutionG] for n in fieldnames(Solution)))
    dfG[!, :fname] = copy(fnames)
    deleteat!(dfG, 1)
    CSV.write("allresultsG.csv", dfG[!, [10, 4, 7, 8, 9, 6, 5, 2, 1, 3]])

    df2M = DataFrame(Dict(n => [getfield(x, n) for x in all_OptSolution2M] for n in fieldnames(Solution2R)))
    df2M[!, :fname] = copy(fnames)
    deleteat!(df2M, 1)
    CSV.write("allresults2M.csv", df2M[!, [7, 4, 5, 6, 2, 1, 3]])

    df2G = DataFrame(Dict(n => [getfield(x, n) for x in all_OptSolution2G] for n in fieldnames(Solution2R)))
    df2G[!, :fname] = copy(fnames)
    deleteat!(df2G, 1)
    CSV.write("allresults2G.csv", df2G[!, [7, 4, 5, 6, 2, 1, 3]])


    # -------------------------------------------------------------------------
    # save the results into latex tables

    open("resM.tex", "w") do f
        pretty_table(f, dfM[!, [10, 4, 7, 8, 9, 6, 5, 2, 1, 3]], backend=Val(:latex))
    end

    open("resG.tex", "w") do f
        pretty_table(f, dfG[!, [10, 4, 7, 8, 9, 6, 5, 2, 1, 3]], backend=Val(:latex))
    end

    open("res2M.tex", "w") do f
        pretty_table(f, df2M[!, [7, 4, 5, 6, 2, 1, 3]], backend=Val(:latex))
    end

    open("res2G.tex", "w") do f
        pretty_table(f, df2G[!, [7, 4, 5, 6, 2, 1, 3]], backend=Val(:latex))
    end

    # -------------------------------------------------------------------------
    # draw graphically the results

    # Time elapsed for instances solved to the optimum by the two formulations
    figure("0. Comparison between formulations M and G", figsize=(12, 7.5))
    title("Elapsed time collected")
    xticks(rotation=60, ha="right")
    tick_params(labelsize=6, axis="x")
    xlabel("Name of datafiles")
    ylabel("Elapsed time (seconds)")
    plot(dfM[!, :fname], dfM[!, :tElapsed], linewidth=1, marker="o", markersize=5, color="r", label="formulation M")
    plot(dfG[!, :fname], dfG[!, :tElapsed], linewidth=1, marker="s", markersize=5, color="b", label="formulation G")
    legend(loc=2, fontsize="small")
    grid(color="gray", linestyle=":", linewidth=0.5)
    savefig("resultsMGtime.png")

    
    # Optimal value (when solved) for the aggregated objective function
    figure("1. Comparison between formulations M and G", figsize=(12, 7.5))
    title("Optimal value of objective functions collected")
    xticks(rotation=60, ha="right")
    tick_params(labelsize=6, axis="x")
    xlabel("Name of datafiles")
    ylabel("Optimal value of objective functions")
    plot(dfM[!, :fname], dfM[!, :zOpt], linewidth=1, marker="o", markersize=5, color="r", label="formulation M")
    plot(dfG[!, :fname], dfG[!, :zOpt], linewidth=1, marker="s", markersize=5, color="b", label="formulation G")
    legend(loc=2, fontsize="small")
    grid(color="gray", linestyle=":", linewidth=0.5)
    savefig("resultsMGobjFct.png")


    # Optimal number of transfets between docks (when solved)
    figure("2. Comparison between formulations M and G", figsize=(12, 7.5))
    title("Number of transfers collected")
    xticks(rotation=60, ha="right")
    tick_params(labelsize=6, axis="x")
    xlabel("Name of datafiles")
    ylabel("Number of transfers")
    plot(dfM[!, :fname], dfM[!, :nTransfertDone], linewidth=1, marker="o", markersize=5, color="r", label="formulation M")
    plot(dfG[!, :fname], dfG[!, :nTransfertDone], linewidth=1, marker="s", markersize=5, color="b", label="formulation G")
    legend(loc=2, fontsize="small")
    grid(color="gray", linestyle=":", linewidth=0.5)
    savefig("resultsMGnbrTft.png")


    # Positive difference in number of transferts for instances solved to the optimum by the two formulations
    x_values = (String)[]
    y_values = (Int64)[]
    facecolors = (String)[]
    winner = (String)[]
    x_file = copy(dfM[!, :fname])
    y_M = copy(dfM[!, :nTransfertDone])
    y_G = copy(dfG[!, :nTransfertDone])
    for i in 1:length(y_M)
        if y_M[i] != -1 && y_G[i] != -1
            push!(x_values, x_file[i])
            if y_G[i] > y_M[i]
                println(">")
                push!(y_values, y_G[i] - y_M[i])
                push!(facecolors, "blue")
                push!(winner, "G")
            elseif y_G[i] < y_M[i]
                push!(y_values, y_M[i] - y_G[i])
                push!(facecolors, "red")
                push!(winner, "M")
            else
                push!(y_values, 0)
                push!(facecolors, "black")
                push!(winner, "=")
            end
        end
    end
    edgecolors = facecolors
    figure("3. Comparison between formulations M and G", figsize=(12, 7.5))
    title("Positive difference of number of transfers collected")
    xticks(1:length(x_values), x_values, rotation=60, ha="right")
    tick_params(labelsize=6, axis="x")
    xlabel("Name of datafiles")
    ylabel("Positive difference of number of transfers")
    yticks(0:maximum(y_values))
    ylim(-1, 5)
    bar(x_values, y_values, color=facecolors, edgecolor=edgecolors, alpha=0.5)
    for i = 1:length(x_values)
        text(i, y_values[i] + 0.075, winner[i], ha="center")
    end
    savefig("resultsMGdifference.png")


    # comparison M and 2M
    x_values = (String)[]
    y_values = (Int64)[]
    facecolors = (String)[]
    winner = (String)[]
    x_file = copy(dfM[!, :fname])
    y_M = copy(dfM[!, :totalTimeTransfert])
    y_2M = copy(df2M[!, :z1TransfertTime])
    for i in 1:length(y_M)
        if y_M[i] != -1 && y_2M[i] != -1
            push!(x_values, x_file[i])
            if y_2M[i] > y_M[i]
                push!(y_values, y_M[i] - y_2M[i])
                push!(facecolors, "red")
                push!(winner, "M")
            elseif y_2M[i] < y_M[i]
                push!(y_values, y_2M[i] - y_M[i])
                push!(facecolors, "red")
                push!(winner, "2M")
            else
                push!(y_values, 0)
                push!(facecolors, "red")
                push!(winner, "=")
            end
        end
    end
    edgecolors = facecolors
    figure("4. Comparison between formulations M and 2M", figsize=(12, 7.5))
    title("Positive difference of total time transfert")
    xticks(1:length(x_values), x_values, rotation=60, ha="right")
    tick_params(labelsize=6, axis="x")
    xlabel("Name of datafiles")
    ylabel("Positive difference of total time transfert")
    yticks(minimum(y_values):0)
    ylim(minimum(y_values)-1, 1)
    bar(x_values, y_values, color=facecolors, edgecolor=edgecolors, alpha=0.5)
    for i = 1:length(x_values)
        text(i, 0 + 0.075, winner[i], ha="center")
    end
    savefig("resultsM2Mdifference.png")


    # comparison G and 2G
    x_values = (String)[]
    y_values = (Int64)[]
    facecolors = (String)[]
    winner = (String)[]
    x_file = copy(dfG[!, :fname])
    y_G = copy(dfG[!, :totalTimeTransfert])
    y_2G = copy(df2G[!, :z1TransfertTime])
    for i in 1:length(y_M)
        if y_G[i] != -1 && y_2G[i] != -1
            push!(x_values, x_file[i])
            if y_2G[i] > y_G[i]
                push!(y_values, y_G[i] - y_2G[i])
                push!(facecolors, "blue")
                push!(winner, "G")
            elseif y_2G[i] < y_G[i]
                push!(y_values, y_2G[i] - y_G[i])
                push!(facecolors, "blue")
                push!(winner, "2G")
            else
                push!(y_values, 0)
                push!(facecolors, "blue")
                push!(winner, "=")
            end
        end
    end
    edgecolors = facecolors
    figure("5. Comparison between formulations G and 2G", figsize=(12, 7.5))
    title("Positive difference of total time transfert")
    xticks(1:length(x_values), x_values, rotation=60, ha="right")
    tick_params(labelsize=6, axis="x")
    xlabel("Name of datafiles")
    ylabel("Positive difference of total time transfert")
    yticks(minimum(y_values):0)
    ylim(minimum(y_values)-1, 1)
    bar(x_values, y_values, color=facecolors, edgecolor=edgecolors, alpha=0.5)
    for i = 1:length(x_values)
        text(i, 0 + 0.075, winner[i], ha="center")
    end    
    savefig("resultsG2Gdifference.png")


    # comparison if exists a dominance between 2M and M + 2G and G
    x_values = (String)[]
    y_values = (Int64)[]
    x_file = copy(dfG[!, :fname])

    y_Mz1 = copy(dfM[!, :totalTimeTransfert])
    y_Mz2 = copy(dfM[!, :totalQuantityTransfered])

    y_Gz1 = copy(dfG[!, :totalTimeTransfert])
    y_Gz2 = copy(dfG[!, :totalQuantityTransfered])

    y_2Mz1 = copy(df2M[!, :z1TransfertTime])
    y_2Mz2 = copy(df2M[!, :z2QuantityTransfered])

    y_2Gz1 = copy(df2G[!, :z1TransfertTime])
    y_2Gz2 = copy(df2G[!, :z2QuantityTransfered])

    global countDominance = 0
    open("dominance.txt", "w") do f
        for i in 1:length(x_file)
            if y_Mz1[i] != -1 && y_2Mz1[i] != -1
                if y_2Mz1[i] < y_Mz1[i] && y_2Mz2[i] > y_Mz2[i]
                    println(f, x_file[i],"  dominance 2M ⟶ ($(y_2Mz1[i]) ; $(y_2Mz2[i])) M:($(y_Mz1[i]) ; $(y_Mz2[i]))" )
                    global countDominance+=1
                end
            end

            if y_Gz1[i] != -1 && y_2Gz1[i] != -1
                if y_2Gz1[i] < y_Gz1[i] && y_2Gz2[i] > y_Gz2[i]
                    println(f, x_file[i],"  dominance 2G ⟶ ($(y_2Gz1[i]) ; $(y_2Gz2[i])) G:($(y_Gz1[i]) ; $(y_Gz2[i]))" )
                    global countDominance+=1
                end
            end
        end
        println(f, "\n Number of dominance: $countDominance")
    end

end
