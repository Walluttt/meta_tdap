using PyPlot

# --------------------------------------------------------------------------- #
# Display the Gantt chart corresponding to the previsionnal planning of 
# trucks and transferts of pallets

function displayGanttInstance(instance::Instance)
    
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


    truckID = string.(collect(1:instance.n))

    title("Previsional planning of trucks and transferts of pallets",fontsize=10)
    xlim([hmin-1,hmax+1])

    xlabel("time")
    ylabel("truck ID")

    barh(truckID, left=instance.a/60, width=tOccupationQuai/60, height=0.25, color=colors)
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