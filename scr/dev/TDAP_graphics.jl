# =============================================================================
# TDAP
# =============================================================================


# -----------------------------------------------------------------------------
# Display the Gantt chart corresponding to the previsionnal planning of 
# trucks and transferts of pallets

function drawGanttInstance(instance::Instance)
    
    tOccupationQuai = instance.d - instance.a

    hmin = Int(floor(minimum(instance.a)/60))
    hmax = Int(ceil(maximum(instance.d)/60))
    hstr = []
    colors=[]
    for i in hmin:hmax
        push!(hstr, string(i)*":00")
        push!(colors,[rand(),rand(),rand()])
    end 
    xticks(collect(hmin:hmax), hstr)

    cm = get_cmap(:gist_rainbow)
    colorrange = (0:instance.n-1) ./ instance.n
   
    truckID = string.(collect(1:instance.n))

    title(instance.name * ": Previsional planning of trucks and transferts of pallets",fontsize=10)
    xlim([hmin-1,hmax+1])

    xlabel("time")
    ylabel("truck ID")

    barh(truckID, left=instance.a/60, width=tOccupationQuai/60, height=0.25, color=cm(colorrange)) #color=colors)
    gca().invert_yaxis()

    for i in 1:length(instance.a)
        sHHa, sMMa = string.(convertMinutesHHMM(instance.a[i]))
        sHHd, sMMd = string.(convertMinutesHHMM(instance.d[i]))

        length(sHHa)==1 ? sHHa = "0" * sHHa : nothing
        length(sMMa)==1 ? sMMa = "0" * sMMa : nothing
        length(sHHd)==1 ? sHHd = "0" * sHHd : nothing
        length(sMMd)==1 ? sMMd = "0" * sMMd : nothing

        text(instance.a[i]/60-0.18,i-1+0.35, fontsize=6, sHHa * ":" * sMMa)
        text(instance.d[i]/60-0.18,i-1+0.35, fontsize=6, sHHd * ":" * sMMd)
    end

    for i in 1:length(instance.a)
        xMilieuD = instance.a[i]/60 + (instance.d[i]/60 - instance.a[i]/60) / 2
        for j in 1:length(instance.a)    
            if instance.f[i,j] != 0
                xMilieuA = instance.a[j]/60 + (instance.d[j]/60 - instance.a[j]/60) / 2 + rand()*0.5 - 0.25
                annotate(".", xy=[xMilieuA;j-1], arrowprops=Dict("arrowstyle"=>"->"), xytext=[xMilieuD;i-1])
            end
        end
    end
    
    return nothing
end 


# -----------------------------------------------------------------------------
# Compute and draw the evolution of the load in the terminal in term of pallets

function drawLoadTerminal(formulationID, instance, tr, atr, dtr, mod, yLim_OnOff)

    n = instance.n
    m = instance.m

    for r=1:2*n
        println("    at the time marker r=$r:")
        sommeIN = 0
        for i in atr[r], j=1:n, k=1:m, l=1:m
            if value(mod[:z][i,j,k,l])==1 && instance.f[i,j] > 0
                sommeIN += instance.f[i,j]
                println("      i=$i j=$j k=$k l=$l :   entrance of.. ",instance.f[i,j]," pallets : [truck $i | dock $k] → [truck $j | dock $l]")
            end
        end
        sommeOUT = 0
        for i=1:n, j in dtr[r], k=1:m, l=1:m
            if value(mod[:z][i,j,k,l])==1 && instance.f[i,j] > 0
                sommeOUT += instance.f[i,j]
                println("      i=$i j=$j k=$k l=$l :   exit of ..... ",instance.f[i,j]," pallets : [truck $i | dock $k] → [truck $j | dock $l]")
            end
        end    
        println("    at the time marker r=$r:  $sommeIN pallets entered into the terminal")
        println("                              $sommeOUT pallets taken out of the terminal")
        println("                  i.e. ", sommeIN-sommeOUT," pallets ≤ $(instance.C)\n")    
    end

    s_tr = Vector{String}(undef,2*n)
    for timeMarkers in 1:2*n
        sHH, sMM = string.(convertMinutesHHMM(tr[timeMarkers]))
        length(sHH)==1 ? sHH = "0" * sHH : nothing
        length(sMM)==1 ? sMM = "0" * sMM : nothing
        s_tr[timeMarkers] = sHH * ":" * sMM
    end

    nPallets = zeros(Int, n*n, 2*n) # split f[i,j] on one dimension for each timemarker -> n*n x 2*n
    for r in 1:2*n
        for i in atr[r], j=1:n, k=1:m, l=1:m
            if value(mod[:z][i,j,k,l])==1  && instance.f[i,j] > 0
                nPallets[(i-1)*n+j,r] += instance.f[i,j]
            end
        end
        for i=1:n, j in dtr[r], k=1:m, l=1:m
            if value(mod[:z][i,j,k,l])==1
                nPallets[(i-1)*n+j,r] -= instance.f[i,j]
             end
        end    
    end

    figure(formulationID,figsize=(8,6))
    title(instance.name*": Evolution of the load in the terminal")
    xlabel("Time markers")
    ylabel("Number of pallets")
    xticks(ha="right")
    yLim_OnOff == :yLim_On ? ylim(0, instance.C) : nothing

    cm = get_cmap(:jet)
    colorrange = (0:(n*n-1)) ./ (n*n)
    tick_params(
            axis="x",          # changes apply to the x-axis
            which="both",      # both major and minor ticks are affected
            bottom=false,      # ticks along the bottom edge are off
            top=false,         # ticks along the top edge are off
            labelbottom=true)  # labels along the bottom edge are off
    xticks(rotation=45)

    sommePallets = zeros(Int,2*instance.n)
    for i in 1:n*n    
        bar(s_tr, nPallets[i,:], bottom=sommePallets, color=cm(colorrange[i]), edgecolor="white", linewidth=2)
        sommePallets += nPallets[i,:]
    end

    return nothing
end