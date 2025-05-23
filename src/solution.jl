module SolutionModule

export Sol, init_solution, calculate_cost, local_search, isValidAssignment, update_capacity

mutable struct Sol
    assignment::Dict{Int, Int}  # truck => dock
    cost::Float64
    capacity::Dict{Int, Float64}  # t_r => capacité à ce moment
end

function init_solution(instance)
    assignment = Dict{Int, Int}()
    capacity = Dict{Int, Float64}()
    # Tous les autres camions restent non assignés (valeur 0)
    for truck in 1:instance.n
        assignment[truck] = 0
    end
    times = sort(union(instance.a, instance.d))
    for i in times
        capacity[i] = 0.0
    end
    # Obtenir les indices des camions triés par heure d’arrivée
    sorted_trucks = sortperm(instance.a)  # retourne les indices triés

    #Assignation des premiers camions par ordre d'heure d'arrivée, aux premiers docks
    for (dock, truck) in enumerate(sorted_trucks[1:instance.m])
            assignment[truck] = dock
            capacity = update_capacity(instance, capacity, truck, true)  # Initialiser la capacité du dock

    end

    #Assignation des autres camions par ordre d'heure d'arrivée, au premier dock pouvant les accepter
    for truck in sorted_trucks[instance.m+1:instance.n]
            assignment = tiafdm(instance, assignment, truck, capacity)
            capacity = update_capacity(instance, capacity, truck, true)  # Initialiser la capacité du dock
    end
    cost = calculate_cost(instance, assignment)
    return Sol(assignment, cost, capacity)
end

function calculate_cost(instance, assignment)
    total_cost = 0.0

    # Coût opérationnel
    for i in 1:instance.n, j in 1:instance.n
        if assignment[i] != 0 && assignment[j] != 0
            k = assignment[i]
            l = assignment[j]
            if(instance.d[j] >= instance.a[i] && instance.f[i, j] > 0)
                total_cost += instance.c[k, l] * instance.t[k, l]
            end
        end
    end

    # Coût de pénalité si un camion n’est pas bien assigné
    for i in 1:instance.n, j in 1:instance.n
        if instance.f[i, j] > 0
            if !(assignment[i] != 0 && assignment[j] != 0)
                total_cost += instance.p[i, j] * instance.f[i, j]
            end
        end
    end

    return total_cost
end

function local_search(instance, solution, op)
    best_solution = deepcopy(solution)
    println("assignement original : ", solution.assignment)
    println("cost original : ", solution.cost)
    if op == 1  # Dock Exchange Move (DEM)
        for i in 1:instance.m-1
            for j in i+1:instance.m
                # Générer un voisin via DEM
                new_assignment = dem(solution, i, j)
                if(time_constraint(instance, new_assignment))
                    new_cost = calculate_cost(instance, new_assignment)
                    new_solution = Sol(new_assignment, new_cost, solution.capacity)
                    # Vérifie si le voisin est meilleur
                    if new_solution.cost < best_solution.cost
                        best_solution = new_solution
                        return best_solution
                    end
                end
            end
        end
    end
    if op == 2 # Truck Exchange Move (TEM)
        for t1 in 1:instance.n-1
            for t2 in t1+1:instance.n
                if(instance.a[t1]>instance.d[t2] || instance.a[t2]>instance.d[t1])
                    new_assignment = tem(instance, solution.assignment, t1, t2, solution.capacity)
                    if(is_capacity_respected(new_capacity, instance.C) && time_constraint(instance, new_assignment))
                        new_cost = calculate_cost(instance, new_assignment)
                        new_solution = Sol(new_assignment, new_cost, solution.capacity)

                        # Vérifie si le voisin est meilleur
                        if new_solution.cost < best_solution.cost
                            best_solution = new_solution
                            return best_solution
                        end
                    end
                end
            end
        end
    end
    if op == 3 # (TIM)
        for t in 1:instance.n 
            for i in 1:instance.m
                new_assignment, new_capacity = tim(instance, solution, t, i)
                if(is_capacity_respected(new_capacity, instance.C) && time_constraint(instance, new_assignment))
                    new_cost = calculate_cost(instance, new_assignment)
                    new_solution = Sol(new_assignment, new_cost, new_capacity)

                    # Vérifie si le voisin est meilleur
                    if new_solution.cost < best_solution.cost
                        best_solution = new_solution
                        return best_solution
                    end
                end
            end
        end
    end
    if op == 4 # (TIAFDM)
        for t in 1:instance.n
            new_assignment = tiafdm(instance, solution.assignment, t, solution.capacity)
            if(new_assignment[t] != 0 && time_constraint(instance, new_assignment) && is_capacity_respected(new_capacity, instance.C))
                new_cost = calculate_cost(instance, new_assignment)
                new_capacity = update_capacity(instance, solution.capacity, new_assignment[t], true)
                if(is_capacity_respected(new_capacity, instance.C))
                    new_solution = Sol(new_assignment, new_cost, new_capacity)

                    # Vérifie si le voisin est meilleur
                    if new_solution.cost < best_solution.cost
                        best_solution = new_solution
                        return best_solution
                    end
                end

            end
        end
    end
    return best_solution
