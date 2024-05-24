# Catalyst.jl for Reaction Network Modeling

Catalyst.jl is a symbolic modeling package for analysis and high performance
simulation of chemical reaction networks. Catalyst defines symbolic
[`ReactionSystem`](@ref)s, which can be created programmatically or easily
specified using Catalyst's domain specific language (DSL). Leveraging
[ModelingToolkit.jl](https://docs.sciml.ai/ModelingToolkit/stable/) and
[Symbolics.jl](https://docs.sciml.ai/Symbolics/stable/), Catalyst enables
large-scale simulations through auto-vectorization and parallelism. Symbolic
`ReactionSystem`s can be used to generate ModelingToolkit-based models, allowing
the easy simulation and parameter estimation of mass action ODE models, Chemical
Langevin SDE models, stochastic chemical kinetics jump process models, and more.
Generated models can be used with solvers throughout the broader
[SciML](https://sciml.ai) ecosystem, including higher level SciML packages (e.g.
for sensitivity analysis, parameter estimation, machine learning applications,
etc).

## Features
- A DSL provides a simple and readable format for manually specifying chemical
  reactions.
- Catalyst `ReactionSystem`s provide a symbolic representation of reaction networks,
  built on [ModelingToolkit.jl](https://docs.sciml.ai/ModelingToolkit/stable/) and
  [Symbolics.jl](https://docs.sciml.ai/Symbolics/stable/).
- Non-integer (e.g. `Float64`) stoichiometric coefficients are supported for generating
  ODE models, and symbolic expressions for stoichiometric coefficients are supported for
  all system types.
- The [Catalyst.jl API](@ref) provides functionality for extending networks,
  building networks programmatically, network analysis, and for composing multiple
  networks together.
- `ReactionSystem`s generated by the DSL can be converted to a variety of
  `ModelingToolkit.AbstractSystem`s, including symbolic ODE, SDE and jump process
  representations.
- Coupled differential and algebraic constraint equations can be included in
  Catalyst models, and are incorporated during conversion to ODEs or steady
  state equations.
- Conservation laws can be detected and applied to reduce system sizes, and
  generate non-singular Jacobians, during conversion to ODEs, SDEs, and steady
  state equations.
- By leveraging ModelingToolkit, users have a variety of options for generating
  optimized system representations to use in solvers. These include construction
  of dense or sparse Jacobians, multithreading or parallelization of generated
  derivative functions, automatic classification of reactions into optimized
  jump types for Gillespie type simulations, automatic construction of
  dependency graphs for jump systems, and more.
- Generated systems can be solved using any
  [DifferentialEquations.jl](https://docs.sciml.ai/DiffEqDocs/stable/)
  ODE/SDE/jump solver, and can be used within `EnsembleProblem`s for carrying
  out parallelized parameter sweeps and statistical sampling. Plot recipes
  are available for visualizing the solutions.
- [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl) symbolic
  expressions and Julia `Expr`s can be obtained for all rate laws and functions
  determining the deterministic and stochastic terms within resulting ODE, SDE
  or jump models.
- [Latexify](https://korsbo.github.io/Latexify.jl/stable/) can be used to generate
  LaTeX expressions corresponding to generated mathematical models or the
  underlying set of reactions.
- [Graphviz](https://graphviz.org/) can be used to generate and visualize
  reaction network graphs. (Reusing the Graphviz interface created in
  [Catlab.jl](https://algebraicjulia.github.io/Catlab.jl/stable/).)

## Packages Supporting Catalyst
- Catalyst [`ReactionSystem`](@ref)s can be imported from SBML files via
  [SBMLToolkit.jl](https://docs.sciml.ai/SBMLToolkit/stable/), and from BioNetGen .net
  files and various stoichiometric matrix network representations using
  [ReactionNetworkImporters.jl](https://docs.sciml.ai/ReactionNetworkImporters/stable/).
- [MomentClosure.jl](https://augustinas1.github.io/MomentClosure.jl/dev) allows
  generation of symbolic ModelingToolkit `ODESystem`s, representing moment
  closure approximations to moments of the Chemical Master Equation, from
  reaction networks defined in Catalyst.
- [FiniteStateProjection.jl](https://kaandocal.github.io/FiniteStateProjection.jl/dev/)
  allows the construction and numerical solution of Chemical Master Equation
  models from reaction networks defined in Catalyst.
- [DelaySSAToolkit.jl](https://palmtree2013.github.io/DelaySSAToolkit.jl/dev/) can
  augment Catalyst reaction network models with delays, and can simulate the
  resulting stochastic chemical kinetics with delays models.  
- [BondGraphs.jl](https://github.com/jedforrest/BondGraphs.jl) a package for
  constructing and analyzing bond graphs models, which can take Catalyst models as input.
- [PEtab.jl](https://github.com/sebapersson/PEtab.jl) a package that implements the PEtab format for fitting reaction network ODEs to data. Input can be provided either as SBML files or as Catalyst `ReactionSystem`s.
  

## Installation
Catalyst can be installed through the Julia package manager:

```julia
using Pkg
Pkg.add("Catalyst")
```

To solve Catalyst models and visualize solutions, it is also recommended to
install DifferentialEquations.jl and Plots.jl
```julia
Pkg.add("DifferentialEquations")
Pkg.add("Plots")
```

## Illustrative Example
Here is a simple example of generating, visualizing and solving an SIR ODE
model. We first define the SIR reaction model using Catalyst
```@example ind1
using Catalyst
rn = @reaction_network begin
    α, S + I --> 2I
    β, I --> R
end
```
Assuming [Graphviz](https://graphviz.org/) and is installed and *command line
accessible*, the network can be visualized using the [`Graph`](@ref) command
```julia
Graph(rn)
```
which in Jupyter notebooks will give the figure

![SIR Network Graph](assets/SIR_rn.svg)

To generate and solve a mass action ODE version of the model we use
```@example ind1
using DifferentialEquations
p     = [:α => .1/1000, :β => .01]
tspan = (0.0,250.0)
u0    = [:S => 999.0, :I => 1.0, :R => 0.0]
op    = ODEProblem(rn, u0, tspan, p)
sol   = solve(op, Tsit5())       # use Tsit5 ODE solver
```
which we can plot as
```@example ind1
using Plots
plot(sol, lw=2)
```

## Getting Help
Catalyst developers are active on the [Julia
Discourse](https://discourse.julialang.org/), and the [Julia
Slack's](https://julialang.slack.com) \#sciml-bridged and \#sciml-sysbio channels.
For bugs or feature requests [open an
issue](https://github.com/SciML/Catalyst.jl/issues).

## [Supporting and Citing Catalyst.jl](@id catalyst_citation)
The software in this ecosystem was developed as part of academic research. If you would like to help support it,
please star the repository as such metrics may help us secure funding in the future. If you use Catalyst as part
of your research, teaching, or other activities, we would be grateful if you could cite our work:
```
@article{CatalystPLOSCompBio2023,
    doi = {10.1371/journal.pcbi.1011530},
    author = {Loman, Torkel E. AND Ma, Yingbo AND Ilin, Vasily AND Gowda, Shashi AND Korsbo, Niklas AND Yewale, Nikhil AND Rackauckas, Chris AND Isaacson, Samuel A.},
    journal = {PLOS Computational Biology},
    publisher = {Public Library of Science},
    title = {Catalyst: Fast and flexible modeling of reaction networks},
    year = {2023},
    month = {10},
    volume = {19},
    url = {https://doi.org/10.1371/journal.pcbi.1011530},
    pages = {1-19},
    number = {10},
}
```

## Reproducibility
```@raw html
<details><summary>The documentation of this SciML package was built using these direct dependencies,</summary>
```
```@example
using Pkg # hide
Pkg.status() # hide
```
```@raw html
</details>
```
```@raw html
<details><summary>and using this machine and Julia version.</summary>
```
```@example
using InteractiveUtils # hide
versioninfo() # hide
```
```@raw html
</details>
```