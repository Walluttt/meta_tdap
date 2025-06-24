module SolutionModule

export Sol, init_solution, calculate_cost, local_search, isValidAssignment, update_capacity, uvnd, bvnd, gvns, bvns, init_cost, tem, update_cost

mutable struct Sol
    assignment::Dict{Int, Int}  # truck => dock
    cost::Int
    capacity::Dict{Int, Float64}  # t_r => capacité à ce moment
end
function init_solution(instance)
    assignment = Dict{Int, Int}()
    capacity = Dict{Int, Float64}()
    
    # Initialisation : tous les camions non assignés (0)
    for truck in 1:instance.n
        assignment[truck] = 0
    end
    
    cost = init_cost(instance)  # Coût initial avec pénalités
    
    # Initialisation des capacités
    times = sort(union(instance.a, instance.d))
    for t in times
        capacity[t] = 0.0
    end

    # Assignation des premiers camions aux docks (1 à m)
    sorted_trucks = sortperm(instance.a)  # Tri par heure d'arrivée
    dock = 1
    for truck in sorted_trucks[1:min(instance.m, instance.n)]
        old_dock = assignment[truck]
        assignment[truck] = dock
        cost += update_cost(instance, assignment, truck, old_dock)
        dock += 1  # Passage au dock suivant
    end

    for truck in sorted_trucks[instance.m+1:end]
        new_assignment, new_cost = tiafdm(instance, assignment, truck, cost)
        assignment = new_assignment
        cost = new_cost
        # Mettez à jour la capacité après assignation
        capacity = update_capacity(instance, capacity, truck, true)
    end

    # Vérification finale avec `calculate_cost`
    println(abs(cost - calculate_cost(instance, assignment)))
    @assert abs(cost - calculate_cost(instance, assignment)) < 1e-6 "Écart détecté !"
    return Sol(assignment, cost, capacity)
end

function calculate_cost(instance, assignment)
    total_cost = 0
    n = instance.n

    # Pénalité pour tous les flux
    for i in 1:n, j in 1:n
        total_cost += instance.p[i, j] * instance.f[i, j]
    end

    # Coût opérationnel uniquement si flux > 0
    for i in 1:n, j in 1:n
        if assignment[i] != 0 && assignment[j] != 0  && (i!=j || (i==j && instance.f[i, j] > 0))
            k = assignment[i]
            l = assignment[j]
            total_cost += instance.c[k, l] * instance.t[k, l] - instance.p[i, j] * instance.f[i, j]
        end
    end
    return total_cost
end
#Fonction d'initialisation du coût qui va calculer toutes les pénalités
function init_cost(instance)
    cost = 0
    for i in 1:instance.n, j in 1:instance.n
        cost += instance.p[i, j] * instance.f[i, j]
    end
    return cost
end

#Fonction de mise à jour du coût suite à une (dés)affectation
function update_cost(instance, assignment, truck, old_dock)
    delta = 0
    n = instance.n
    new_dock = assignment[truck]

    for j in 1:n
         if j == truck
            # Coût pour soi-même (flux interne du camion)
            if instance.f[truck, truck] > 0
                if old_dock != 0
                    # Ancien: coût opérationnel, nouveau: pénalité
                    prev_cost = instance.c[old_dock, old_dock] * instance.t[old_dock, old_dock] - instance.p[truck, truck] * instance.f[truck, truck]
                else
                    # Ancien: pénalité
                    prev_cost = 0  # Déjà dans le coût de base
                end
                
                if new_dock != 0
                    # Nouveau: coût opérationnel
                    new_cost = instance.c[new_dock, new_dock] * instance.t[new_dock, new_dock] - instance.p[truck, truck] * instance.f[truck, truck]
                else
                    # Nouveau: pénalité
                    new_cost = 0  # Déjà dans le coût de base
                end
                
                delta += new_cost - prev_cost
            end
        else
            old_j_dock = assignment[j]

            # Coût précédent entre truck et j
            if old_dock != 0 && old_j_dock != 0
                prev_cost_ij = instance.c[old_dock, old_j_dock] * instance.t[old_dock, old_j_dock]
            else
                prev_cost_ij = instance.p[truck, j] * instance.f[truck, j]
            end

            # Nouveau coût entre truck et j
            if new_dock != 0 && old_j_dock != 0
                new_cost_ij = instance.c[new_dock, old_j_dock] * instance.t[new_dock, old_j_dock]
            else
                new_cost_ij = instance.p[truck, j] * instance.f[truck, j]
            end

            delta += new_cost_ij - prev_cost_ij

            # Coût inverse entre j et truck
            if old_j_dock != 0 && old_dock != 0
                prev_cost_ji = instance.c[old_j_dock, old_dock] * instance.t[old_j_dock, old_dock]
            else
                prev_cost_ji = instance.p[j, truck] * instance.f[j, truck]
            end

            if old_j_dock != 0 && new_dock != 0
                new_cost_ji = instance.c[old_j_dock, new_dock] * instance.t[old_j_dock, new_dock]
            else
                new_cost_ji = instance.p[j, truck] * instance.f[j, truck]
            end

            delta += new_cost_ji - prev_cost_ji
        end
    end

    return delta
