    module SolutionModule

    export Sol, init_solution, calculate_cost, local_search

    mutable struct Sol
        assignment::Dict{Int, Int}  # truck => dock
        cost::Float64
    end

    function init_solution(instance)
        assignment = Dict{Int, Int}()

        # Tous les autres camions restent non assignés (valeur 0)
        for truck in 1:instance.n
            assignment[truck] = 0
        end
        cap = 0
        # Obtenir les indices des camions triés par heure d’arrivée
        sorted_trucks = sortperm(instance.a)  # retourne les indices triés

        #Assignation des premiers camions par ordre d'heure d'arrivée, aux premiers docks
        for (dock, truck) in enumerate(sorted_trucks[1:instance.m])
            assignment[truck] = dock
            cap += instance.f[truck]
        end

        #Assignation des autres camions par ordre d'heure d'arrivée, au premier dock pouvant les accepter
        for truck in sorted_trucks[instance.m+1:instance.n]
            docked = false
            i = 1
            while !docked && i <= instance.m
                ok = true
                assigned_trucks_at_i = [t for (t, dock) in assignment if dock == i]

                for t in assigned_trucks_at_i
                    if instance.d[t] > instance.a[truck]
                        ok = false
                        break  # on sort car un conflit a été trouvé
                    end
                end

                if ok
                    assignment[truck] = i
                    docked = true
                else
                    i += 1
                end
            end

            if !docked
                assignment[truck] = 0  # pas de quai trouvé
            end
        end
        cost = calculate_cost(instance, assignment)
        return Sol(assignment, cost)
    end
    
    function calculate_cost(instance, assignment)
        total_cost = 0.0

        # Coût opérationnel
        for i in 1:instance.n, j in 1:instance.n
            if assignment[i] != 0 && assignment[j] != 0
                k = assignment[i]
                l = assignment[j]
                if k > 0 && l > 0
                    total_cost += instance.c[k, l] * instance.t[k, l]
                end
            end
        end

        # Coût de pénalité si un camion n’est pas bien assigné
        for i in 1:instance.n, j in 1:instance.n
            if assignment[i] == 0 || assignment[j] == 0
                total_cost += instance.p[i, j] * instance.f[i, j]
            end
        end

        return total_cost
    end

    function local_search(instance, solution, op)
        improved=false
        best_solution = deepcopy(solution)
        if op == 1  # Dock Exchange Move (DEM)
            for i in 1:instance.m-1
                for j in i+1:instance.m
                    # Générer un voisin via DEM
                    new_assignment = dem(instance, solution.assignment, i, j)
                    new_cost = calculate_cost(instance, new_assignment)
                    new_solution = Sol(new_assignment, new_cost)

                    # Vérifie si le voisin est meilleur
                    if new_solution.cost < best_solution.cost
                        best_solution = new_solution
                    end
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

    function tem(assignment, t1, t2) #Faire une vérif pour savoir si 2 camions sont en conflits avant appel
        if isValidAssignment(assignment, instance, t1, assignment[t2]) && isValidAssignment(assignment, instance, t2, assignment[t1])
            tmp = assignment[t1]
            assignment[t1]=assignment[t2]
            assignment[t2]=tmp
        end
        return assignment
    end

    function tim(assignment, truck, i)
        assigned_trucks_at_i = [t for (t, dock) in assignment if dock == i]
        for t in assigned_trucks_at_i
            if instance.d[t] > instance.a[truck]
                assignment[t]=0  # Conflit détecté, retour immédiat
            end
        end
        assignment[truck]=i
        return assignment
    end

    function tiafdm(instance, assignment, truck)
        i=1
        docked=false
        while(!docked && i<=instance.m)
            if isValidAssignment(instance, truck, i)
                assignment[truck]=i
                docked=true
            else
                i+=1
            end
        end

        if !docked
            assignment[truck] = 0  # Aucun quai trouvé
        end

        return assignment
    end


    function isValidAssignment(instance, assignment, truck, i)
        assigned_trucks_at_i = [t for (t, dock) in assignment if dock == i]

        for t in assigned_trucks_at_i
            if instance.d[t] > instance.a[truck]
                return false  # Conflit détecté, retour immédiat
            end
        end

        return true  # Aucun conflit détecté
    end


    end # module