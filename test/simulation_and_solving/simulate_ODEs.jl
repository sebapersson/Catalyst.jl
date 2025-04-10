### Prepares Tests ###

# Fetch packages.
using Catalyst, OrdinaryDiffEqRosenbrock, OrdinaryDiffEqTsit5, OrdinaryDiffEqVerner, Test

# Sets stable rng number.
using StableRNGs
rng = StableRNG(12345)

# Fetch test functions and networks.
include("../test_functions.jl")
include("../test_networks.jl")

### Basic Solution Correctness ###

# Exponential decay, should be identical to the (known) analytical solution.
let
    exponential_decay = @reaction_network begin 
        d, X → ∅
    end

    for factor in [1e-2, 1e-1, 1e0, 1e1, 1e2]
        u0 = rnd_u0(exponential_decay, rng; factor)    
        t_stops = range(0.0, 100 / factor, length = 101)
        p = rnd_ps(exponential_decay, rng; factor)
        prob = ODEProblem(exponential_decay, u0, (0.0, t_stops[end]), p)

        sol = solve(prob, Vern7(), saveat = t_stops, abstol = 1e-10, reltol = 1e-10)
        analytic_sol = [u0[1][2] * exp(-p[1][2] * t) for t in t_stops]
        @test sol[:X] ≈ analytic_sol
    end
end

# Networks with know equilibrium.
let
    known_equilibrium = @reaction_network begin
        (k1, k2), X1 ↔ X2
        (k3, k4), X3 + X4 ↔ X5
        (k5, k6), 2X6 ↔ 3X7
        (k7, k8), ∅ ↔ X8
    end

    for factor in [1e-1, 1e0, 1e1]
        u0 = rnd_u0(known_equilibrium, rng; factor)    
        p = rnd_ps(known_equilibrium, rng; factor, min = 0.1)
        prob = ODEProblem(known_equilibrium, u0, (0.0, 100000.0), p)
        sol = solve(prob, Rosenbrock23())

        @test sol[:X1][end] / sol[:X2][end] ≈ prob.ps[:k2] / prob.ps[:k1]
        @test sol[:X3][end] * sol[:X4][end] / sol[:X5][end] ≈ prob.ps[:k4] / prob.ps[:k3]
        @test (sol[:X6][end]^2 / factorial(2)) / (sol[:X7][end]^3 / factorial(3)) ≈ prob.ps[:k6] / prob.ps[:k5]
        @test sol[:X8][end] ≈ prob.ps[:k7] / prob.ps[:k8]
    end
end