end

function dem(solution, i, j)
    new_assignment = deepcopy(solution.assignment)

    for (truck, dock) in pairs(new_assignment)
        if dock == i
            new_assignment[truck] = j
        elseif dock == j
            new_assignment[truck] = i
        end
    end

    return new_assignment

end

function tem(instance, assignment, t1, t2, capacity) #Faire une vérif pour savoir si 2 camions sont en conflits avant appel
    new_assignment = deepcopy(assignment)

    if isValidAssignment(instance, new_assignment, t1, new_assignment[t2]) && isValidAssignment(instance, new_assignment, t2, new_assignment[t1])
        tmp = new_assignment[t1]
        new_assignment[t1]=new_assignment[t2]
        new_assignment[t2]=tmp
    end

    return new_assignment
end

function tim(instance, solution, truck, i)
    new_assignment = deepcopy(solution.assignment)
    new_capacity = deepcopy(solution.capacity)
    assigned_trucks_at_i = [t for (t, dock) in new_assignment if dock == i]
    for t in assigned_trucks_at_i
        if instance.d[t] > instance.a[truck]
            new_capacity = update_capacity(instance, new_capacity, t, false)  # Retirer la contribution de t
            new_assignment[t]=0  # Conflit détecté, retour immédiat
        end
    end
    new_capacity = update_capacity(instance, new_capacity, truck, true)
    new_assignment[truck]=i
    return new_assignment, new_capacity
end

function tiafdm(instance, assignment, truck, capacity)
    i=1
    docked=false
    new_assignment = deepcopy(assignment)
    while(!docked && i<=instance.m)
        if isValidAssignment(instance, new_assignment, truck, i)
            new_assignment[truck]=i
            docked=true
        else
            i+=1
        end
    end

    if !docked
        new_assignment[truck] = 0  # Aucun quai trouvé
    end

    return new_assignment
end


function isValidAssignment(instance, assignment, truck, i)
    assigned_trucks_at_i = [t for (t, dock) in pairs(assignment) if dock == i]

    for t in assigned_trucks_at_i
        if instance.d[t] > instance.a[truck]
            return false  # Conflit détecté, retour immédiat
        end
    end
    return true  # Aucun conflit détecté
end

function update_capacity(instance, capacity, truck, add::Bool)
    a = instance.a[truck]
    d = instance.d[truck]

    # Temps pertinents à mettre à jour
    for t in keys(capacity)
        if a <= t <= d
            # Camions déjà présents à t (autres que `truck`)
            present_trucks = [j for j in 1:instance.n if j != truck && instance.a[j] <= t <= instance.d[j]]

            # Contribution du camion à la capacité à t :
            delta = 0.0
            for j in present_trucks
                delta += instance.f[truck, j]
            end

            # Mettre à jour la capacité en ajoutant ou retirant ce delta
            if add
                capacity[t] = get(capacity, t, 0.0) + delta
            else
                capacity[t] = get(capacity, t, 0.0) - delta
            end
        end
    end

    return capacity
end

function time_constraint(instance, assignment)
    n = instance.n
    m = instance.m
    for i in 1:n, j in 1:n
        if(instance.f[i,j]>0 && assignment[i] != 0 && assignment[j] != 0)
            if(instance.f[i, j] * (instance.d[j] - instance.a[i] - instance.t[assignment[i], assignment[j]]) < 0)
                return false
            end
        end
    end
    return true
end

function is_capacity_respected(new_capacity, capacity)
    for cap in values(new_capacity)
        if cap > capacity
            return false
        end
    end
    return true
end

function emptyDock(assignment, i) #Shaking move
    new_assignment = deepcopy(assignment)
    assigned_trucks_at_i = [t for (t, dock) in pairs(assignment) if dock == i]

    for t in assigned_trucks_at_i
        new_assignment[t]=0
    end

    return new_assignment
end


end # module