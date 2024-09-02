
# --- given parameters --------------------------------------------------------

# number of docks / nombre de quais 
m = 14
dist = zeros(Float64,m,m)

for quaiDep in 1:Int(m/2), quaiArr in 1:m
    if quaiArr <= Int(m/2)
        dist[quaiDep,quaiArr] = 2 + (abs(quaiArr-quaiDep))*5.5 + 2
    else
        dist[quaiDep,quaiArr] = 2 + abs(m-quaiArr+1 - quaiDep)*5.5 + 16 + 2
    end
end

for quaiDep in Int(m/2)+1:m, quaiArr in 1:m
    if quaiArr <= Int(m/2)
        dist[quaiDep,quaiArr] = 2 + abs(m-quaiArr+1 - quaiDep)*5.5 + 16 + 2
    else
        dist[quaiDep,quaiArr] = 2 + (abs(quaiArr-quaiDep))*5.5 + 2
    end
end

@show dist

# engin de levage evoluant en moyenne a 5km/h
vitesse = 5 # kilometres/heure
t = dist.* vitesse/10000 # heure

using Luxor
Drawing(1000,1000,"Cross-Dock.png")
long=193;larg=100
echelle = 2
@png begin
    sethue("black")
    rect(-200,-100,long*echelle,larg*echelle, :stroke)
    for i in 1:7
     sethue("black")
     rect(-245+i*55,-106,17*echelle,6*echelle, :fill)
     label = string(i)
     sethue("white")
     textcentered(label,-245+i*55+8*echelle,-97)
    end
    for i in 14:-1:8
        sethue("black")
        rect(-245+(14-i+1)*55,94,17*echelle,6*echelle, :fill)
        label = string(i)
        sethue("white")
        textcentered(label,-245+(14-i+1)*55+8*echelle,103)
    end  

    # 1111111
    #=
    sethue("blue")
    i=1
    pt0 = Point(-173+(i-1)*55,-90)
    pt1 = Point(-173+(i-1)*55,90)
    line(pt0,pt1, :stroke) 

    i=1
    pt0 = Point(-173+(i-1)*55,-90)
    pt1 = Point(-173+(i-1)*55,-70)
    for i in 2:7
    pt2 = Point(-173+(i-1)*55,-70)
    pt3 = Point(-173+(i-1)*55,-90)
    poly([pt0, pt1, pt2, pt3], :stroke)
    end    
    
    i=1
    pt0 = Point(-173+(i-1)*55,-90)
    pt1 = Point(-173+(i-1)*55,-70)
    for i in 2:7
    pt2 = Point(-173+(i-1)*55,-70)
    pt3 = Point(-173+(i-1)*55,90)
    poly([pt0, pt1, pt2, pt3], :stroke)
    end
    =#

    sethue("royalblue1")
    i=1
    pt0 = Point(-173+(i-1)*55+3,-90)
    pt1 = Point(-173+(i-1)*55+3,90)
    line(pt0,pt1, :stroke)  

    i=1
    pt0 = Point(-173+(i-1)*55+3,90)
    pt1 = Point(-173+(i-1)*55+3,70)
    for i in 2:7
        pt2 = Point(-173+(i-1)*55+3,70)
        pt3 = Point(-173+(i-1)*55+3,90)
        poly([pt0, pt1, pt2, pt3], :stroke)
    end    

    i=1
    pt0 = Point(-173+(i-1)*55+3,90)
    pt1 = Point(-173+(i-1)*55+3,70)
    for i in 2:7
        pt2 = Point(-173+(i-1)*55+3,70)
        pt3 = Point(-173+(i-1)*55+3,-90)
        poly([pt0, pt1, pt2, pt3], :stroke)
    end


    #22222
    #=
    sethue("red")
    for i in 2:2
        pt0 = Point(-173+(i-1)*55+6,-90)
        pt1 = Point(-173+(i-1)*55+6,90)
        line(pt0,pt1, :stroke)  
    end

    d=2
    pt0 = Point(-173+(d-1)*55+6,-90)
    pt1 = Point(-173+(d-1)*55+6,-70+3)
    for i in 1:7
        if d!=i    
            pt2 = Point(-173+(i-1)*55+6,-70+3)
            pt3 = Point(-173+(i-1)*55+6,-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    end    
    
    d=2
    pt0 = Point(-173+(d-1)*55+6,-90)
    pt1 = Point(-173+(d-1)*55+6,-70+3)
    for i in 1:7
        if d!=i    
            pt2 = Point(-173+(i-1)*55+6,-70+3)
            pt3 = Point(-173+(i-1)*55+6,90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    end  
    =#
    
    sethue("indianred1")
    i=2
    pt0 = Point(-173+(i-1)*55+9,-90)
    pt1 = Point(-173+(i-1)*55+9,90)
    line(pt0,pt1, :stroke)  


    d=2
    pt0 = Point(-173+(d-1)*55+9,90)
    pt1 = Point(-173+(d-1)*55+9,70-3)
    for i in 1:7
        if d!=i  
            pt2 = Point(-173+(i-1)*55+9,70-3)
            pt3 = Point(-173+(i-1)*55+9,90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    end

    d=2
    pt0 = Point(-173+(d-1)*55+9,90)
    pt1 = Point(-173+(d-1)*55+9,70-3)
    for i in 1:7
        if d!=i  
            pt2 = Point(-173+(i-1)*55+9,70-3)
            pt3 = Point(-173+(i-1)*55+9,-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    end


    #33333
    for quaiDep = 1:7
    if quaiDep == 1
        sethue("blue")
    elseif quaiDep == 2
        sethue("red")
    elseif quaiDep == 3
        sethue("green")
    elseif quaiDep == 4
        sethue("gold")
    elseif quaiDep == 5
        sethue("orange") 
    elseif quaiDep == 6
        sethue("cyan") 
    elseif quaiDep == 7
        sethue("magenta")                      
    end

    pt0 = Point(-173+(quaiDep-1)*55+3*(quaiDep+1),-90)
    pt1 = Point(-173+(quaiDep-1)*55+3*(quaiDep+1),90)
    line(pt0,pt1, :stroke)  

    pt0 = Point(-173+(quaiDep-1)*55+3*(quaiDep+1),-90)
    pt1 = Point(-173+(quaiDep-1)*55+3*(quaiDep+1),-70+3*(quaiDep-1))
    for i in 1:7
        if quaiDep!=i    
            pt2 = Point(-173+(i-1)*55+3*(quaiDep+1),-70+3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*(quaiDep+1),-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    end    
    
    pt0 = Point(-173+(quaiDep-1)*55+3*(quaiDep+1),-90)
    pt1 = Point(-173+(quaiDep-1)*55+3*(quaiDep+1),-70+3*(quaiDep-1))
    for i in 1:7
        if quaiDep!=i    
            pt2 = Point(-173+(i-1)*55+3*(quaiDep+1),-70+3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*(quaiDep+1),90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    end  

    end
    
    #=
    sethue("indianred1")
    i=2
    pt0 = Point(-173+(i-1)*55+9,-90)
    pt1 = Point(-173+(i-1)*55+9,90)
    line(pt0,pt1, :stroke)  


    d=2
    pt0 = Point(-173+(d-1)*55+9,90)
    pt1 = Point(-173+(d-1)*55+9,70-3)
    for i in 1:7
        if d!=i  
            pt2 = Point(-173+(i-1)*55+9,70-3)
            pt3 = Point(-173+(i-1)*55+9,90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    end

    d=2
    pt0 = Point(-173+(d-1)*55+9,90)
    pt1 = Point(-173+(d-1)*55+9,70-3)
    for i in 1:7
        if d!=i  
            pt2 = Point(-173+(i-1)*55+9,70-3)
            pt3 = Point(-173+(i-1)*55+9,-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
        end
    end    
=#
 end
 