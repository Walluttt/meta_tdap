using Luxor, PyPlot   # pour les dessins
using Random, Distributions

include("../loadTDAP.jl")
include("dataTerminal.jl")
include("graphiques.jl")
include("timeWindows.jl")
include("ventilationCamions.jl")

mutable struct Camion
    numero     :: Int64
    hArr       :: Float64
    hDep       :: Float64
    nPalettes  :: Vector{Int64}
end


function instance_generator()
  # === Parametres ==============================================================

  # nombre de quais du terminal (nombre obligatoirement pair)
  m = rand(4:2:8)#14

  # vitesse (km/h) moyenne des engins de levage 
  vitesse = 5  # 5km/h en moyenne 

  # Nombre et chargement max des camions a 3 essieux
  nbrMaxCamions3essieux = 12#20
  nbrMaxPalettesCamions3essieux = 16

  # Nombre et chargement max des camions a 6 essieux
  nbrMaxCamions6essieux = 6#8
  nbrMaxPalettesCamions6essieux = 40

  # Nombre maximum de palettes a considerer
  nbrMaxPalettes = 240#320

  # =============================================================================
  # =============================================================================

  # === Calcul des donnees relatives au terminal ================================
  dist = calculDistancesEntreQuais(m)
  temps = calculTempsEntreQuais(dist, vitesse)

  # === Genere un scenario (fenetres de temps + chargements pour les camions entrants et sortants
  # === Attention : cette fonction peut se terminer sur un echec!
  chargementCamions3essieux, chargementCamions6essieux, f = genereChargementsTransporter(nbrMaxCamions3essieux, nbrMaxCamions6essieux, nbrMaxPalettesCamions3essieux, nbrMaxPalettesCamions6essieux,nbrMaxPalettes)
  #println("\nChargement initial des camions 6 essieux :", chargementCamions6essieux)
  #println("\nChargement final des camions 3 essieux   :", chargementCamions3essieux)

  # === Generation des fenetres de temps dans [8h;19h] pour les 3 types de camion
  Camions3essieux, Camions6essieux = genererFenetreTemps(chargementCamions3essieux, chargementCamions6essieux)

  # === Trace le diagramme de Gantt des donnees de l'instance ===================
  traceFenetresTempsCamionsCharges(Camions3essieux, Camions6essieux, chargementCamions6essieux, f)

  # === Trace tous les flux possibles entre les quais ===========================
  #traceTousFluxEntreQuais()
  
  # === Trace des flux fournis entre les quais ==================================
  #traceDesFluxEntreQuais(m)




  # --- given parameters --------------------------------------------------------

  # number of trucks / nombre de camions
  nbrCamions3essieux = length(chargementCamions3essieux)
  nbrCamions6essieux = length(chargementCamions6essieux)
  n = nbrCamions3essieux+nbrCamions6essieux

  # number of docks / nombre de quais 
  #m = 4 

  # operational cost per unit time from dock k to dock l 
  c = dist.-4.0
  #=
  c = [0.0 10.0 20.0 10.0; 
      10.0 0.0 10.0 20.0; 
      20.0 10.0 0.0 10.0;
      10.0 20.0 10.0 0.0]
  =#

  # operational time for pallets from dock k to dock l  (in minutes, 0<=minutes<=59)
  t = temps


  # penalty cost per unit cargo from truck i to truck j
  p = fill(100,n,n)
  for i in 1:n
      p[i,i]=0
  end

  # number of pallets transferring from truck i to truck j 


  # capacity of the cross dock terminal (maximum number of cargos the cross dock can hold at a time)
  C = 100 

  a = []
  d = []
  for i in eachindex(Camions6essieux)
      push!(a,Camions6essieux[i].hArr)
      push!(d,Camions6essieux[i].hDep)
  end 
  for i in eachindex(Camions3essieux)
      push!(a,Camions3essieux[i].hArr)
      push!(d,Camions3essieux[i].hDep)
  end 


  # arrival time of truck i (in hour.minutes, 0<=hour<=23, 0<=minutes<=59)
  #a = [12.40, 09.10, 09.10, 14.30, 10.12, 08.25]
  # departure time of truck i
  #d = [17.13, 16.10, 14.00, 17.53, 16.05, 13.10]

  # --- built parameters --------------------------------------------------------

  # 1 iff truck i departs no later than truck j arrives, 0 otherwise
  δ=zeros(Int64,n,n)  

  for i=1:n, j=1:n
      if i!=j
          if d[i] <= a[j]
              δ[i,j] = 1
          end
      end
  end

  ## time corresponding to arrivals and departures, merged and sorted
  #tr = sort(vcat(a,d))
  #
  #atr = Vector{Int64}[]
  #for r=1:2*n
  #    println("r = $r")
  #    v = (Int64)[]
  #    for i=1:n
  #        print("  $(a[i])  $(tr[r]) : ")
  #        if a[i]<=tr[r]
  #            println("$i")
  #            push!(v,i)
  #        else
  #            println(" ")
  #        end
  #    end
  #    push!(atr,v)
  #end
  #
  #dtr = Vector{Int64}[]
  #for r=1:2*n
  #    println("r = $r")
  #    v = (Int64)[]
  #    for j=1:n
  #        print("  $(d[j])  $(tr[r]) : ")
  #        if d[j]<=tr[r]
  #            println("$j")
  #            push!(v,j)            
  #        else
  #            println(" ")
  #        end
  #    end
  #    push!(dtr,v)
  #end
  #
  #@show atr
  #@show dtr

  dockID = 1:m
  truckID = 1:n

  return instance(n,m,truckID,dockID,a,d,t,f,c,p,δ,C)

