#! format: off

### Fetch Packages and Set Global Variables ###
using Catalyst, ModelingToolkit, OrdinaryDiffEq, Plots
@variables t

### Run Tests ###

# Test creating networks with/without options.
let
    @reaction_network begin (k1, k2), A <--> B end
    @reaction_network begin
        @parameters k1 k2
        (k1, k2), A <--> B
    end
    @reaction_network begin
        @parameters k1 k2
        @species A(t) B(t)
        (k1, k2), A <--> B
    end
    @reaction_network begin
        @species A(t) B(t)
        (k1, k2), A <--> B
    end

    @reaction_network begin
        @parameters begin
            k1
            k2
        end
        (k1, k2), A <--> B
    end
    @reaction_network begin
        @species begin
            A(t)
            B(t)
        end
        (k1, k2), A <--> B
    end
    @reaction_network begin
        @parameters begin
            k1
            k2
        end
        @species begin
            A(t)
            B(t)
        end
        (k1, k2), A <--> B
    end

    n1 = @reaction_network rnname begin (k1, k2), A <--> B end
    n2 = @reaction_network rnname begin
        @parameters k1 k2
        (k1, k2), A <--> B
    end
    n3 = @reaction_network rnname begin
        @species A(t) B(t)
        (k1, k2), A <--> B
    end
    n4 = @reaction_network rnname begin
        @parameters k1 k2
        @species A(t) B(t)
        (k1, k2), A <--> B
    end
    n5 = @reaction_network rnname begin
        (k1, k2), A <--> B
        @parameters k1 k2
    end
    n6 = @reaction_network rnname begin
        (k1, k2), A <--> B
        @species A(t) B(t)
    end
    n7 = @reaction_network rnname begin
        (k1, k2), A <--> B
        @parameters k1 k2
        @species A(t) B(t)
    end
    n8 = @reaction_network rnname begin
        @parameters begin
            k1
            k2
        end
        (k1, k2), A <--> B
    end
    n9 = @reaction_network rnname begin
        @species begin
            A(t)
            B(t)
        end
        (k1, k2), A <--> B
    end
    n10 = @reaction_network rnname begin
        @parameters begin
            k1
            k2
        end
        @species begin
            A(t)
            B(t)
        end
        (k1, k2), A <--> B
    end
    @test all(==(n1), (n2, n3, n4, n5, n6, n7, n8, n9, n10))
end

# Tests that when either @species or @parameters is given, the other is infered properly.
let
    rn1 = @reaction_network begin
        k*X, A + B --> 0
    end
    @test issetequal(species(rn1), @species A(t) B(t))
    @test issetequal(parameters(rn1), @parameters k X)

    rn2 = @reaction_network begin
        @species A(t) B(t) X(t)
        k*X, A + B --> 0
    end
    @test issetequal(species(rn2), @species A(t) B(t) X(t))
    @test issetequal(parameters(rn2), @parameters k)

    rn3 = @reaction_network begin
        @parameters k
        k*X, A + B --> 0
    end
    @test issetequal(species(rn3), @species A(t) B(t))
    @test issetequal(parameters(rn3), @parameters k X)

    rn4 = @reaction_network begin
        @species A(t) B(t) X(t)
        @parameters k
        k*X, A + B --> 0
    end
    @test issetequal(species(rn4), @species A(t) B(t) X(t))
    @test issetequal(parameters(rn4), @parameters k)

    rn5 = @reaction_network begin
        @parameters k B [isconstantspecies=true]
        k*X, A + B --> 0
    end
    @test issetequal(species(rn5), @species A(t))
    @test issetequal(parameters(rn5), @parameters k B X)
end

# Test inferring with stoichiometry symbols and interpolation.
let
    @parameters k g h gg X y [isconstantspecies = true]
    t = Catalyst.DEFAULT_IV
    @species A(t) B(t) BB(t) C(t)

    rni = @reaction_network inferred begin
        $k*X, $y + g*A + h*($gg)*B + $BB * C --> k*C
    end
    @test issetequal(species(rni), [A, B, BB, C])
    @test issetequal(parameters(rni), [k, g, h, gg, X, y])

    rnii = @reaction_network inferred begin
        @species BB(t)
        @parameters y [isconstantspecies = true]
        k*X, y + g*A + h*($gg)*B + BB * C --> k*C
    end
    @test rnii == rni
