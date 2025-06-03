include("TDAP_datastructures.jl")
include("TDAP_filesManagement.jl")
include("solution.jl")

using .Datastructures
using .SolutionModule

# Fonction pour charger et afficher les informations sur l'instance
function load_and_show_instance(path::String, instance_name::String)
    instance = loadTDAP_singleObjective(path, instance_name)
    
    println("Instance chargée: ", instance_name)
    println("Nombre de camions: ", instance.n)
    println("Nombre de quais: ", instance.m)
    println("Capacité des quais: ", instance.C)
    println("Coût de transport (c): \n", instance.c)
    println("Temps opérationnel (t): \n", instance.t)
    #println("\nValeurs de f[i, j] :")
    # for i in 1:instance.n
    #     for j in 1:instance.n
    #         println("f[$i, $j] = ", instance.f[i, j])
    #     end
    #end
    return instance  # Pour réutilisation
end

# Fonction principale
function main()
    # path = "../data/singleObjective/didactic/"
    # instance_name = "didactic"
    
    path = "../data/singleObjective/singleObjectiveGelareh2016/"
    instance_name = "data_18_6_0"
    
    # Charger et afficher l’instance
    instance = load_and_show_instance(path, instance_name)
    solution = nothing
    time = @elapsed begin
        solution = SolutionModule.init_solution(instance)
        println("assignement original : ", solution.assignment)
        println("cost original : ", solution.cost)
        #solution = SolutionModule.local_search(instance, solution, 1)
        #solution = SolutionModule.bvnd(instance, solution)
        #solution = SolutionModule.bvns(instance, solution, 500)
        solution = SolutionModule.gvns(instance, solution, 500, 2)
    end

    println("\nSolution générée:")
    println("\nHeure d'arrivée et de sortie de chaque camion (par ordre d'arrivée) :")
    for truck in sort(collect(keys(solution.assignment)), by = t -> instance.a[t])
        println("Camion $truck : arrivée = $(instance.a[truck]), sortie = $(instance.d[truck])")
    end
    println("Affectation :")
    for truck in sort(collect(keys(solution.assignment)), by = t -> instance.a[t])
        print("$truck => ", solution.assignment[truck], " ")
    end
    println("\nCoût total: ", solution.cost)
    for (t, cap) in sort(collect(solution.capacity))
        println("t = $t : capacité = $cap")
    end
    println("\nTemps d'exécution : $(round(time, digits=3)) s")

end

# Lancer le programme
main()
