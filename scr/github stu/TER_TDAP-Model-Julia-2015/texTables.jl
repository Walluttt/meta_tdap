using TexTables, DataFrames

function TER_latexTable(instances, m2015_times, m2015_result, m2009_times, m2009_result)

    t1 = TableCol("M09_time", instances, m2009_times)
    t2 = TableCol("M09_res", instances, m2009_result)
    t3 = TableCol("M15_time", instances, m2015_times);
    t4 = TableCol("M15_res", instances, m2015_result)

    table = hcat(t2, t1, t4, t3)
    return table
end

function to_table(instances, results, times, nb)

    t_time = TableCol("Times (s)", instances, times)
    t_value = TableCol("Obj value", instances, results)
    t_cpt = TableCol("Nb cargo", instances, nb)

    table = hcat(t_value, t_time, t_cpt)
    return table
end

function to_table2(instances, results, times, nb,nb_p,nb_deli_td,nb_p_td,t_cardinal_pareto)

    t_time = TableCol("Times (s)", instances, times)
    t_value = TableCol("Obj value", instances, results)
    t_cpt = TableCol("Nb cargo", instances, nb)
    t_p = TableCol("Nb pallets",instances, nb_p)
    t_ndtd = TableCol("Nb deli TD",instances, nb_deli_td)
    t_ptd = TableCol("Nb pallets TD",instances, nb_p_td)
    t_card_p = TableCol("Carinal Pareto",instances,t_cardinal_pareto)

    table = hcat(t_value, t_time, t_cpt,t_p,t_ndtd,t_ptd)
    return table
end

function to_table_moa(instances, results1,results2, times,t_delivery,t_delivery_done,pallets)

    t_time = TableCol("Times(s)", instances, times)
    t_value1 = TableCol("Obj_1", instances, results1)
    t_value2 = TableCol("Obj_2", instances, results2)
    t_cpt1 = TableCol("Deli_todo", instances, t_delivery)
    t_cpt2 = TableCol("deli_done", instances, t_delivery_done)
    t_palltes = TableCol("Pallets tranfer", instances, pallets)
    t_data = TableCol("Data",instances,instances)

    table = hcat(t_data,t_value1,t_value2,t_cpt1,t_cpt2,t_palltes,t_time)
    return table
end

#----------------------------------------------------------------------------------------------
# Example
#=
function exampleTable()

    // select some instances
    instances = ["I1", "I2", "I3"]
    // get result
    tps1 = [1.34, 2.34, 3.34]
    res1 = [1023, 3432, 1232]
    tps2 = [2.34, 3.34, 4.34]
    res2 = [4321, 3454, 1243]
    // build the table
    table = TER_latexTable(instances, tps1, res1, tps2, res2)
    // print the table
    table |> print
    println("")
    // get the table into latex format
    to_tex(table) |> print
end
=#

function dataframe_to_latex(df::DataFrame)
    ncols = ncol(df)
    nrows = nrow(df)
    
    # Header
    latex_str = "\\begin{tabular}{|"
    for i in 1:ncols
        latex_str *= "c|"
    end
    latex_str *= "}\n\\hline\n"
    
    # Column names
    for col in names(df)
        latex_str *= "$col & "
    end
    latex_str = latex_str[1:end-2] * "\\\\\n\\hline\n"
    
    # Data rows
    for i in 1:nrows
        for j in 1:ncols
            latex_str *= string(df[i, j])
            if j < ncols
                latex_str *= " & "
            else
                latex_str *= " \\\\\n"
            end
        end
    end
    
    # Footer
    latex_str *= "\\hline\n\\end{tabular}"
    
    return latex_str
end