end
function update_capacity(instance, capacity, truck, add::Bool)
    a = instance.a[truck]
    d = instance.d[truck]

    # Parcourir uniquement les périodes antérieures à d (départ du camion)
    for t in filter(x -> a <= x < d, keys(capacity))
        # Camions déjà présents à t (autres que `truck`)
        present_trucks = [j for j in 1:instance.n if j != truck && (instance.a[j] <= t || t <= instance.d[j])]
        
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

    return capacity
end

function local_search(instance, solution, op)
    best_solution = deepcopy(solution)
    if op == 1 # (TIM)
        for t in 1:instance.n 
            for i in 1:instance.m
                new_assignment, new_capacity, new_cost = tim(instance, solution, t, i)
                if(is_capacity_respected(new_capacity, instance.C) && time_constraint(instance, new_assignment))
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
    if op == 2 # Truck Exchange Move (TEM)
        for t1 in 1:instance.n-1
            for t2 in t1+1:instance.n
                if(instance.a[t1]>instance.d[t2] || instance.a[t2]>instance.d[t1])
                    new_assignment, new_cost = tem(instance, solution.assignment, t1, t2, solution.capacity)
                    if(time_constraint(instance, new_assignment))
                        new_cost += solution.cost
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
    if op == 3  # Dock Exchange Move (DEM)
        for i in 1:instance.m-1
            for j in i+1:instance.m
            # Générer un voisin via DEM
                new_assignment, new_cost = dem(instance, solution, i, j)
                new_solution = Sol(new_assignment, new_cost+solution.cost, solution.capacity)
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
            new_assignment, new_cost = tiafdm(instance, solution.assignment, t, solution.cost)
            if(new_assignment[t] != 0 && time_constraint(instance, new_assignment))
                new_capacity = update_capacity(instance, solution.capacity, t, true)
                if(is_capacity_respected(new_capacity, instance.C))
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

function local_searchBI(instance, solution, op)
    best_solution = deepcopy(solution)
    best_improvement = 0  # Suivre la meilleure amélioration trouvée
    
    if op == 1 # (TIM)
        for t in 1:instance.n 
            for i in 1:instance.m
                # Éviter de tester la même affectation
                if solution.assignment[t] == i
                    continue
                end
                
                new_assignment, new_capacity, new_cost = tim(instance, solution, t, i)
                if is_capacity_respected(new_capacity, instance.C) && time_constraint(instance, new_assignment)
                    new_solution = Sol(new_assignment, new_cost, new_capacity)
                    
                    # Calculer l'amélioration
                    improvement = solution.cost - new_solution.cost
                    
                    # Garder seulement si c'est la meilleure amélioration
                    if improvement > best_improvement
                        best_solution = new_solution
                        best_improvement = improvement
                    end
                end
            end
        end
    end
    
    if op == 2 # Truck Exchange Move (TEM)
        for t1 in 1:instance.n-1
            for t2 in t1+1:instance.n
                # Éviter les échanges inutiles (même dock)
                if solution.assignment[t1] == solution.assignment[t2]
                    continue
                end
                
                if instance.a[t1] > instance.d[t2] || instance.a[t2] > instance.d[t1]
                    new_assignment, delta_cost = tem(instance, solution.assignment, t1, t2, solution.capacity)
                    
                    if time_constraint(instance, new_assignment)
                        new_cost = solution.cost + delta_cost
                        new_solution = Sol(new_assignment, new_cost, solution.capacity)
                        
                        # Calculer l'amélioration
                        improvement = solution.cost - new_solution.cost
                        
                        if improvement > best_improvement
                            best_solution = new_solution
                            best_improvement = improvement
                        end
                    end
                end
            end
        end
    end
    
    if op == 3  # Dock Exchange Move (DEM)
        for i in 1:instance.m-1
            for j in i+1:instance.m
                new_assignment, delta_cost = dem(instance, solution, i, j)
                new_cost = solution.cost + delta_cost
                new_solution = Sol(new_assignment, new_cost, solution.capacity)
                
                # Calculer l'amélioration
                improvement = solution.cost - new_solution.cost
                
                if improvement > best_improvement
                    best_solution = new_solution
                    best_improvement = improvement
                end
            end
        end
    end
    
    if op == 4 # (TIAFDM)
        for t in 1:instance.n
            # Éviter de tester si déjà assigné au meilleur dock possible
            if solution.assignment[t] != 0
                continue
            end
            
            new_assignment, new_cost = tiafdm(instance, solution.assignment, t, solution.cost)
            
            if new_assignment[t] != 0 && time_constraint(instance, new_assignment)
                new_capacity = update_capacity(instance, solution.capacity, t, true)
                
                if is_capacity_respected(new_capacity, instance.C)
                    new_solution = Sol(new_assignment, new_cost, new_capacity)
                    
                    # Calculer l'amélioration
                    improvement = solution.cost - new_solution.cost
                    
                    if improvement > best_improvement
                        best_solution = new_solution
                        best_improvement = improvement
                    end
                end
            end
        end
    end
    
    return best_solution
