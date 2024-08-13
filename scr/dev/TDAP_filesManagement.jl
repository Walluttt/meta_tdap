
# =============================================================================
# Loading an instance of TDAP (format from Gelareh) 
#
# Each instance is composed of 2 files: 
# - the dock's data (*.cd) 
# - the truck's data (*.cf)

function loadTDAP_singleObjective(path::String, fname::String)

    # file 1: the dock data ---------------------------------------------------
    file = open(path*fname*".cd")

    readline(file)                    # line skipped
    readline(file)                    # line skipped
    m = parse.(Int, readline(file))   # the number of dock (m)
    readline(file)                    # line skipped
    C = parse.(Int, readline(file))   # the stockage capacity value (C, in number of pallets)
    readline(file)                    # line skipped

    t = Matrix{Int64}(undef, m, m)  # the operational times (t, in minutes)
    for i=1:m
        t[i,:] = Int.(parse.(Float64, split(readline(file))))
    end

    readline(file)                    # line skipped

    c = Matrix{Int64}(undef, m, m)    # the transportation cost (c, in €)
    for i=1:m
        c[i,:] = Int.(parse.(Float64, split(readline(file))))
    end

    # following lines are skipped until end of file (the dock id)

    close(file)


    # file 2: the truck data --------------------------------------------------
    file = open(path*fname*".cf")

    readline(file)                    # line skipped
    readline(file)                    # line skipped
    n = parse.(Int, readline(file))   # the number of trucks (n)
    readline(file)                    # line skipped

    a = Vector{Int64}(undef, n)       # the arrival (a) and departure (d) times (in minutes ∈ [00:00;23:59])
    d = Vector{Int64}(undef, n)
    for i=1:n
        line = split(readline(file))
        a[i] = parse(Int64, split(line[1], ":")[1]) * 60  +  parse(Int64, split(line[1], ":")[2])
        d[i] = parse(Int64, split(line[2], ":")[1]) * 60  +  parse(Int64, split(line[2], ":")[2])
    end

    readline(file)                    # line skipped
    for i=1:n
        readline(file)                # line skipped (the truck id)
    end
    readline(file)                    # line skipped
    readline(file)                    # line skipped    

    f = zeros(Int64, n, n)            # number of pallets (f), integer
    p = zeros(Int64, n, n)            # penality (p), integer (€)
    while ! eof(file)
        line = split(readline(file))

        ida = parse(Int, line[1]) + 1 # id truck arrival
        idd = parse(Int, line[2]) + 1 # id truck departure

        f[ida, idd] = parse(Int64, line[3])
        p[ida, idd] = Int(parse(Float64, line[4]))
    end

    close(file)

    return Instance(fname, n, m, a, d, t, f, c, p, C)
end


# =============================================================================
# collect the un-hidden filenames available in a given directory

function getfname(target)
    # target : string := chemin + nom du repertoire ou se trouve les instances

    # positionne le currentdirectory dans le repertoire cible
    cd(joinpath(pwd(),target))

    # retourne le repertoire courant
    #println("pwd = ", pwd())

    # recupere tous les fichiers se trouvant dans le repertoire indique
    allfiles = readdir()

    # vecteur booleen qui marque les noms de fichiers valides
    flag = trues(size(allfiles))

    k=1
    for f in allfiles
        # traite chaque fichier du repertoire
        if f[1] != '.'
            # pas un fichier cache => conserver
            #println("fname = ", f)
        else
            # fichier cache => supprimer
            flag[k] = false
        end
        k = k+1
    end

    # repositionne le chemin
    cd(joinpath(pwd(),".."))

    # extrait les noms valides et retourne le vecteur correspondant
    finstances = allfiles[flag]
    
    return finstances
end