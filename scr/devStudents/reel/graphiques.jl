
# =============================================================================
function traceFlux(quaiDep::Int64, quaiArr::Int64, nbrQuai::Int64)

    if quaiDep <= Int(nbrQuai/2)

        # cas ou le quai de depart est dans la premiere moitie des quais
        println("quai depart au nord")

        if quaiDep == 1
            sethue("blue")
        elseif quaiDep == 2
            sethue("red3")
        elseif quaiDep == 3
            sethue("green")
        elseif quaiDep == 4
            sethue("darkgoldenrod")
        elseif quaiDep == 5
            sethue("orangered3") 
        elseif quaiDep == 6
            sethue("turquoise3") 
        elseif quaiDep == 7
            sethue("blueviolet")                      
        end 

        if quaiArr <= Int(nbrQuai/2)
            # vers un quai du meme cote du terminal 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            i = quaiArr
            pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
            Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
        else
            # vers un quai de l'autre cote du terminal 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            i = nbrQuai-quaiArr+1
            pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),90)
            poly([pt0, pt1, pt2, pt3], :stroke)
            Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
        end     
    
    else

        # cas ou le quai de depart est dans la seconde moitie des quais
        println("quai depart au sud")  

        if quaiDep == 8
            sethue("royalblue1")
        elseif quaiDep == 9
            sethue("indianred1")
        elseif quaiDep == 10
            sethue("chartreuse")
        elseif quaiDep == 11
            sethue("gold")
        elseif quaiDep == 12
            sethue("orangered1") 
        elseif quaiDep == 13
            sethue("cyan") 
        elseif quaiDep == 14
            sethue("magenta")                      
        end

        if quaiArr > Int(nbrQuai/2)
            # vers un quai du meme cote du terminal 
            quaiDep = nbrQuai-quaiDep+1 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            i = nbrQuai-quaiArr+1
            if quaiDep!=i  
                pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
                pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,90)
                poly([pt0, pt1, pt2, pt3], :stroke)
                Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
            end
        else
            # vers un quai de l'autre cote du terminal  
            quaiDep = nbrQuai-quaiDep+1       
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            i = quaiArr
            pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,-90)
            poly([pt0, pt1, pt2, pt3], :stroke)
            Luxor.arrow(pt2, pt3, arrowheadlength=8, arrowheadangle=pi/8, linewidth=.3)
        end
    
    end     

    return nothing
end


