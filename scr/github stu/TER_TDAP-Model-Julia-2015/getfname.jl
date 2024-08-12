# --------------------------------------------------------------------------- #
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