
@testset "Fit ACE" begin

    using ACE1pack, JuLIP

    include("artifacts.jl")
    test_train_set = joinpath(data_dir, "TiAl_tiny.xyz")
    json_params = joinpath(tests_files_dir, "fit_params.json")
    expected_errors_json = joinpath(tests_files_dir, "expected_fit_errors.json")
    json_params = joinpath(tests_files_dir, "fit_params.json")
    yaml_params = joinpath(tests_files_dir, "fit_params.yaml")

    @info("test full fit from script")

    species = [:Ti, :Al]
    r0 = 2.88 

    data = data_params(fname = test_train_set,
        energy_key = "energy",
        force_key = "force",
        virial_key = "virial")

    rpi_basis = basis_params(
        type = "rpi",
        species = species, 
        N = 3, 
        maxdeg = 6, 
        r0 = r0, 
        rad_basis = basis_params(
            type = "rad", 
            rcut = 5.0, 
            rin = 1.44,
            pin = 2))

    pair_basis = basis_params(
        type = "pair", 
        species = species, 
        maxdeg = 6,
        r0 = r0,
        rcut = 5.0,
        rin = 0.0,
        pcut = 2, # TODO: check if it should be 1 or 2?
        pin = 0)
    
    basis = Dict(
        "rpi_basis" => rpi_basis,
        "pair_basis" => pair_basis
    )

    solver = solver_params(solver = :lsqr)

    # symbols for species (e.g. :Ti) would work as well
    e0 = Dict("Ti" => -1586.0195, "Al" => -105.5954)

    weights = Dict(
        "default" => Dict("E" => 5.0, "F" => 1.0, "V" => 1.0),
        "FLD_TiAl" => Dict("E" => 5.0, "F" => 1.0, "V" => 1.0),
        "TiAl_T5000" => Dict("E" => 30.0, "F" => 1.0, "V" => 1.0))

    P = precon_params(type = "laplacian", rlap_scal = 3.0)

    params = fit_params(
        data = data,
        basis = basis,
        solver = solver,
        e0 = e0,
        weights = weights,
        P = P,
        ACE_fname = "")

    IP, lsqinfo = ACE1pack.fit_ace(params)

    errors = lsqinfo["errors"]

    expected_errors = load_dict(expected_errors_json)

    for error_type in keys(errors)
        for config_type in keys(errors[error_type])
            for property in keys(errors[error_type][config_type])
                @test errors[error_type][config_type][property] ≈  
                expected_errors[error_type][config_type][property]
            end
        end
    end

    @info("Test full fit from fit_params.json")

    params = load_dict(json_params)
    params["data"]["fname"] = test_train_set
    params["ACE_fname"] = ""
    params = fill_defaults!(params)
    IP, lsqinfo = fit_ace(params)

    errors = lsqinfo["errors"]

    for error_type in keys(errors)
        for config_type in keys(errors[error_type])
            for property in keys(errors[error_type][config_type])
                @test errors[error_type][config_type][property] ≈  
                expected_errors[error_type][config_type][property]
            end
        end
    end

    @info("Test full fit from fit_params.yaml")

    params = load_dict(yaml_params)
    params["data"]["fname"] = test_train_set
    params["ACE_fname"] = ""
    params = fill_defaults!(params)
    IP, lsqinfo = fit_ace(params)

    errors = lsqinfo["errors"]

    for error_type in keys(errors)
        for config_type in keys(errors[error_type])
            for property in keys(errors[error_type][config_type])
                @test errors[error_type][config_type][property] ≈  
                expected_errors[error_type][config_type][property]
            end
        end
    end

end