end

# Tests that when some species or parameters are left out, the others are set properly.
let
    rn6 = @reaction_network begin
        @species A(t)
        k*X, A + B --> 0
    end
    @test issetequal(species(rn6), @species A(t) B(t))
    @test issetequal(parameters(rn6), @parameters k X)

    rn7 = @reaction_network begin
        @species A(t) X(t)
        k*X, A + B --> 0
    end
    @test issetequal(species(rn7), @species A(t) X(t) B(t))
    @test issetequal(parameters(rn7), @parameters k)

    rn7 = @reaction_network begin
        @parameters B [isconstantspecies=true]
        k*X, A + B --> 0
    end
    @test issetequal(species(rn7), @species A(t))
    @test issetequal(parameters(rn7), @parameters B k X)

    rn8 = @reaction_network begin
        @parameters B [isconstantspecies=true] k
        k*X, A + B --> 0
    end
    @test issetequal(species(rn8), @species A(t))
    @test issetequal(parameters(rn8), @parameters B k X)

    rn9 = @reaction_network begin
        @parameters k1 X1
        @species A1(t) B1(t)
        k1*X1, A1 + B1 --> 0
        k2*X2, A2 + B2 --> 0
    end
    @test issetequal(species(rn9), @species A1(t) B1(t) A2(t) B2(t))
    @test issetequal(parameters(rn9), @parameters k1 X1 k2 X2)

    rn10 = @reaction_network begin
        @parameters k1 X2 B2 [isconstantspecies=true]
        @species A1(t) X1(t)
        k1*X1, A1 + B1 --> 0
        k2*X2, A2 + B2 --> 0
    end
    @test issetequal(species(rn10), @species A1(t) X1(t) B1(t) A2(t))
    @test issetequal(parameters(rn10), @parameters k1 X2 B2 k2)

    rn11 = @reaction_network begin
        @parameters k1 k2
        @species X1(t)
        k1*X1, A1 + B1 --> 0
        k2*X2, A2 + B2 --> 0
    end
    @test issetequal(species(rn11), @species X1(t) A1(t) A2(t) B1(t) B2(t))
    @test issetequal(parameters(rn11), @parameters k1 k2 X2)
end

##Checks that some created networks are identical.
let
    rn12 = @reaction_network rnname begin (k1, k2), A <--> B end
    rn13 = @reaction_network rnname begin
        @parameters k1 k2
        (k1, k2), A <--> B
    end
    rn14 = @reaction_network rnname begin
        @species A(t) B(t)
        (k1, k2), A <--> B
    end
    rn15 = @reaction_network rnname begin
        @parameters k1 k2
        @species A(t) B(t)
        (k1, k2), A <--> B
    end
    @test all(==(rn12), (rn13, rn14, rn15))
end

# Checks that the rights things are put in vectors.
let
    rn18 = @reaction_network rnname begin
        @parameters p d1 d2
        @species A(t) B(t)
        p, 0 --> A
        1, A --> B
        (d1, d2), (A, B) --> 0
    end
    rn19 = @reaction_network rnname begin
        p, 0 --> A
        1, A --> B
        (d1, d2), (A, B) --> 0
    end
    @test rn18 == rn19

    @parameters p d1 d2
    @species A(t) B(t)
    @test isequal(parameters(rn18)[1], p)
    @test isequal(parameters(rn18)[2], d1)
    @test isequal(parameters(rn18)[3], d2)
    @test isequal(species(rn18)[1], A)
    @test isequal(species(rn18)[2], B)

    rn20 = @reaction_network rnname begin
        @species X(t)
        @parameters S
        mm(X,v,K), 0 --> Y
        (k1,k2), 2Y <--> Y2
        d*Y, S*(Y2+Y) --> 0
    end
    rn21 = @reaction_network rnname begin
        @species X(t) Y(t) Y2(t)
        @parameters v K k1 k2 d S
        mm(X,v,K), 0 --> Y
        (k1,k2), 2Y <--> Y2
        d*Y, S*(Y2+Y) --> 0
    end
    rn22 = @reaction_network rnname begin
        @species X(t) Y2(t)
        @parameters d k1
        mm(X,v,K), 0 --> Y
        (k1,k2), 2Y <--> Y2
        d*Y, S*(Y2+Y) --> 0
    end
    @test all(==(rn20), (rn21, rn22))
    @parameters v K k1 k2 d S
    @species X(t) Y(t) Y2(t)
    @test issetequal(parameters(rn22),[v K k1 k2 d S])
    @test issetequal(species(rn22), [X Y Y2])