end
function dem(instance, solution, i, j)
    new_assignment = deepcopy(solution.assignment)
    new_cost = solution.cost
    for truck in 1:instance.n
        dock = new_assignment[truck]
        if dock == i
            new_assignment[truck] = 0
            new_cost += update_cost(instance, new_assignment, truck, i)
            new_assignment[truck] = j
            new_cost += update_cost(instance, new_assignment, truck, 0)  
        elseif dock == j
            new_assignment[truck] = 0
            new_cost += update_cost(instance, new_assignment, truck, j)
            new_assignment[truck] = i
            new_cost += update_cost(instance, new_assignment, truck, 0)  
        end
    end
    return new_assignment, new_cost

end

function tem(instance, assignment, t1, t2, capacity) #Faire une vérif pour savoir si 2 camions sont en conflits avant appel
    new_assignment = deepcopy(assignment)

    old_dock_t1=new_assignment[t1]
    old_dock_t2=new_assignment[t2]
    new_cost = 0
    new_assignment[t1] = 0
    new_cost += update_cost(instance, new_assignment, t1, old_dock_t1)


    new_assignment[t2] = 0
    new_cost += update_cost(instance, new_assignment, t2, old_dock_t2)

    
    if isValidAssignment(instance, new_assignment, t1, old_dock_t2) && isValidAssignment(instance, new_assignment, t2, old_dock_t1)
        
        new_assignment[t1]=old_dock_t2
        new_cost += update_cost(instance, new_assignment, t1, 0)
        new_assignment[t2]=old_dock_t1
        new_cost += update_cost(instance, new_assignment, t2, 0) 
        
        return new_assignment, new_cost
    end

    return assignment, 0
end

function tim(instance, solution, truck, i)
    new_assignment = deepcopy(solution.assignment)
    new_capacity = deepcopy(solution.capacity)
    new_cost = solution.cost
    assigned_trucks_at_i = [t for (t, dock) in new_assignment if dock == i]
    for t in assigned_trucks_at_i
        if max(instance.a[truck], instance.a[t]) < min(instance.d[truck], instance.d[t])
            new_capacity = update_capacity(instance, new_capacity, t, false)  # Retirer la contribution de t
            old_dock = new_assignment[t]
            new_assignment[t] = 0  # Conflit détecté, retour immédiat
            new_cost += update_cost(instance, new_assignment, t, old_dock)  # Mettre à jour le coût de l'affectation
        end
    end
    new_capacity = update_capacity(instance, new_capacity, truck, true)
    old_dock = new_assignment[truck]
    new_assignment[truck]=i
    new_cost += update_cost(instance, new_assignment, truck, old_dock)  # Mettre à jour le coût de l'affectation
    return new_assignment, new_capacity, new_cost
end

function tiafdm(instance, assignment, truck, cost)
    i=1
    docked=false
    old_dock = assignment[truck]
    new_assignment = deepcopy(assignment)
    while(!docked && i<=instance.m)
        if isValidAssignment(instance, new_assignment, truck, i)
            new_assignment[truck]=i
            docked=true
        else
            i+=1
        end
    end
    new_cost = cost
    if !docked
        new_assignment[truck] = old_dock  # Aucun quai trouvé
    else
        new_cost += update_cost(instance, new_assignment, truck, old_dock)  # Mettre à jour le coût de l'affectation
    end

    return new_assignment, new_cost
