module ADNIDatasets

using CSV, DataFrames
using Setfield
using Dates

include("dktnames.jl")

struct ADNIScanData
    Date::Date
    SUVR::Vector{Float64}
    Volume::Vector{Float64}
    Ref_SUVR::Float64
    Ref_Vol::Float64
end

struct ADNISubject
    ID::Int
    n_scans::Int
    scan_dates::Vector{Date}
    Data::Vector{ADNIScanData}
end

struct ADNIDataset
    n_subjects::Int
    SubjectData::Vector{ADNISubject}
    rois::Vector{String}
end

function ADNISubject(subid, df::DataFrame, roi_names, reference_region::String)
    sub = filter( x -> x.RID == subid, df )
    
    if "EXAMDATE" ∈ names(sub)
        subdate = sub[!, :EXAMDATE]
    elseif "SCANDATE" ∈ names(sub)
        subdate = sub[!, :SCANDATE]
    end
    subsuvr = sub[!, suvr_name.(roi_names)] |> dropmissing |> disallowmissing |> Array
    subvol = sub[!, vol_name.(roi_names)] |> dropmissing |> disallowmissing |> Array
    subref_suvr = sub[!, suvr_name.(reference_region)]
    subref_vol = sub[!, vol_name.(reference_region)]
    n_scans = length(subdate)
    if n_scans == size(subsuvr, 1) == size(subvol, 1)
       return  ADNISubject(
                subid,
                n_scans,
                subdate,
                [ADNIScanData(subdate[i], subsuvr[i,:], subvol[i,:], 
                              subref_suvr[i], subref_vol[i]) for i in 1:n_scans]
        )
    end
end

function ADNIDataset(df::DataFrame, roi_names=dktnames; min_scans=1, max_scans=Inf, reference_region="inferiorcerebellum", qc=true)
    
    if qc
        df = filter(x -> x.qc_flag == 2, df) # check QC status
    end
    
    subjects = unique(df.RID)
    n_scans = [count(==(sub), df.RID) for sub in subjects]
    multi_subs = subjects[findall(x -> min_scans <= x <= max_scans, n_scans)]

    adnisubjects = Vector{ADNISubject}()
    for sub in multi_subs 
        sub = ADNISubject(sub, df, roi_names, reference_region)
        if sub isa ADNISubject
            push!(adnisubjects, sub)
        end
    end
    ADNIDataset(
        length(adnisubjects),
        adnisubjects,
        roi_names
    )
end

function get_subject_data(data::ADNIDataset, subject)
    lns = @lens _.SubjectData[subject]
    get(data, lns)
end

function get_suvr(data::ADNISubject)
    reduce(hcat, [get(data , @lens _.Data[i].SUVR) for i in 1:data.n_scans])
end

function get_suvr(data::ADNIDataset, subject)
    subdata = get_subject_data(data, subject)
    get_suvr(subdata)
end

function get_ref_suvr(data::ADNISubject)
    reduce(vcat, [get(data , @lens _.Data[i].Ref_SUVR) for i in 1:data.n_scans])
end

function get_ref_suvr(data::ADNIDataset, subject)
    subdata = get_subject_data(data, subject)
    get_ref_suvr(subdata)
end

function get_ref_vol(data::ADNISubject)
    reduce(vcat, [get(data , @lens _.Data[i].Ref_Vol) for i in 1:data.n_scans])
end

function get_ref_vol(data::ADNIDataset, subject)
    subdata = get_subject_data(data, subject)
    get_ref_vol(subdata)
end

function get_norm_suvr(data, subject)
    subsuvr = get_suvr(data, subject)
    subsuvr ./ maximum(subsuvr)
end

function get_vol(data::ADNISubject)
    reduce(hcat, [get(data , @lens _.Data[i].Volume) for i in 1:data.n_scans])
end

function get_vol(data::ADNIDataset, subject)
    subdata = get_subject_data(data, subject)
    get_vol(subdata)
end

function get_dates(data::ADNISubject)
    get(data, @lens _.scan_dates)
end
function get_dates(data::ADNIDataset, subject)
    subdata = get_subject_data(data, subject)
    get_dates(subdata)
end

function get_times(data::ADNISubject)
    dates = get_dates(data)
    days = dates .- minimum(dates)
    [get(day, @lens _.value) for day in days] ./ 365
