module SolutionModule

export Sol, init_solution, calculate_cost, local_search, isValidAssignment, update_capacity, uvnd, bvnd, gvns, bvns

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
    n = instance.n
    m = instance.m

    # Premier terme : coût opérationnel
    for k in 1:m, l in 1:m, i in 1:n, j in 1:n
        if assignment[i] == k && assignment[j] == l
            total_cost += instance.c[k, l] * instance.t[k, l]
        end
    end

    # Deuxième terme : pénalité
    for i in 1:n, j in 1:n
        if instance.f[i, j] > 0
            # Vérifie si (i, j) a été affecté à un couple (k, l)
            assigned = false
            for k in 1:m, l in 1:m
                if assignment[i] == k && assignment[j] == l
                    assigned = true
                    break
                end
            end
            if !assigned
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
            new_assignment = dem(solution, i, j)
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
    if op == 2 # Truck Exchange Move (TEM)
        for t1 in 1:instance.n-1
            for t2 in t1+1:instance.n
                if(instance.a[t1]>instance.d[t2] || instance.a[t2]>instance.d[t1])
                    new_assignment = tem(instance, solution.assignment, t1, t2, solution.capacity)
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
            if(new_assignment[t] != 0 && time_constraint(instance, new_assignment))
                new_capacity = update_capacity(instance, solution.capacity, t, true)
                if(is_capacity_respected(new_capacity, instance.C))
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
            if(instance.d[j] - instance.a[i] - instance.t[assignment[i], assignment[j]] < 0)
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


function uvnd(instance, solution)

    best_solution = local_search(instance, solution, 1)
    println("voisinage 1 cost : ", best_solution.cost)
    tmp = local_search(instance, solution, 2)
    println("voisinage 2 cost : ", tmp.cost)
    if tmp.cost < best_solution.cost
        best_solution = tmp
    end
    tmp = local_search(instance, solution, 3)
    println("voisinage 3 cost : ", tmp.cost)

    if tmp.cost < best_solution.cost
        best_solution = tmp
    end
    tmp = local_search(instance, solution, 4)
    println("voisinage 4 cost : ", tmp.cost)
    if tmp.cost < best_solution.cost
        best_solution = tmp
    end
    if(best_solution.cost < solution.cost)
        return best_solution
    end
    return best_solution
end

function vnd(instance, solution, op)
    if(op==1)
        return uvnd(instance, solution)
    else 
        return bvnd(instance, solution)
    end
end



function bvnd(instance, initial_solution)
    lambda_max = 4  # nombre d'opérateurs de voisinage
    Operators = 1:lambda_max
    S = deepcopy(initial_solution)
    improved = true

    while improved
        improved = false
        lambda = 1
        while lambda <= lambda_max
            # Générer un voisin avec l'opérateur lambda
            S_prime = local_search(instance, S, lambda)
            # Choix de la stratégie : First Improvement (FI) ou Best Improvement (BI)
            # FI : on prend le premier voisin améliorant (déjà fait dans local_search)
            if S_prime.cost < S.cost
                S = S_prime
                improved = true
                lambda = 1  # retour au premier voisinage
                continue
            end
            lambda += 1  # passer au voisinage suivant
        end
    end
    return S
end

function bvns(instance, initial_solution, nmax)
    k_max = 4  # nombre d'opérateurs de voisinage
    S = deepcopy(initial_solution)
    nbIterationsWithoutImprovement = 0

    while nbIterationsWithoutImprovement < nmax
        k = 1
        while k <= k_max
            # --- Shaking step dépendant de k ---
            S_shaken = deepcopy(S)
            if k == 1
                # DEM : échange aléatoire de deux quais
                i, j = rand(1:instance.m, 2)
                S_shaken.assignment = dem(S, i, j)
            elseif k == 2
                # TEM : échange aléatoire de deux camions
                t1, t2 = rand(1:instance.n, 2)
                S_shaken.assignment = tem(instance, S.assignment, t1, t2, S.capacity)
            elseif k == 3
                # TIM : réaffectation aléatoire d'un camion à un quai
                t = rand(1:instance.n)
                dock = rand(1:instance.m)
                shaken_assignment, shaken_capacity = tim(instance, S, t, dock)
                S_shaken.assignment = shaken_assignment
                S_shaken.capacity = shaken_capacity
            elseif k == 4
                # TIAFDM : affectation aléatoire d'un camion
                t = rand(1:instance.n)
                S_shaken.assignment = tiafdm(instance, S.assignment, t, S.capacity)
            end
            # Recalculer le coût après shaking
            S_shaken.cost = calculate_cost(instance, S_shaken.assignment)

            # --- Amélioration locale ---
            S_local = local_search(instance, S_shaken, k)

            # --- Séquential Neighborhood change step ---
            if S_local.cost < S.cost
                S = S_local
                k = 1
                nbIterationsWithoutImprovement = 0
            else
                k += 1
            end
        end
        nbIterationsWithoutImprovement += 1
    end
    return S
end

function gvns(instance, initial_solution, nmax, op_vnd)
    k_max = 4  # nombre d'opérateurs de shaking
    S = deepcopy(initial_solution)
    nbIterNoImprovement = 0

    while nbIterNoImprovement < nmax
        k = 1
        while k ≤ k_max
            # --- Shaking step (avec validation) ---
            S_shaken = generate_shaken(instance, S, k)
            # --- Improvement procedure: VND ---
            S_improved = vnd(instance, S_shaken, op_vnd)
            # --- Sequential Neighborhood Change Step ---
            if S_improved.cost < S.cost
                S = S_improved
                k = 1   # retour au premier opérateur de shaking
                nbIterNoImprovement = 0
            else
                k += 1  # passage à l'opérateur suivant dans le shaking
            end
        end
        nbIterNoImprovement += 1
    end
    return S
end

function generate_shaken(instance, S, k; max_attempts=10)
    attempt = 0
    valid = false
    S_shaken = deepcopy(S)
    while attempt < max_attempts && !valid
        S_shaken = deepcopy(S)
        if k == 1
            # DEM : échange aléatoire de deux quais
            i, j = rand(1:instance.m, 2)
            S_shaken.assignment = dem(S, i, j)
            # Pour DEM, nous gardons la capacité initiale
        elseif k == 2
            # TEM : échange aléatoire de deux camions
            t1, t2 = rand(1:instance.n, 2)
            S_shaken.assignment = tem(instance, S.assignment, t1, t2, S.capacity)
            # Pour TEM, la capacité reste inchangée par rapport à S.capacity
        elseif k == 3
            # TIM : réaffectation aléatoire d'un camion à un quai
            t = rand(1:instance.n)
            dock = rand(1:instance.m)
            shaken_assignment, shaken_capacity = tim(instance, S, t, dock)
            S_shaken.assignment = shaken_assignment
            S_shaken.capacity = shaken_capacity
        elseif k == 4
            # TIAFDM : affectation aléatoire d'un camion
            t = rand(1:instance.n)
            S_shaken.assignment = tiafdm(instance, S.assignment, t, S.capacity)
            # Ici, on suppose que S.capacity reste telle quelle.
        end
        # Recalculer le coût après shaking
        S_shaken.cost = calculate_cost(instance, S_shaken.assignment)
        # Vérifier la solution générée (contraintes temporelles, capacité, etc.)
        if time_constraint(instance, S_shaken.assignment) && is_capacity_respected(S_shaken.capacity, instance.C)
            valid = true
        else
            attempt += 1
        end
    end
    # En cas d'échec (aucune solution valide après max_attempts), on retourne S non modifiée
    if !valid
        S_shaken = deepcopy(S)
    end
    return S_shaken
end


end # module