# ADNIDatasets

Package for working with data from the ALzheimer's Disease Neuroimaging Initaitive in Julia. 

ADNI is an excellent, open data initiative set up to share longitudinal, multimodal neuroimaging data relevant to Alzheimer's diseaes. However, data from ADNI is notoriously hard to work with. This package is an effort to make working with ADNI data easier. 

At present, the package mainly supports analysis of PET neuroimaging data that is analysed using the FreeSurfer DKT atlas, for example the myloid-beta AV45 and tau AV1451 tracers. 

This is a very lightweight packages that simply reads and reorganises tabular data from ADNI. 

# What Does the Package Do? 

There are three main types defined by `ADNIDatasets.jl`, each defining different levels of information. First, there is `ADNIScanData`, which stores information about a single scan. Second, there is `ADNISubject`, which stores all the scans and metainfomration such as their ADNI ID, number of scans and scan dates. Third, and finally, `ADNIDataset`, which stores all the subjects form a given ADNI dataset. `ADNIDataset` is the most userfacing type and several helper functinos are defined for extracting useful information from within it. 

# Example

First, download the pre-analysed ADNI .csv data. . This can then be loaded into an `ADNIDataset`. 

```julia
julia> using ADNIDatasets, DataFrames, CSV

julia> data_df = CSV.read("/path/to/adni/data.csv", DataFrame)

julia> data = ADNIDataset(data_df)
```

By default this will load data with fieldnames from the FreeSurfer DKT atlas. If we wished to change this we can enter a second position argument containing a `Vector{String}` of names that correspond to column names in `data_df`.

There are additional keyword arguments that can be used. 

```julia
julia> data = ADNIDataset(data_df; min_scans = 1, max_scans = 3, reference_region="inferiorcerebellum")
```

`min_scans` and `max_scans` can be used to filter subejcts by the number of scans they have. By default `min_scans = 1` and `max_scans = Inf`. The reference region can be used to set which region is used for standardising PET data. By default the reference region is given by `reference_region="inferiocerebellum"`, which is commonly used for tau PET data. This can be changed depending on the tracer; for example, for amyloid-beta PET, ADNI supply a composite reference region and this can be set like so: 

```julia
julia> data = ADNIDataset(data_df; reference_region="COMPOSITE_REF")
```