end


function isValidAssignment(instance, assignment, truck, i)
    assigned_trucks_at_i = [t for (t, dock) in pairs(assignment) if dock == i]

    for t in assigned_trucks_at_i
        if instance.d[t] > instance.a[truck] && instance.d[truck] > instance.a[t]
            return false  # Conflit détecté, retour immédiat
        end
    end
    return true  # Aucun conflit détecté
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


function uvnd(instance, solution)

    best_solution = local_search(instance, solution, 1)

    tmp = local_search(instance, solution, 2)
    if tmp.cost < best_solution.cost
        best_solution = tmp
    end

    tmp = local_search(instance, solution, 3)
    if tmp.cost < best_solution.cost
        best_solution = tmp
    end

    tmp = local_search(instance, solution, 4)
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
    S = deepcopy(initial_solution)
    improved = false  # Commencer par true pour entrer dans la boucle

    # Simulation do-while : exécuter au moins une fois
    while true
        improved = false
        lambda = 1
        
        while lambda <= lambda_max
            S_prime = local_searchBI(instance, S, lambda)
            
            if S_prime.cost < S.cost
                S = S_prime
                improved = true
                lambda = 1  # Retour au premier voisinage
            else
                lambda += 1
            end
        end
        
        # Condition de sortie (équivalent à while improved)
        if !improved
            break
        end
    end
    return S
end

function bvns(instance, initial_solution, nmax)
    k_max = 3  # nombre d'opérateurs de voisinage
    S = deepcopy(initial_solution)
    nbIterationsWithoutImprovement = 0

    while nbIterationsWithoutImprovement < nmax
        k = 1
        while k <= k_max
            # --- Shaking step avec acceptation conditionnelle ---
            S_shaken = generate_shaken(instance, S, k)
            S_shaken, cost = repair_solution(instance, S_shaken, k)  # Réparer la solution si nécessaire
            S_shaken.cost = cost  # Mettre à jour le coût après réparation

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
    cost=0
    while nbIterNoImprovement < nmax
        k = 1
        while k ≤ k_max
            #--- Shaking step (avec validation) ---
            S_shaken = generate_shaken(instance, S, k)
            #println("cout shaking:", cost)

            S_shaken, cost = repair_solution(instance, S_shaken, k)  # Réparer la solution si nécessaire
            S_shaken.cost = cost  # Mettre à jour le coût après réparation
            # println("cout réparé:", cost)
            # @assert abs(cost - calculate_cost(instance, S_shaken.assignment)) < 1e-6 "Écart détecté !"

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

function ils(instance, initial_solution, nmax)
    k_max = 4  # nombre d'opérateurs de shaking
    S = deepcopy(initial_solution)
    S = uvnd(instance, S)  # Amélioration initiale
    nbIterNoImprovement = 0

    while nbIterNoImprovement < nmax
        k = 1
        while k <= k_max
            # --- Shaking step (avec validation) ---
            S_shaken = generate_shaken(instance, S, k)
            S_shaken, cost = repair_solution(instance, S_shaken, k)  # Réparer la solution si nécessaire
            S_shaken.cost = cost  # Mettre à jour le coût après réparation
            # println("cout réparé:", cost)
            # @assert abs(cost - calculate_cost(instance, S_shaken.assignment)) < 1e-6 "Écart détecté !"

            # --- Improvement procedure: VND ---
            S_improved = bvnd(instance, S_shaken)
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


function simulated_annealing(instance, initial_solution, T0, alpha, n_iter)
    S = deepcopy(initial_solution)
    best = deepcopy(S)
    T = T0
    for i in 1:n_iter
        # Générer un voisin aléatoire en utilisant generate_shaken et repair_solution
        op = rand(1:3)  # Vous pouvez ajuster l'intervalle selon vos opérateurs disponibiles
        S_shaken = generate_shaken(instance, S, op)
        S_shaken, cost = repair_solution(instance, S_shaken, op)
        S_shaken.cost = cost  # Mettre à jour le coût après réparation

        # Amélioration locale pour raffiner le voisin
        S_shaken = bvnd(instance, S_shaken)
        
        delta = S_shaken.cost - S.cost
        # Accepter le nouveau voisin s'il est meilleur ou avec une probabilité exp(-Δ/T)
        if delta < 0 || rand() < exp(-delta / T)
            S = S_shaken
            if S.cost < best.cost
                best = deepcopy(S)
            end
        end
        
        # Descente de température
        T *= alpha
    end
    return best
end

