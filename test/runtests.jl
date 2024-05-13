using Pkg: Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using ADNIDatasets
using DataFrames, CSV
using Test

testpath = dirname(relpath(@__FILE__))
datapath = joinpath(testpath, "adni-test.csv")

datadf = CSV.read(datapath, DataFrame)

data_scans_3 = ADNIDataset(datadf; min_scans=3, qc=false)
data_scans_1 = ADNIDataset(datadf; min_scans=1, qc=false)
data_scans_2 = ADNIDataset(datadf; min_scans=2, max_scans=2, qc=false)

@testset "ADNIDatasets.jl" begin
    # test number of subjects are correct
    @test length(data_scans_3) == 2
    @test length(data_scans_1) == 3
    @test length(data_scans_2) == 1
    
    @test data_scans_3[1] isa ADNISubject
    suvr = get_suvr(data_scans_3, 1)
    vols = get_vol(data_scans_3, 1)
    suvr_ref = calc_suvr(data_scans_3, 1)
    initial_conditions = get_initial_conditions(data_scans_3, 1)

    # test types 
    @test suvr isa Matrix{Float64}
    @test vols isa Matrix{Float64}
    @test suvr_ref isa Matrix{Float64}
    @test initial_conditions isa Vector{Float64}

    # suvr and volume are same dimensions
    @test size(suvr) == size(vols)

    # test suvr vs normalised suvr
    @test suvr .* 2 == suvr_ref

    # test initial conditinos are correct
    @test length(initial_conditions) == 83
    @test initial_conditions == suvr_ref[:,1]

    # testing indexing and filtering
    _idx_subset = data_scans_1[[2, 3]]
    _filter_subset = filter(x -> length(x) > 2, data_scans_1)
    @test _idx_subset isa ADNIDataset
    @test get_id.(_idx_subset) == [2, 3]
    @test get_id.(_idx_subset) == get_id.(_filter_subset)
end