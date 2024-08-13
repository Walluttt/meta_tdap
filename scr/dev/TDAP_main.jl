
using Printf 
using JuMP, GLPK

include("TDAP_datastructures.jl")
include("TDAP_filesManagement.jl")
include("TDAP_display.jl")
include("TDAP_processingInstance.jl")
include("TDAP_formulations.jl")


#path = "../../data/singleObjective/didactic/"
#file = "exemple"

path = "../../data/singleObjective/singleObjectiveGelareh2016/data_10_3/"
file = "data_10_3_0"

instance = loadTDAP_singleObjective(path, file)
displayInstance(instance)

δ, tr, atr, dtr = processingInstance(instance)
displayProcessing(δ, tr, atr, dtr)

IPsolver = GLPK.Optimizer
mod = formulation_M(instance, δ, atr, dtr, IPsolver)

t_formulationM = 0.0
start  = time()
optimize!(mod)
t_formulationM = time()-start

if termination_status(mod) == OPTIMAL

    println(" ")
    println("  Optimal solution found:")

    # -------------------------------------------------------------------------
    print("    ")
    println("CPUTime consumed: ", trunc(t_formulationM, digits=3), " sec\n")

   # -------------------------------------------------------------------------
    zOpt = objective_value(mod)
    print("    ")
    println("zOptimal: ", zOpt)

    n = instance.n
    m = instance.m
    global cost = 0.0
    for i=1:n, j=1:n, k=1:m, l=1:m
        global cost =  cost + instance.c[k,l] * instance.t[k,l] * value(mod[:z][i,j,k,l])
    end
    println("      -> operational cost...: ", cost)

    global penality = 0.0
    for i=1:n
        for j=1:n
            som = 0
            for k=1:m, l=1:m
                som = som + value(mod[:z][i,j,k,l])
            end
            global penality = penality + instance.p[i,j] * instance.f[i,j] * (1-som)
        end
    end
    println("      -> penalty cost.......: ", penality, "\n")

   # -------------------------------------------------------------------------
    print("    ")
    println("Assigment truck to dock:")
    for i=1:n, k=1:m
         if value.(mod[:y][i,k])==1
              println("      truck $i ⟶  dock $k | arrival: ", instance.a[i]," ⟶  departure: ", instance.d[i])
         end
    end

    print("\n    ")
    println("Transfert of pallets:")
    global delivery_done = 0
    for i=1:n, j=1:n
        if instance.f[i,j] > 0
            for k=1:m, l=1:m
                if value.(mod[:z][i,j,k,l])==1
                    println("      truck $i ⟶  truck $j  from  dock $k ⟶  dock $l")
                    global delivery_done += 1
                end
            end
        end
    end
    print("    ")
    println("Number of deliveries: ", delivery_done)    

else

    println("No optimal solution found")

end