function generate_shaken(instance, S, k; max_attempts=10)
    attempt = 0
    valid = false
    new_cost = 0
    S_shaken = deepcopy(S)
    while attempt < max_attempts && !valid
        S_shaken = deepcopy(S)
        if k == 1
            # TIM : réaffectation aléatoire d'un camion à un quai
            t = rand(1:instance.n)
            dock = rand(1:instance.m)
            shaken_assignment, shaken_capacity, new_cost = tim(instance, S, t, dock)
            S_shaken.cost = new_cost
            S_shaken.assignment = shaken_assignment
            S_shaken.capacity = shaken_capacity
        elseif k == 2
            # TEM : échange aléatoire de deux camions
            t1, t2 = rand(1:instance.n, 2)
            S_shaken.assignment, new_cost = tem(instance, S.assignment, t1, t2, S.capacity)
            S_shaken.cost += new_cost
            # Pour TEM, la capacité reste inchangée par rapport à S.capacity
        elseif k == 3
            # DEM : échange aléatoire de deux quais
            i, j = rand(1:instance.m, 2)
            S_shaken.assignment, new_cost = dem(instance, S, i, j)
            S_shaken.cost = new_cost
            # Pour DEM, nous gardons la capacité initiale
        elseif k == 4
            # TIAFDM : affectation aléatoire d'un camion
            t = rand(1:instance.n)
            S_shaken.assignment, S_shaken.cost = tiafdm(instance, S.assignment, t, S.cost)
            S_shaken.capacity = update_capacity(instance, S_shaken.capacity, t, true)  # Mettre à jour la capacité après affectation
        end
        # Recalculer le coût après shaking
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

# Cette fonction tente de réparer une solution en cas de violation partielle
function repair_solution(instance, solution, movement_type)
    repaired = deepcopy(solution)
    old_dock = 0
    new_cost = solution.cost
    if(movement_type == 1 || movement_type == 2) # TIM ou TEM
        # 1. Réparer les violations de contrainte temporelle (3.8)
        # Pour chaque transfert prévu, vérifier si le délai est respecté.
        for i in 1:instance.n, j in 1:instance.n
            if instance.f[i,j] > 0 && repaired.assignment[i] != 0 && repaired.assignment[j] != 0
                # Si la contrainte n'est pas respectée
                if instance.d[j] - instance.a[i] - instance.t[repaired.assignment[i], repaired.assignment[j]] < 0
                    # On peut désassigne le camion j
                    old_dock = repaired.assignment[j]
                    repaired.assignment[j] = 0
                    new_cost += update_cost(instance, repaired.assignment, j, old_dock)  # Mettre à jour le coût de l'affectation
                    # Puis, recalculer la capacité après cette modification.
                    repaired.capacity = update_capacity(instance, repaired.capacity, j, false)
                end
            end
        end
    end
    if(movement_type == 1)
        # 2. Réparer les violations de capacité
        # Pour chaque instant critique t, contrôler si la capacité est dépassée.
        times = sort(union(instance.a, instance.d))
        for t in times
            cap_used = 0.0
            trucks_present = Int[]
            for i in 1:instance.n
                if repaired.assignment[i] != 0 && instance.a[i] <= t <= instance.d[i]
                    push!(trucks_present, i)
                    cap_used += sum(instance.f[i, j] for j in 1:instance.n)
                end
            end
            sorted_trucks = sort(trucks_present, by = t -> instance.a[t])
            while cap_used > instance.C && !isempty(sorted_trucks)
                truck_to_remove = sorted_trucks[1]
                old_dock = assignment[truck_to_remove]
                repaired.assignment[truck_to_remove] = 0
                new_cost += update_cost(instance, repaired.assignment, truck_to_remove, old_dock) 

                repaired.capacity = update_capacity(instance, repaired.capacity, truck_to_remove, false)
                # Recalculez la charge pour l'instant t
                cap_used = 0.0
                trucks_present = Int[]
                for i in 1:instance.n
                    if repaired.assignment[i] != 0 && instance.a[i] <= t <= instance.d[i]
                        push!(trucks_present, i)
                        cap_used += sum(instance.f[i, j] for j in 1:instance.n)
                    end
                end
                sorted_trucks = sort(trucks_present, by = t -> instance.a[t])
            end
        end
    end
    #new_cost=calculate_cost(instance, repaired.assignment)
    return repaired, new_cost
end

#Vérifie si l'instance est full mesh
function isFullMesh(instance)
    for j in 1:instance.n
        if instance.f[j, j] > 0
            return true
        end
    end
    return false
end

end # module