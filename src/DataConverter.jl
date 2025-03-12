module DataConverter 

using CSV, DataFrames

function make_dkt_name(names)
    println(names)
    words = split(names, "_")
    if words[end-1] == "rh" || words[end-1] == "Right"
        hem = "right"
    elseif words[end-1] == "lh" || words[end-1] == "Left"
        hem = "left"
    end
    return lowercase(hem * words[end])
end

make_ucsf_fs_dict(ucsfnames, region_names) = Dict(zip(ucsfnames, region_names))

function make_ucsf_name(ucsf_dictionary_df, region_names; include_icv = true)
    rois = make_dkt_name.(region_names)
    rns = deepcopy(region_names)
    if include_icv
        push!(rns, "icv")
        push!(rois, "icv")
    end

    dict = make_ucsf_fs_dict(rois, rns)

    fldnames = Vector{String}()
    labels = Vector{String}()
    for roi in rois
        roi_df = filter(x -> contains(lowercase(x.TEXT), roi), ucsf_dictionary_df)
    
        for _df in eachrow(roi_df)
            push!(fldnames, _df.FLDNAME)
            push!(labels, prod(split(_df.TEXT)[1:2]) * "_" * dict[roi])
        end
    end
    return fldnames, labels
end

function rename_ucsf_df(df, fldnames, labels)
    newdf = deepcopy(df)
    [rename!(newdf, f => l) for (f, l) in zip(fldnames, labels)]
    return newdf
end

function make_ucsf_df(data_df, dict_df, region_names; include_icv = true)
    fldnames, labels = make_ucsf_name(dict_df, region_names; include_icv = include_icv)
    newdf = rename_ucsf_df(data_df, fldnames, labels)
    return newdf[:, [names(data_df)[1:20]; labels]]
end

function add_icv(data_df, atr_df)
    df = deepcopy(data_df)
    df.ICV = fill(-1., size(df, 1))
    df.Has_ICV = fill(false, size(df, 1));    
    for _df in eachrow(df)
        subdf = filter(x -> x.RID == _df.RID, atr_df)
        if size(subdf, 1) == 0
            continue 
        end
        dt = abs.(_df.SCANDATE .- subdf.EXAMDATE)
        if minimum(dt).value < 120
            _df.ICV = subdf[argmin(dt), "CorticalVolume_icv"]
            _df.Has_ICV = true
        end
    end
    return df
end

end