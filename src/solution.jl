module SolutionModule

export Sol, init_solution, calculate_cost, local_search, isValidAssignment

mutable struct Sol
assignment::Dict{Int, Int}  # truck => dock
cost::Float64
capacity::Int
end

function init_solution(instance)
    assignment = Dict{Int, Int}()
    cap=0
    # Tous les autres camions restent non assignés (valeur 0)
    for truck in 1:instance.n
        assignment[truck] = 0
    end
    # Obtenir les indices des camions triés par heure d’arrivée
    sorted_trucks = sortperm(instance.a)  # retourne les indices triés

    #Assignation des premiers camions par ordre d'heure d'arrivée, aux premiers docks
    for (dock, truck) in enumerate(sorted_trucks[1:instance.m])
        assignment[truck] = dock
    end

    #Assignation des autres camions par ordre d'heure d'arrivée, au premier dock pouvant les accepter
    for truck in sorted_trucks[instance.m+1:instance.n]
            assignment = tiafdm(instance, assignment, truck)
            cost = calculate_cost(instance, assignment)
    end
    cost = calculate_cost(instance, assignment)
    return Sol(assignment, cost, 0)
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
    if op == 1  # Dock Exchange Move (DEM)
        for i in 1:instance.m-1
            for j in i+1:instance.m
                # Générer un voisin via DEM
                new_assignment = dem(instance, solution.assignment, i, j)
                new_cost = calculate_cost(instance, new_assignment)
                new_solution = Sol(new_assignment, new_cost, 0)

                # Vérifie si le voisin est meilleur
                if new_solution.cost < best_solution.cost
                    best_solution = new_solution
                    return best_solution
                end
            end
        end
    end
    if op == 2 # Truck Exchange Move (TEM)
        for t1 in 1:instance.n-1
            for t2 in t1+1:instance.n
                if(instance.a[t1]>instance.d[t2] || instance.a[t2]>instance.d[t1])
                    new_assignment = tem(instance, solution.assignment, t1, t2)
                    new_cost = calculate_cost(instance, new_assignment)
                    new_solution = Sol(new_assignment, new_cost, 0)

                    # Vérifie si le voisin est meilleur
                    if new_solution.cost < best_solution.cost
                        best_solution = new_solution
                        return best_solution
                    end
                end
            end
        end
    end
    if op == 3 # (TIM)
        for t in 1:instance.n 
            for i in 1:instance.m
                new_assignment = tim(instance, solution.assignment, t, i)
                new_cost = calculate_cost(instance, new_assignment)
                new_solution = Sol(new_assignment, new_cost, 0)

                # Vérifie si le voisin est meilleur
                if new_solution.cost < best_solution.cost
                    best_solution = new_solution
                    return best_solution
                end
            end
        end
    end
    if op == 4 # (TIAFDM)
        for t in 1:instance.n
            new_assignment = tiafdm(instance, solution.assignment, t)
            new_cost = calculate_cost(instance, new_assignment)
            new_solution = Sol(new_assignment, new_cost, 0)

            # Vérifie si le voisin est meilleur
            if new_solution.cost < best_solution.cost
                best_solution = new_solution
                return best_solution
            end
        end
    end
    return best_solution
end

function dem(instance, assignment, i, j)
    new_assignment = deepcopy(assignment)

    for (truck, dock) in new_assignment
        if dock == i
            new_assignment[truck] = j
        elseif dock == j
            new_assignment[truck] = i
        end
    end

    return new_assignment

end

function tem(instance, assignment, t1, t2) #Faire une vérif pour savoir si 2 camions sont en conflits avant appel
    new_assignment = deepcopy(assignment)

    if isValidAssignment(instance, new_assignment, t1, new_assignment[t2]) && isValidAssignment(instance, new_assignment, t2, new_assignment[t1])
        tmp = new_assignment[t1]
        new_assignment[t1]=new_assignment[t2]
        new_assignment[t2]=tmp
    end
    return new_assignment
end

function tim(instance, assignment, truck, i)
    new_assignment = deepcopy(assignment)
    assigned_trucks_at_i = [t for (t, dock) in new_assignment if dock == i]
    for t in assigned_trucks_at_i
        if instance.d[t] > instance.a[truck]
            new_assignment[t]=0  # Conflit détecté, retour immédiat
        end
    end
    new_assignment[truck]=i
    return new_assignment
end

function tiafdm(instance, assignment, truck)
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


function addTruck(instance, solution, truck, dock)
# On copie temporairement l'affectation
    temp_assignment = deepcopy(solution.assignment)
    temp_assignment[truck] = dock

    a = instance.a[truck]
    d = instance.d[truck]
    added_volume = 0
    removed_volume = 0

    for i in 1:instance.n
        if temp_assignment[i] != 0
            # Ajouts
            if instance.a[i] <= d
                for j in 1:instance.n
                    if temp_assignment[j] != 0 && instance.f[i, j] > 0
                        added_volume += instance.f[i, j]
                    end
                end
            end
            # Sorties
            if instance.d[i] <= a
                for j in 1:instance.n
                    if temp_assignment[j] != 0 && instance.f[j, i] > 0
                        removed_volume += instance.f[j, i]
                    end
                end
            end
        end
    end

    # Capacité potentielle après ajout
    current_load = instance.capacity + added_volume - removed_volume
    return current_load
end


function emptyDock(instance, assignment, i) #Shaking move
    new_assignment = deepcopy(assignment)
    assigned_trucks_at_i = [t for (t, dock) in pairs(assignment) if dock == i]

    for t in assigned_trucks_at_i
        new_assignment[t]=0
    end

    return new_assignment
end


end # module