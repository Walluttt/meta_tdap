
# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
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


# -----------------------------------------------------------------------------
# set the filenames 

function setfnameTest()

    finstances = [  "compile",
                    "data_10_3_0",
                    "data_10_3_1",
                    "data_10_3_2"#,
                    #"data_12_4_0"
                ]
    return finstances
end

function setfname()

    finstances = [  "compile",
                    "data_10_3_0",
                    "data_10_3_1",
                    "data_10_3_2",
                    "data_10_3_3",
                    "data_10_3_4",
                    "data_12_4_0",
                    "data_12_4_1",
                    "data_12_4_2",
                    "data_12_4_3",
                    "data_12_4_4",
                    "data_12_6_0",
                    "data_12_6_1",
                    "data_12_6_2",
                    "data_12_6_3",
                    "data_12_6_4",
                    "data_14_4_0",
                    "data_14_4_1",
                    "data_14_4_2",
                    "data_14_4_3",
                    "data_14_4_4",
                    "data_14_6_0",
                    "data_14_6_1",
                    "data_14_6_2",
                    "data_14_6_3",
                    "data_14_6_4",
                    "data_16_4_0",
                    "data_16_4_1",
                    "data_16_4_2",
                    "data_16_4_3",
                    "data_16_4_4",
                    "data_16_6_0",
                    "data_16_6_1",
                    "data_16_6_2",
                    "data_16_6_3",
                    "data_16_6_4",
                    "data_18_4_0",
                    "data_18_4_1",
                    "data_18_4_2",
                    "data_18_4_3",
                    "data_18_4_4",
                    "data_18_6_0",
                    "data_18_6_1",
                    "data_18_6_2",
                    "data_18_6_3",
                    "data_18_6_4",
                    "data_20_6_0",
                    "data_20_6_1",
                    "data_20_6_2",
                    "data_20_6_3",
                    "data_20_6_4",
                    "data_20_8_0",
                    "data_20_8_1",
                    "data_20_8_2",
                    "data_20_8_3",
                    "data_20_8_4",
                    "data_25_6_0",
                    "data_25_6_1",
                    "data_25_6_2",
                    "data_25_6_3",
                    "data_25_6_4",
                    "data_25_8_0",
                    "data_25_8_1",
                    "data_25_8_2",
                    "data_25_8_3",
                    "data_25_8_4",
                    "data_30_6_0",
                    "data_30_6_1",
                    "data_30_6_2",
                    "data_30_6_3",
                    "data_30_6_4",
                    "data_30_8_0",
                    "data_30_8_1",
                    "data_30_8_2",
                    "data_30_8_3",
                    "data_30_8_4"
                ]
    return finstances
end