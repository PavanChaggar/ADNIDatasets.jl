# ADNIDatasets

Package for working with data from the ALzheimer's Disease Neuroimaging Initaitive in Julia. 

ADNI is an excellent, open data initiative set up to share longitudinal, multimodal neuroimaging data relevant to Alzheimer's diseaes. However, data from ADNI is notoriously hard to work with. This package is an effort to make working with ADNI data easier. 

At present, the package mainly supports analysis of PET neuroimaging data that is analysed using the FreeSurfer DKT atlas, for example the myloid-beta AV45 and tau AV1451 tracers. 

This is a very lightweight packages that simply reads and reorganises tabular data from ADNI. 

# What Does the Package Do? 

There are three main types defined by `ADNIDatasets.jl`, each defining different levels of information. First, there is `ADNIScanData`, which stores information about a single scan. Second, there is `ADNISubject`, which stores all the scans and metainfomration such as their ADNI ID, number of scans and scan dates. Third, and finally, `ADNIDataset`, which stores all the subjects form a given ADNI dataset. `ADNIDataset` is the most userfacing type and several helper functinos are defined for extracting useful information from within it. 

# Example

First, download the pre-analysed ADNI .csv data. This can then be loaded into an `ADNIDataset`. 

```
filepath = /path/to/adni/data.csv

data = ADNIDataset(filepath)
```