end

# Tests that defaults work.
let
    rn26 = @reaction_network rnname begin
        @parameters p=1.0 d1 d2=5
        @species A(t) B(t)=4
        p, 0 --> A
        1, A --> B
        (d1, d2), (A, B) --> 0
    end

    rn27 = @reaction_network rnname begin
    @parameters p1=1.0 p2=2.0 k1=4.0 k2=5.0 v=8.0 K=9.0 n=3 d=10.0
    @species X(t)=4.0 Y(t)=3.0 X2Y(t)=2.0 Z(t)=1.0
        (p1,p2), 0 --> (X,Y)
        (k1,k2), 2X + Y --> X2Y
        hill(X2Y,v,K,n), 0 --> Z
        d, (X,Y,X2Y,Z) --> 0
    end
    u0_27 = []
    p_27 = []

    rn28 = @reaction_network rnname begin
    @parameters p1=1.0 p2 k1=4.0 k2 v=8.0 K n=3 d
    @species X(t)=4.0 Y(t) X2Y(t) Z(t)=1.0
        (p1,p2), 0 --> (X,Y)
        (k1,k2), 2X + Y --> X2Y
        hill(X2Y,v,K,n), 0 --> Z
        d, (X,Y,X2Y,Z) --> 0
    end
    u0_28 = symmap_to_varmap(rn28, [:p2=>2.0, :k2=>5.0, :K=>9.0, :d=>10.0])
    p_28 = symmap_to_varmap(rn28, [:Y=>3.0, :X2Y=>2.0])
    defs28 = Dict(Iterators.flatten((u0_28, p_28)))

    rn29 = @reaction_network rnname begin
    @parameters p1 p2 k1 k2 v K n d
    @species X(t) Y(t) X2Y(t) Z(t)
        (p1,p2), 0 --> (X,Y)
        (k1,k2), 2X + Y --> X2Y
        hill(X2Y,v,K,n), 0 --> Z
        d, (X,Y,X2Y,Z) --> 0
    end
    u0_29 = symmap_to_varmap(rn29, [:p1=>1.0, :p2=>2.0, :k1=>4.0, :k2=>5.0, :v=>8.0, :K=>9.0, :n=>3, :d=>10.0])
    p_29 = symmap_to_varmap(rn29, [:X=>4.0, :Y=>3.0, :X2Y=>2.0, :Z=>1.0])
    defs29 = Dict(Iterators.flatten((u0_29, p_29)))

    @test ModelingToolkit.defaults(rn27) == defs29
    @test merge(ModelingToolkit.defaults(rn28), defs28) == ModelingToolkit.defaults(rn27)
end

### Observables ###

