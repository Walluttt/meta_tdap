# --------------------------------------------------------------------------- #
# Loading an instance of TDAP (format from Gelareh) 
# example : loadTDAP(".data/data_10_3/data_10_3_0")

struct instance
    n::Int64            # number of trucks
    m::Int64            # number of docks
    N::Vector{Int64}
    M::Vector{Int64}
    a::Vector{Float64}
    d::Vector{Float64}
    t::Matrix{Float64}
    f::Matrix{Float64}
    c::Matrix{Float64}
    p::Matrix{Float64}
    x::Matrix{Int64}
    C::Int64
end

function loadTDAP(fname)

    # load the dock data
    file=open(fname*".cd")
    readline(file)
    readline(file)

    # m number of dock
    m = parse.(Int, readline(file))
    readline(file)

    # C stockage capacity
    C = parse.(Int, readline(file))
    readline(file)

    # t operational time
    t=zeros(Float64, m, m)
    j = 0
    for i=1:m
        j=1
        for value in split(readline(file))
            t[i,j] = parse.(Float64, value)#*0.15 # Redetermine unit of t ???
            #if (t[i,j] == 0.60)
            #    t[i,j] = 1
            #end
            j = j+1
        end
    end
    readline(file)

    # c transport cost
    c=zeros(Float64, m, m)
    j=0
    for i=1:m
        j=1
        for value in split(readline(file))
            c[i,j] = parse.(Float64, value)
            j = j+1
        end
    end
    readline(file)

    # dock id
    dockID=zeros(Int, m)
    for i=1:m
        dockID[i]=parse(Int, split(readline(file))[2])
    end

    close(file)

    # load the truck data
    file=open(fname*".cf")
    readline(file)
    readline(file)

    # n number of trucks
    n = parse.(Int, readline(file))
    readline(file)

    # arrival and depart time
    a=zeros(Float64, n)
    d=zeros(Float64, n)
    for i=1:n
        line = split(readline(file))
        a[i] = parse(Float64, split(line[1], ":")[1]) + 0.01*parse(Float64, split(line[1], ":")[2])
        d[i] = parse(Float64, split(line[2], ":")[1]) + 0.01*parse(Float64, split(line[2], ":")[2])
    end
    readline(file)

    # truck id
    truckID=zeros(Int, n)
    for i=1:n
        truckID[i]=parse(Int,split(readline(file))[2])
    end
    readline(file)
    readline(file)

    # p penality and f number of pallets
    f=zeros(Float64, n, n)
    p=zeros(Float64, n, n)
    while ! eof(file)
        line = split(readline(file))
        ida = parse(Int, line[1])+1
        idd = parse(Int, line[2])+1

        f[ida, idd] = parse(Float64, line[3])
        p[ida, idd] = parse(Float64, line[4])
    end

    close(file)

    # Deterline value of x
    x=zeros(Int, n, n)
    for i=1:n
        for j=1:n
            if d[i] <= a[j]
                x[i,j] = 1
            end
        end
    end

    return instance(n,m,dockID,truckID,a,d,t,f,c,p,x,C)
end