# Compares simulations generated through Catalyst with those generated by manually created functions.
let
    # Manually declares ODEs to compare Catalyst-generated simulations to.
    catalyst_networks = []
    manual_networks = []
    u0_syms = []
    ps_syms = []
    
    function real_functions_1(du, u, p, t)
        X1, X2, X3 = u
        p1, p2, p3, k1, k2, k3, k4, d1, d2, d3 = p
        du[1] = p1 + k1 * X2 - k2 * X1 * X3^2 / factorial(2) - k3 * X1 + k4 * X3 - d1 * X1
        du[2] = p2 - k1 * X2 + k2 * X1 * X3^2 / factorial(2) - d2 * X2
        du[3] = p3 + 2 * k1 * X2 - 2 * k2 * X1 * X3^2 / factorial(2) + k3 * X1 - k4 * X3 -
                d3 * X3
    end
    push!(catalyst_networks, reaction_networks_standard[1])
    push!(manual_networks, real_functions_1)
    push!(u0_syms, [:X1, :X2, :X3])
    push!(ps_syms, [:p1, :p2, :p3, :k1, :k2, :k3, :k4, :d1, :d2, :d3])

    function real_functions_2(du, u, p, t)
        X1, X2 = u
        v1, K1, v2, K2, d = p
        du[1] = v1 * K1 / (K1 + X2) - d * X1 * X2
        du[2] = v2 * X1 / (K2 + X1) - d * X1 * X2
    end
    push!(catalyst_networks, reaction_networks_standard[2])
    push!(manual_networks, real_functions_2)
    push!(u0_syms, [:X1, :X2])
    push!(ps_syms, [:v1, :K1, :v2, :K2, :d])

    function real_functions_3(du, u, p, t)
        X1, X2, X3 = u
        v1, v2, v3, K1, K2, K3, n1, n2, n3, d1, d2, d3 = p
        du[1] = v1 * K1^n1 / (K1^n1 + X3^n1) - d1 * X1
        du[2] = v2 * K2^n2 / (K2^n2 + X1^n2) - d2 * X2
        du[3] = v3 * K3^n3 / (K3^n3 + X2^n3) - d3 * X3
    end
    push!(catalyst_networks, reaction_networks_hill[2])
    push!(manual_networks, real_functions_3)
    push!(u0_syms, [:X1, :X2, :X3])
    push!(ps_syms, [:v1, :v2, :v3, :K1, :K2, :K3, :n1, :n2, :n3, :d1, :d2, :d3])

    function real_functions_4(du, u, p, t)
        X1, X2, X3 = u
        k1, k2, k3, k4, k5, k6 = p
        du[1] = -k1 * X1 + k2 * X2 + k5 * X3 - k6 * X1
        du[2] = -k3 * X2 + k4 * X3 + k1 * X1 - k2 * X2
        du[3] = -k5 * X3 + k6 * X1 + k3 * X2 - k4 * X3
    end
    push!(catalyst_networks, reaction_networks_conserved[1])
    push!(manual_networks, real_functions_4)
    push!(u0_syms, [:X1, :X2, :X3])
    push!(ps_syms, [:k1, :k2, :k3, :k4, :k5, :k6])

    function real_functions_5(du, u, p, t)
        X, Y, Z = u
        k1, k2, k3, k4 = p
        du[1] = k1 - k2 * log(12 + X) * X
        du[2] = k2 * log(12 + X) * X - k3 * log(3 + Y) * Y
        du[3] = k3 * log(3 + Y) * Y - log(5, 6 + k4) * Z
    end
    push!(catalyst_networks, reaction_networks_weird[2])
    push!(manual_networks, real_functions_5)
    push!(u0_syms, [:X, :Y, :Z])
    push!(ps_syms, [:k1, :k2, :k3, :k4])

    for (rn_catalyst, rn_manual, u0_sym, ps_sym) in zip(catalyst_networks, manual_networks, u0_syms, ps_syms)
        for factor in [1e-2, 1e-1, 1e0, 1e1]
            # Set input values.
            u0_1 = rnd_u0(rn_catalyst, rng; factor = factor)
            ps_1 = rnd_ps(rn_catalyst, rng; factor = factor)
            (nameof(rn_catalyst) == :rnh2) && (p_1 = rnd_ps_Int64(rn_catalyst, rng))
            u0_2 = map_to_vec(u0_1, u0_sym)
            ps_2 = map_to_vec(ps_1, ps_sym)

            # Check drift functions.
            dt = zeros(length(u0_1))
            rn_manual(dt, u0_2, ps_2, 0.0)
            @test dt ≈ f_eval(rn_catalyst, u0_1, ps_1, 0.0)

            # Compares that simulations are identical. 
            oprob_1 = ODEProblem(rn_catalyst, u0_1, (0.0, 100.0), ps_1)
            oprob_2 = ODEProblem(rn_manual, u0_2, (0.0, 100.0), ps_2)
            sol1 = solve(oprob_1, Rosenbrock23())
            sol2 = solve(oprob_2, Rosenbrock23())
            @test sol1[u0_sym] ≈ sol2.u
        end
    end
end