# =============================================================================
function traceTousFluxEntreQuais()

    long=193; larg=100; echelle = 2

    @png begin

        # pose le fond de l'image du terminal ---------------------------------

        # perimetre du terminal 
        sethue("black")
        rect(-200,-100,long*echelle,larg*echelle, :stroke)

        # quais au nord
        for i in 1:7
            sethue("black")
            rect(-245+i*55,-106,17*echelle,6*echelle, :fill)
            label = string(i)
            sethue("white")
            textcentered(label,-245+i*55+8*echelle,-97)
        end

        # quais au sud
        for i in 14:-1:8
            sethue("black")
            rect(-245+(14-i+1)*55,94,17*echelle,6*echelle, :fill)
            label = string(i)
            sethue("white")
            textcentered(label,-245+(14-i+1)*55+8*echelle,103)
        end  

        # pose tous les chemins de palettes depuis les quais 1 a 7 ------------
        for quaiDep = 1:7

            if quaiDep == 1
                sethue("blue")
            elseif quaiDep == 2
                sethue("red3")
            elseif quaiDep == 3
                sethue("green")
            elseif quaiDep == 4
                sethue("darkgoldenrod")
            elseif quaiDep == 5
                sethue("orangered3") 
            elseif quaiDep == 6
                sethue("turquoise3") 
            elseif quaiDep == 7
                sethue("blueviolet")                      
            end 

            # vers un quai du meme cote du terminal 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            for i in 1:7
                if quaiDep!=i    
                    pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
                    pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),-90)
                    poly([pt0, pt1, pt2, pt3], :stroke)
                end
            end    
    
            # vers un quai de l'autre cote du terminal 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
            for i in 1:7
                pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1),-70+3*(quaiDep-1))
                pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1),90)
                poly([pt0, pt1, pt2, pt3], :stroke)
            end  

        end
    

        # pose tous les chemins de palettes depuis les quais 8 a 14 ---------------
        for quaiDep = 8:14

            if quaiDep == 8
                sethue("royalblue1")
            elseif quaiDep == 9
                sethue("indianred1")
            elseif quaiDep == 10
                sethue("chartreuse")
            elseif quaiDep == 11
                sethue("gold")
            elseif quaiDep == 12
                sethue("orangered1") 
            elseif quaiDep == 13
                sethue("cyan") 
            elseif quaiDep == 14
                sethue("magenta")                      
            end

            quaiDep = quaiDep-7
    
            # vers un quai du meme cote du terminal 
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            for i in 1:7
                if quaiDep!=i  
                    pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
                    pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,90)
                    poly([pt0, pt1, pt2, pt3], :stroke)
                end
            end
    
            # vers un quai de l'autre cote du terminal         
            pt0 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,90)
            pt1 = Point(-173+(quaiDep-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
            for i in 1:7 
                pt2 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,70-3*(quaiDep-1))
                pt3 = Point(-173+(i-1)*55+3*2(quaiDep-1)+3,-90)
                poly([pt0, pt1, pt2, pt3], :stroke)
            end
    
        end
    end

    #return nothing
end


# =============================================================================
function traceDesFluxEntreQuais(nbrQuai::Int64)

    long=193; larg=100; echelle = 2

    @png begin

        # pose le fond de l'image du terminal ---------------------------------

        # perimetre du terminal 
        sethue("black")
        rect(-200,-100,long*echelle, larg*echelle, :stroke)

        # quais
        for i in 1:Int(nbrQuai/2)
            sethue("black")
            rect(-245+i*55, -106, 17*echelle, 6*echelle, :fill)
            rect(-245+i*55, 94,   17*echelle, 6*echelle, :fill)
            sethue("white")
            label = string(i)
            textcentered(label, -245+i*55+8*echelle, -97)
            label = string(nbrQuai-i+1)
            textcentered(label, -245+i*55+8*echelle, 103)
        end 
    
        # pose les flux -------------------------------------------------------
        traceFlux(2,4,4)
        traceFlux(1,4,4)
        traceFlux(2,1,4)  
    end

    #return nothing
end


# =============================================================================
# =============================================================================



# =============================================================================
function traceCamionQuai(hArr::Float64, hDep::Float64, iCamion::Int64)
    tempsArr = hArr*60 - 8*60
    tempsDep = (hDep-hArr)*60
    if iCamion <=8 
        if iCamion == 1
            sethue("blue")
        elseif iCamion == 2
            sethue("red")
        elseif iCamion == 3
            sethue("green")
        elseif iCamion == 4
            sethue("orange")
        elseif iCamion == 5
            sethue("magenta") 
        elseif iCamion == 6
            sethue("turquoise3") 
        elseif iCamion == 7
            sethue("blueviolet")   
        elseif iCamion == 8
            sethue("sienna4")                      
        end 

    else
        sethue("black")  
    end      
    rect(-250+tempsArr*45/60, -280+(iCamion-1)*20-5, tempsDep*45/60, 10, :fill)
end

# =============================================================================
function traceFenetresTempsCamionsCharges(Camions3essieux,
                                          Camions6essieux,
                                          chargementCamions6essieux,
                                          f)

    nbrCamions3essieux = length(Camions3essieux)
    nbrCamions6essieux = length(Camions6essieux)
    long=600; larg=600; echelle = 1

    @png begin

        # pose le fond de l'image du Gantt ------------------------------------
        sethue("black")
        rect(-300,-300,long*echelle,larg*echelle, :stroke)
        for i in 1:8
            pt1 = Point(-250,-280+(i-1)*20)
            pt2 = Point(245,-280+(i-1)*20)
            line(pt1, pt2, :stroke)
            label = string(i)
            textcentered(label, -260, -280+(i-1)*20)
        end
        for i in 9:28
            pt1 = Point(-250,-280+(i-1)*20)
            pt2 = Point(245,-280+(i-1)*20)
            line(pt1, pt2, :stroke)
            label = string(i-8)
            textcentered(label, -260, -280+(i-1)*20)
        end    
        for i in 1:12
            pt1 = Point(-250+(i-1)*45,270)
            pt2 = Point(-250+(i-1)*45,280)
            line(pt1, pt2, :stroke)
            label = string(i+7)
            textcentered(label, -250+(i-1)*45,295)
        end   
    
        # trace les fenetres de temps des camions a quai ----------------------
        for tr in 1:nbrCamions6essieux       
            traceCamionQuai(Camions6essieux[tr].hArr, Camions6essieux[tr].hDep, tr)
        end

        for tr in 1:nbrCamions3essieux      
            traceCamionQuai(Camions3essieux[tr].hArr, Camions3essieux[tr].hDep, tr+8)
        end
    
        # trace les palettes transportees dans les camions 6 essieux
        for tr6 in 1:nbrCamions6essieux
            if tr6 == 1
                sethue("blue")
            elseif tr6 == 2
                sethue("red")
            elseif tr6 == 3
                sethue("green")
            elseif tr6 == 4
                sethue("orange")
            elseif tr6 == 5
                sethue("magenta") 
            elseif tr6 == 6
                sethue("turquoise3") 
            elseif tr6 == 7
                sethue("blueviolet")   
            elseif tr6 == 8
                sethue("sienna4")                      
            end 
            
            label = string(chargementCamions6essieux[tr6])
            textcentered(label, -250+(((Camions6essieux[tr6].hArr*60)- 8*60)*45/60) +3, -280+(tr6-1)*20-6)
        end 

        # trace les palettes attendues dans les camions 3 essieux
        for tr3 in 1:nbrCamions3essieux
    
            pas = 0
            for tr6 in 1:nbrCamions6essieux
                if tr6 == 1
                    sethue("blue")
                elseif tr6 == 2
                    sethue("red")
                elseif tr6 == 3
                    sethue("green")
                elseif tr6 == 4
                    sethue("orange")
                elseif tr6 == 5
                    sethue("magenta") 
                elseif tr6 == 6
                    sethue("turquoise3") 
                elseif tr6 == 7
                    sethue("blueviolet")   
                elseif tr6 == 8
                    sethue("sienna4")                      
                end 
                
                if f[tr6,tr3+nbrCamions6essieux] != 0 
                    print(f[tr6,tr3+nbrCamions6essieux], " ")
                    label = string(f[tr6,tr3+nbrCamions6essieux])
                    println(">>>", Camions3essieux[tr3].hArr *45/60)
                    textcentered(label, -250+(((Camions3essieux[tr3].hArr*60)- 8*60)*45/60) +pas+3, -280+(tr3-1+8)*20-6)
                    pas+=15
                end
            end
            println(" ")
        end
    
    end

end
