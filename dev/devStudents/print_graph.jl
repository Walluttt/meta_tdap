using DataFrames
using Plots
include("texTables.jl")

function graph_bi(results,fig_title::String)

  df = DataFrame(
    Data = results[1],
    Obj_1 = results[2],
    Obj_2 = abs.(results[3]),
    Deli_todo = results[4],
    Deli_done = results[5],
    Ratio_deli = results[6],
    Times = results[7]
  )

  println(df)

  gr()
  #return scatter(
  #  df.Data, 
  #  df.Obj_2,
  #  title=fig_title,
  #  series_annotations = text.(df.Ratio_deli,:bottom),
  #  xlabel="Instances", 
  #  ylabel="Objective 2", 
  #  legend=false
  #)
end

function graph_mono(results,fig_title::String)

  df = DataFrame(
      Data = results[1],
      Obj_1 = results[2],
      Deli_todo = results[3],
      Deli_done = results[4],
      Ratio_deli = results[5],
      Times = results[6]
  )

  println(df)

  gr()
  return scatter(
    df.Data, 
    df.Obj_1,
    title=fig_title,
    series_annotations = text.(df.Ratio_deli,:bottom),
    xlabel="Instances", 
    ylabel="Objective", 
    legend=false
  )
end