### Checks Simulations Don't Error ###
let
    for (i, rn) in enumerate(reaction_networks_all)
        for factor in [1e-1, 1e0, 1e1]
            u0 = rnd_u0(rn, rng; factor)
            # If parameter in exponent, this avoids potential (-small u)^(decimal) and large exponents.
            if in(i, [[11:20...]..., 34, 37, 42])
                ps = rnd_ps(rn, rng)
            else
                ps = rnd_ps(rn, rng; factor)
            end
            prob = ODEProblem(rn, u0, (0.0, 1.0), ps)
            @test SciMLBase.successful_retcode(solve(prob, Rosenbrock23()))
        end
    end
end

### Other Tests ###

# Checks that solution values have types consistent with their input types.
# Check that both float types are preserved in the solution (and problems), while integers are 
# promoted to floats.
# Checks that the time types are correct (`Float64` by default or possibly `Float32`).
let
    # Create model. Checks when input type is `Float64` the produced values are also `Float64`.
    rn = @reaction_network begin
        (k1,k2), X1 <--> X2
    end
    u0 = [:X1 => 1.0, :X2 => 3.0]
    ps = [:k1 => 2.0, :k2 => 3.0]
    oprob = ODEProblem(rn, u0, 1.0, ps)
    osol = solve(oprob, Tsit5())
    @test eltype(osol[:X1]) == eltype(osol[:X2]) == typeof(oprob[:X1]) == typeof(oprob[:X2]) == Float64
    @test eltype(osol.t) == typeof(oprob.tspan[1]) == typeof(oprob.tspan[2]) == Float64

    # Checks that `Int64` values are promoted to `Float64`. 
    u0 = [:X1 => 1, :X2 => 3]
    ps = [:k1 => 2, :k2 => 3]
    oprob = ODEProblem(rn, u0, 1, ps)
    osol = solve(oprob, Tsit5())
    @test eltype(osol[:X1]) == eltype(osol[:X2]) == typeof(oprob[:X1]) == typeof(oprob[:X2]) == Float64
    @test eltype(osol.t) == Float64

    # Checks when values are `Float32` (a valid type and should be preserved).
    u0 = [:X1 => 1.0f0, :X2 => 3.0f0]
    ps = [:k1 => 2.0f0, :k2 => 3.0f0]
    oprob = ODEProblem(rn, u0, 1.0f0, ps)
    osol = solve(oprob, Tsit5())
    @test_broken eltype(osol[:X1]) == eltype(osol[:X2]) == typeof(oprob[:X1]) == typeof(oprob[:X2]) == Float32 # https://github.com/SciML/ModelingToolkit.jl/issues/3553
    @test eltype(osol.t) == typeof(oprob.tspan[1]) == typeof(oprob.tspan[2]) == Float32
end

# Tests simulating a network without parameters.
let
    no_param_network = @reaction_network begin 
        (1.5, 2), ∅ ↔ X 
    end
    for factor in [1e0, 1e1, 1e2]
        u0 = rnd_u0(no_param_network, rng; factor)
        prob = ODEProblem(no_param_network, u0, (0.0, 1000.0))
        sol = solve(prob, Rosenbrock23())
        @test sol[:X][end] ≈ 1.5 / 2.0
    end
end

# Test solving with floating point stoichiometry.
let
    # Prepare model with/without Catalyst.
    function oderhs(du, u, p, t)
        du[1] = -2.5 * p[1] * u[1]^2.5
        du[2] = 3 * p[1] * u[1]^2.5
        nothing
    end
    rn = @reaction_network begin 
        k, 2.5 * A --> 3 * B 
    end
    u_1 = rnd_u0(rn, rng)
    p_1 = [:k => 1.0]
    u_2 = map_to_vec(u_1, [:A, :B])
    p_2 = map_to_vec(p_1, [:k])
    tspan = (0.0, 1.0)
    
    # Check equivalence.
    du1 = du2 = zeros(2) 
    oprob = ODEProblem(rn, u_1, tspan, p_1; combinatoric_ratelaws = false)
    oprob.f(du1, oprob.u0, oprob.p, 90.0)
    oderhs(du2, u_2, p_2, 0.0)
    @test du1 ≈ du2
end
