include("TDAP_datastructures.jl")
include("TDAP_filesManagement.jl")
include("solution.jl")

using .Datastructures
using .SolutionModule
using Plots
using DataFrames
import .Datastructures: Instance


# Structure pour stocker les résultats
struct BenchmarkResult
    instance_name::String
    algorithm::String
    cost::Float64
    time::Float64
    n_trucks::Int
    n_docks::Int
end


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
function quick_benchmark()
    instances_config = [
            ("../data/singleObjective/singleObjectiveGelareh2016/", "data_10_3_0"),
            ("../data/singleObjective/singleObjectiveGelareh2016/", "data_12_4_0"),
            ("../data/singleObjective/singleObjectiveGelareh2016/", "data_12_4_4"),
            ("../data/singleObjective/singleObjectiveGelareh2016/", "data_14_6_1"),
            ("../data/singleObjective/singleObjectiveGelareh2016/", "data_16_4_2"),
            ("../data/singleObjective/singleObjectiveGelareh2016/", "data_18_6_0"),
    ]
    
    algorithms = [
        ("SA", (instance, solution) -> SolutionModule.simulated_annealing(instance, solution, 1000, 0.95, 30))

    ]
    
    # Utiliser la même logique mais avec moins d'instances/algorithmes
    # [Code similaire à run_benchmark mais avec la config réduite]
end

# Fonction pour créer les graphiques
function create_benchmark_plots(results::Vector{BenchmarkResult})
    # Séparer les données par algorithme
    sa_results = filter(r -> r.algorithm == "SA", results)
    gvns_results = filter(r -> r.algorithm == "GVNS", results)
    
    # Graphique 1: Comparaison des coûts
    p1 = plot(title="Comparaison des Coûts par Instance", 
              xlabel="Instance", ylabel="Coût", 
              legend=:topright, size=(800, 600)
              )
    
    instance_names = [r.instance_name for r in sa_results]
    sa_costs = [r.cost for r in sa_results]
    gvns_costs = [r.cost for r in gvns_results]
    
    plot!(p1, instance_names, sa_costs, label="SA", alpha=0.7, color=:blue)
    plot!(p1, instance_names, gvns_costs, label="GVNS", alpha=0.7, color=:red)
    plot!(p1, xrotation=45)
    
    # Graphique 2: Comparaison des temps d'exécution
    p2 = plot(title="Temps d'Exécution par Instance", 
              xlabel="Instance", ylabel="Temps (s)", 
              legend=:topright, size=(800, 600))
    
    sa_times = [r.time for r in sa_results]
    gvns_times = [r.time for r in gvns_results]
    
    plot!(p2, instance_names, sa_times, label="SA", alpha=0.7, color=:blue)
    plot!(p2, instance_names, gvns_times, label="GVNS", alpha=0.7, color=:red)
    plot!(p2, xrotation=45)
    
    # Forcer les ticks Y sans notation scientifique
    y_min = min(minimum(sa_costs), minimum(gvns_costs))
    y_max = max(maximum(sa_costs), maximum(gvns_costs))
    y_ticks = range(y_min, y_max, length=6)
    plot!(p1, yticks=(y_ticks, [string(Int(round(tick))) for tick in y_ticks]))

    

    # Afficher les graphiques
    display(p1)
    display(p2)

    # Sauvegarder les graphiques
    savefig(p1, "cost_comparison.png")
    savefig(p2, "time_comparison.png")

    
    println("📈 Graphiques sauvegardés: cost_comparison.png, time_comparison.png")
end

# Fonction principale
function main()
    # path = "../data/singleObjective/didactic/"
    # instance_name = "didactic"
    
       path = "../data/singleObjective/singleObjectiveGelareh2016/"
    instances_config = [
        "data_10_3_0",
        "data_12_4_0",
        "data_12_4_4",
        "data_14_6_1",
        "data_16_4_2",
        "data_18_6_0",
        "data_20_6_0",
        "data_30_6_0",
        "data_30_8_0",
        "data_35_8_0",
        "data_40_8_0",
    ]
    results = BenchmarkResult[]

    for instance_name in instances_config
        println("📊 Instance: $instance_name")
        
        instance = load_and_show_instance(path, instance_name)
        init_solution = SolutionModule.init_solution(instance)
        solution = init_solution

        time_sa = @elapsed begin
            solution_sa = SolutionModule.simulated_annealing(instance, init_solution, 1000, 0.95, 50)
            #solution_sa = SolutionModule.bvns(instance, init_solution, 30)
        end
        push!(results, BenchmarkResult(
            instance_name, "SA", solution_sa.cost, time_sa, instance.n, instance.m
        ))
       
        println("Coût pour SA: ", solution.cost)
        println("Temps: $(round(time_sa, digits=3)) s")

        init_solution = SolutionModule.init_solution(instance)

        time_gvns = @elapsed begin
            solution_gvns = SolutionModule.gvns(instance, init_solution, 30, 2)
        end
        push!(results, BenchmarkResult(
            instance_name, "GVNS", solution_gvns.cost, time_gvns, instance.n, instance.m
        ))
        println("Coût pour GVNS: ", solution.cost)
        println("Temps: $(round(time_gvns, digits=3)) s")
    end
    create_benchmark_plots(results)
    return results

end

# Lancer le programme
main()