# Test basic functionality.
# Tests various types of indexing.
let 
    rn = @reaction_network begin
        @observables begin
            X ~ Xi + Xa
            Y ~ Y1 + Y2
        end
        (p,d), 0 <--> Xi
        (k1,k2), Xi <--> Xa
        (k3,k4), Y1 <--> Y2
    end
    @unpack X, Xi, Xa, Y, Y1, Y2, p, d, k1, k2, k3, k4 = rn

    # Test that ReactionSystem have the correct properties.
    @test length(species(rn)) == 4
    @test length(states(rn)) == 4
    @test length(observed(rn)) == 2
    @test length(equations(rn)) == 6

    @test isequal(observed(rn)[1], X ~ Xi + Xa)
    @test isequal(observed(rn)[2], Y ~ Y1 + Y2)

    # Tests correct indexing of solution.
    u0 = [Xi => 0.0, Xa => 0.0, Y1 => 1.0, Y2 => 2.0]
    ps = [p => 1.0, d => 0.2, k1 => 1.5, k2 => 1.5, k3 => 5.0, k4 => 5.0]

    oprob = ODEProblem(rn, u0, (0.0, 1000.0), ps)
    sol = solve(oprob, Tsit5())
    @test sol[X][end] ≈ 10.0
    @test sol[Y][end] ≈ 3.0
    @test sol[rn.X][end] ≈ 10.0
    @test sol[rn.Y][end] ≈ 3.0
    @test sol[:X][end] ≈ 10.0
    @test sol[:Y][end] ≈ 3.0

    # Tests that observables can be used for plot indexing.
    @test plot(sol; idxs=X).series_list[1].plotattributes[:y][end] ≈ 10.0
    @test plot(sol; idxs=rn.X).series_list[1].plotattributes[:y][end] ≈ 10.0
    @test plot(sol; idxs=:X).series_list[1].plotattributes[:y][end] ≈ 10.0
    @test plot(sol; idxs=[X, Y]).series_list[2].plotattributes[:y][end] ≈ 3.0
    @test plot(sol; idxs=[rn.X, rn.Y]).series_list[2].plotattributes[:y][end] ≈ 3.0
    @test plot(sol; idxs=[:X, :Y]).series_list[2].plotattributes[:y][end] ≈ 3.0
end

# Compares programmatic and DSL system with observables.
let
    # Model declarations.
    rn_dsl = @reaction_network begin
        @observables begin
            X ~ x + 2x2y
            Y ~ y + x2y
        end
        k, 0 --> (x, y)
        (kB, kD), 2x + y <--> x2y
        d, (x,y,x2y) --> 0
    end

    @variables t X(t) Y(t)
    @species x(t), y(t), x2y(t)
    @parameters k kB kD d
    r1 = Reaction(k, nothing, [x], nothing, [1])
    r2 = Reaction(k, nothing, [y], nothing, [1])
    r3 = Reaction(kB, [x, y], [x2y], [2, 1], [1])
    r4 = Reaction(kD, [x2y], [x, y], [1], [2, 1])
    r5 = Reaction(d, [x], nothing, [1], nothing)
    r6 = Reaction(d, [y], nothing, [1], nothing)
    r7 = Reaction(d, [x2y], nothing, [1], nothing)
    obs_eqs = [X ~ x + 2x2y, Y ~ y + x2y]
    rn_prog = ReactionSystem([r1, r2, r3, r4, r5, r6, r7], t, [x, y, x2y], [k, kB, kD, d]; observed = obs_eqs)

    # Make simulations.
    u0 = [x => 1.0, y => 0.5, x2y => 0.0]
    tspan = (0.0, 15.0)
    ps = [k => 1.0, kD => 0.1, kB => 0.5, d => 5.0]
    oprob_dsl = ODEProblem(rn_dsl, u0, tspan, ps)
    oprob_prog = ODEProblem(rn_prog, u0, tspan, ps)

    sol_dsl = solve(oprob_dsl, Tsit5(); saveat=0.1)
    sol_prog = solve(oprob_prog, Tsit5(); saveat=0.1)

    # Tests observables equal in both cases.
    @test oprob_dsl[:X] == oprob_prog[:X]
    @test oprob_dsl[:Y] == oprob_prog[:Y]
    @test sol_dsl[:X] == sol_prog[:X]
    @test sol_dsl[:Y] == sol_prog[:Y]
end