end

function write_matrix(io,mat::Matrix)

  for i in 1:size(mat,1), j in 1:size(mat,2)
    if j != size(mat,2)
      write(io,string(mat[i,j])*" ")
    else
      write(io,string(mat[i,j])*"\n")
    end
  end
end

function in_hour(h::Float64)

  println(h)
  h_min =Int64(ceil((h-floor(h))*60))
  h_h   =Int64(floor(h))
  return string(h_h)*":"*string(h_min) 

end

function instance_file_generator(file_num)

  inst = instance_generator()

  filed = "../data/inst_reel/inst_reel_$file_num.cd"
  filef = "../data/inst_reel/inst_reel_$file_num.cf"

  touch(filed)
  touch(filef)

  open(filed,"w") do io 
    write(io,"\n")
    write(io,"//nb dock\n")
    write(io,string(inst.m)*"\n")
    write(io,"//capacite de stockage de l'entrepot\n")
    write(io,string(inst.C)*"\n")
    write(io,"//table des temps de transports\n")
    write_matrix(io,inst.t)
    write(io,"table des couts de transports\n")
    write_matrix(io,inst.c)
    write(io,"//ID des quais\n")
    for i in 1:inst.m
      write(io,"quai $i\n")
    end
  end

  open(filef,"w") do io
    write(io,"\n")
    write(io,"//nb camion\n")
    write(io,string(inst.n)*"\n")
    write(io,"//temps d'arrive et de depart des camion\n")
    for i in 1:length(inst.a)
      write(io,in_hour(inst.a[i])*" "*in_hour(inst.d[i])*"\n")
    end
    write(io,"ID des camions\n")
    for i in 1:length(inst.N)
      write(io,"camion $i\n")
    end
    write(io,"//table de cargo des camions\n")
    write(io,"//camion_amenant camion_prenant quantite penalite\n")
    println(inst.N)
    println(size(inst.f,1)," ",size(inst.f,2))
    for i in 1:size(inst.f,1), j in 1:size(inst.f,2)
      if inst.f[i,j] > 0
        write(io,string(inst.N[i]-1)*" "*string(inst.N[j]-1)*" "*string(Int64(inst.f[i,j]))*" "*string(inst.p[i,j])*"\n")
      end
    end
  end
end


function generate(n::Int64)
  k=1
  while k<=n 
    try
      instance_file_generator(k)
      k+=1
      for file in readdir("./")  
          if occursin(".png",file)
            mv(file,joinpath("../fig/instance/", file))
          end
      end
    catch
    end
  end

end