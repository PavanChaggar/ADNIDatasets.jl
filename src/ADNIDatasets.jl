module ADNIDatasets

using CSV, DataFrames
using Setfield
using Dates

struct ADNIScanData
    Date::Date
    SUVR::Vector{Float64}
    Volume::Vector{Float64}
    SUVR_Ref::Float64
end

struct ADNISubject
    ID::Int64
    n_scans::Int64
    scan_dates::Vector{Date}
    Data::Vector{ADNIScanData}
end

struct ADNIDataset
    n_subjects::Int64
    SubjectData::Vector{ADNISubject}
    rois::Vector{String}
end

function ADNISubject(subid, df, dktnames, reference_region::String)
    sub = filter( x -> x.RID == subid, df )

    subdate = sub[!, :EXAMDATE]
    subsuvr = sub[!, suvr_name.(dktnames)] |> dropmissing |> disallowmissing |> Array
    subvol = sub[!, vol_name.(dktnames)] |> dropmissing |> disallowmissing |> Array
    subref = sub[!, suvr_name.(reference_region)]
    n_scans = length(subdate)
    if n_scans == size(subsuvr, 1) == size(subvol, 1)
       return  ADNISubject(
                subid,
                n_scans,
                subdate,
                [ADNIScanData(subdate[i], subsuvr[i,:], subvol[i,:], subref[i]) for i in 1:n_scans]
        )
    end
end

function ADNIDataset(df, dktnames; min_scans=3, reference_region="inferiorcerebellum")
    subjects = unique(df.RID)

    n_scans = [count(==(sub), df.RID) for sub in subjects]
    multi_subs = subjects[findall(x -> x >= min_scans, n_scans)]

    adnisubjects = Vector{ADNISubject}()
    for sub in multi_subs 
        sub = ADNISubject(sub, df, dktnames, reference_region)
        if sub isa ADNISubject
            push!(adnisubjects, sub)
        end
    end
    ADNIDataset(
        length(adnisubjects),
        adnisubjects,
        dktnames
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

function get_suvr_ref(data::ADNISubject)
    reduce(vcat, [get(data , @lens _.Data[i].SUVR_Ref) for i in 1:data.n_scans])
end

function get_suvr_ref(data::ADNIDataset, subject)
    subdata = get_subject_data(data, subject)
    get_suvr_ref(subdata)
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

function get_times(data::ADNISubject)
    dates = data.scan_dates
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
    ref = get_suvr_ref(data)
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

function get_initial_conditions(data, subject)
    data = calc_suvr(data, subject)
    data[:,1]
end

function Base.length(data::ADNIDataset)
    get(data, @lens _.n_subjects)
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

# Exports
export ADNIDataset
export get_suvr, get_suvr_ref, get_vol, get_times, 
       get_id, calc_suvr, get_initial_conditions
end # module ADNIDatasets