# Tests for complicated observable formula.
# Tests using a single observable (without begin/end statement).
# Tests using observable component not part of reaction.
# Tests using parameters in observables formula.
let 
    rn = @reaction_network begin
        @parameters op_1 op_2
        @species X4(t)
        @observables X ~ X1^2 + op_1*(X2 + 2X3) + X1*X4/op_2 + p        
        (p,d), 0 <--> X1
        (k1,k2), X1 <--> X2
        (k3,k4), X2 <--> X3
    end
    
    u0 = Dict([:X1 => 1.0, :X2 => 2.0, :X3 => 3.0, :X4 => 4.0])
    ps = Dict([:p => 1.0, :d => 0.2, :k1 => 1.5, :k2 => 1.5, :k3 => 5.0, :k4 => 5.0, :op_1 => 1.5, :op_2 => 1.5])

    oprob = ODEProblem(rn, u0, (0.0, 1000.0), ps)
    sol = solve(oprob, Tsit5())

    @test sol[:X][1] == u0[:X1]^2 + ps[:op_1]*(u0[:X2] + 2*u0[:X3]) + u0[:X1]*u0[:X4]/ps[:op_2] + ps[:p]  
end

# Checks that ivs are correctly found
let
    rn = @reaction_network begin
        @ivs t x y
        @species V1(t) V2(t,x) V3(t, y) W1(t) W2(t, y)
        @observables begin
            V ~ V1 + 2V2 + 3V3
            W ~ W1 + W2
        end
    end
    V,W = getfield.(observed(rn), :lhs)
    @test isequal(arguments(ModelingToolkit.unwrap(V)), [rn.iv, rn.sivs[1], rn.sivs[2]])
    @test isequal(arguments(ModelingToolkit.unwrap(W)), [rn.iv, rn.sivs[2]])
end

# Declares observables implicitly/explicitly.
let 
    # Basic case.
    rn1 = @reaction_network rn_observed begin
        @observables X ~ X1 + X2
        k, 0 --> X1 + X2
    end
    rn2 = @reaction_network rn_observed begin
        @variables X(t)
        @observables X ~ X1 + X2
        k, 0 --> X1 + X2
    end
    @test isequal(rn1, rn2)

    # Case with metadata.
    rn3 = @reaction_network rn_observed begin
        @observables (X,  [bounds=(0.0, 10.0)]) ~ X1 + X2
        k, 0 --> X1 + X2
    end
    rn4 = @reaction_network rn_observed begin
        @variables X(t) [bounds=(0.0, 10.0)]
        @observables X ~ X1 + X2
        k, 0 --> X1 + X2
    end
    @test isequal(rn3, rn4)
end

# Tests various erroneous declarations throw errors.
let 
    # Independent variable in @compounds.
    @test_throws Exception @eval @reaction_network rn_observed begin
        @observables X(t) ~ X1 + X2
        k, 0 --> X1 + X2
    end

    # System with observable in observable formula.
    @test_throws Exception @eval @reaction_network begin
        @observables begin
            X ~ X1 + X2
            X2 ~ 2X
        end
        (p,d), 0 <--> X1 + X2
    end

    # Multiple @compounds options
    @test_throws Exception @eval @reaction_network rn_observed begin
        @observables X ~ X1 + X2
        @observables Y ~ Y1 + Y2
        k, 0 --> X1 + X2
        k, 0 --> Y1 + Y2
    end
    @test_throws Exception @eval @reaction_network begin
        @observables begin
            X ~ X1 + X2
        end
        @observables begin
            X2 ~ 2(X1 + X2)
        end
        (p,d), 0 <--> X1 + X2
    end

    # Default value for compound.
    @test_throws Exception @eval @reaction_network rn_observed begin
        @observables (X = 1.0) ~ X1 + X2
        k, 0 --> X1 + X2
    end

    # Forbidden symbols as observable names.
    @test_throws Exception @eval @reaction_network rn_observed begin
        @observables t ~ t1 + t2
        k, 0 --> t1 + t2
    end
    @test_throws Exception @eval @reaction_network rn_observed begin
        @observables im ~ i + m
        k, 0 --> i + m
    end

    # Non-trivial observables expression.
    @test_throws Exception @eval @reaction_network rn_observed begin
        @observables X - X1 ~ X2
        k, 0 --> X1 + X2
    end

    # Occurrence of undeclared dependants.
    @test_throws Exception @eval @reaction_network rn_observed begin
        @observables X ~ X1 + X2
        k, 0 --> X1
    end
end