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

    return instance  # Pour réutilisation
end

# Fonction principale
function main()
    path = "../data/singleObjective/singleObjectiveGelareh2016/"
    instance_name = "data_10_3_0"
    
    # Charger et afficher l’instance
    instance = load_and_show_instance(path, instance_name)

    # Générer une solution initiale (assignation nulle)
    solution = SolutionModule.init_solution(instance)
    solution = SolutionModule.local_search(instance, solution, 1)
    println("\nSolution générée:")
    println("Affectation: ", solution.assignment)
    println("Coût total: ", solution.cost)
end

# Lancer le programme
main()