end

function get_times(data::ADNIDataset, subject)
    subdata = get_subject_data(data, subject)
    get_times(subdata)
end

function get_id(data::ADNIDataset, subject)
    subdata = get_subject_data(data, subject)
    get_id(subdata)
end

function get_id(data::ADNISubject)
    get(data, @lens _.ID)
end

function get_id(data::ADNIDataset)
    [get_id(data, i) for i in 1:length(data)]
end

function calc_suvr(data::ADNISubject; max_norm = false)
    suvr = get_suvr(data)
    ref = get_ref_suvr(data)
    data = suvr ./ ref'
    if max_norm
        return data ./ maximum(data)
    else
        return data
    end
end

function calc_suvr(data::ADNIDataset, subject; max_norm = false)
    subdata = get_subject_data(data, subject)
    calc_suvr(subdata; max_norm = max_norm)
end

function get_initial_conditions(data::ADNISubject)
    data = calc_suvr(data)
    data[:,1]
end

function get_initial_conditions(data::ADNIDataset, subject)
    data = calc_suvr(data, subject)
    data[:,1]
end

function Base.show(io::IO, data::ADNIDataset)
    n_subs = data.n_subjects
    n_scans = sum([sub.n_scans for sub in data.SubjectData])
    print(io, "ADNI data set with $n_subs subjects and $(n_scans) scans.")
end

function Base.show(io::IO, sub::ADNISubject)
    println(io, "Subject ID: $(sub.ID)")
    print(io, "Number of scans: $(sub.n_scans)")
end

function Base.show(io::IO, scan::ADNIScanData)
    print(io, "Scan Date: $(scan.Date)")
end

suvr_name(roi) = uppercase("$(roi)" * "_suvr")
vol_name(roi) = uppercase("$(roi)" * "_volume")

# ------------------------------------------------------------
# ADNI Dataset iteration
# ------------------------------------------------------------

function Base.getindex(data::ADNIDataset, idx::Int)
    return data.SubjectData[idx]
end

function Base.getindex(data::ADNIDataset, idx::Vector{Int})
    return ADNIDataset(length(idx), data.SubjectData[idx], data.rois)
end

function Base.getindex(data::ADNIDataset, idx::UnitRange{Int})
    _idx = collect(idx)
    return ADNIDataset(length(idx), data.SubjectData[_idx], data.rois)
end

function Base.iterate(d::ADNIDataset, state=1)
    state > length(d) ? nothing : (d[state], state+1)
end

Base.eltype(d::ADNIDataset) = ADNISubject
Base.IteratorEltype(d::ADNIDataset) = Base.HasEltype()
Base.keys(d::ADNIDataset) = LinearIndices(1:length(d))
Base.values(d::ADNIDataset) = d.SubjectData
function Base.length(data::ADNIDataset)
    get(data, @lens _.n_subjects)
end

Base.lastindex(d::ADNIDataset) = length(d)

function Base.filter(func, data::ADNIDataset)
    d = Iterators.filter(func, data) |> collect
    ADNIDataset(length(d), d, data.rois)
end

# ------------------------------------------------------------
# ADNI Subject iteration
# ------------------------------------------------------------
function Base.getindex(sub::ADNISubject, idx::Int)
    return sub.Data[idx]
end

function Base.getindex(sub::ADNISubject, idx::Vector{Int})
    return ADNISubject(sub.ID, length(idx), sub.scan_dates[idx], sub.Data[idx])
end

function Base.getindex(sub::ADNISubject, idx::UnitRange{Int})
    _idx = collect(idx)
    return ADNISubject(sub.ID, length(idx), sub.scan_dates[_idx], sub.Data[_idx])
end

function Base.iterate(d::ADNISubject, state=1)
    state > length(d) ? nothing : (d[state], state+1)
end

function Base.length(data::ADNISubject)
    get(data, @lens _.n_scans)
end

Base.lastindex(d::ADNISubject) = length(d)

# Dashboard
function data_dashboard end

# Exports
export ADNIDataset, ADNISubject, ADNIScanData
export get_suvr, get_ref_suvr, get_ref_vol, get_vol, get_dates, get_times, 
       get_id, calc_suvr, get_initial_conditions
export data_dashboard

end # module ADNIDatasets
