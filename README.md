[![Build Status](https://travis-ci.org/LAMDA-POMDP/LocalApproximationRandomStrategy.jl.svg?branch=main)](https://travis-ci.org/JuliaPOMDP/LocalApproximationValueIteration.jl)
[![Coverage Status](https://coveralls.io/repos/github/LAMDA-POMDP/LocalApproximationRandomStrategy.jl/badge.svg?branch=main)](https://coveralls.io/github/JuliaPOMDP/LocalApproximationValueIteration.jl?branch=master)

# LocalApproximationRandomStrategy

This package implements the Local Approximation Random Policy for providing a lower bound of the optimal value of POMDPs.

## State Space Representation

For value function approximation, the solver depends on the [LocalFunctionApproximation.jl](https://github.com/sisl/LocalFunctionApproximation.jl)
package. The `LocalApproximationValueIteration` solver must be
initialized with an appropriate `LocalFunctionApproximator` object that approximates
the computed value function over the entire state space by either interpolation over a multi-dimensional grid discretization
of the state space, or by k-nearest-neighbor averaging
with a randomly drawn set of state space samples. The resulting policy uses this object to compute the action-value
function or the best action for any arbitrary state query.

A key operational requirement that the solver has from the MDP is that any state can be represented via an equivalent
real-valued vector. This is enforced by the two `convert_s` function requirements that convert an instance of
the MDP State type to a real-valued vector and vice versa. The signatures for these methods are:

```julia
convert_s(::Type{S},::V where V <: AbstractVector{Float64},::P)
convert_s(::Type{V} where V <: AbstractVector{Float64},::S,::P)
```

The user is required to implement the above two functions for the `State` type of their MDP problem model. An example of this
is shown in `test/runtests_versus_discrete_vi.jl` for the [GridWorld](https://github.com/JuliaPOMDP/POMDPModels.jl/blob/master/src/gridworld.jl) model.
:

```julia
function POMDPs.convert_s(::Type{V} where V <: AbstractVector{Float64}, s::GridWorldState, mdp::GridWorld)
    v = SVector{3,Float64}(s.x, s.y, convert(Float64,s.done))
    return v
end

function POMDPs.convert_s(::Type{GridWorldState}, v::AbstractVector{Float64}, mdp::GridWorld)
    s = GridWorldState(round(Int64, v[1]), round(Int64, v[2]), convert(Bool, v[3]))
end
```
Note that `SVector` must be imported through [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl)

## Usage

`POMDPs.jl` has a macro `@requirements_info` that determines the functions necessary to use some solver on some specific MDP model. As mentioned above, the
`LocalApproximationValueIteration` solver depends on a `LocalFunctionApproximator` object and so that object must first be created to invoke
the requirements of the solver accordingly (check [here](http://juliapomdp.github.io/POMDPs.jl/latest/requirements) for more information). From our running example in `test/runtests_versus_discrete_vi.jl`, a function approximation object that uses grid interpolation 
(`LocalGIFunctionApproximator`) is created, after the appropriate `RectangleGrid` is 
constructed (Look at [GridInterpolations.jl](https://github.com/sisl/GridInterpolations.jl/blob/master/src/GridInterpolations.jl/) for more details about this).

```julia
using POMDPs, POMDPModels
using GridInterpolations
using LocalFunctionApproximation
using LocalApproximationValueIteration

VERTICES_PER_AXIS = 10 # Controls the resolutions along the grid axis
grid = RectangleGrid(range(1, stop=100, length=VERTICES_PER_AXIS), range(1, stop=100, length=VERTICES_PER_AXIS), [0.0, 1.0]) # Create the interpolating grid
interp = LocalGIFunctionApproximator(grid)  # Create the local function approximator using the grid

@requirements_info LocalApproximationValueIterationSolver(interp) GridWorld() # Check if the solver requirements are met
```

The user should modify the above steps depending on the kind of interpolation and the necessary parameters they want. We have delegated this step to the user
as it is extremely problem and domain specific. Note that the solver supports both explicit and generative transition models for the MDP (more on that [here](http://juliapomdp.github.io/POMDPs.jl/latest/def_pomdp)).
The `.is_mdp_generative` and `.n_generative_samples` arguments of the `LocalApproximationValueIteration` solver should be set accordingly, and there are different
`@requirements` depending on which kind of model the MDP has.

Once all the necessary functions have been defined, the solver can be created.  A `GridWorld` MDP is defined with grid size 100 x 100 and appropriate reward states:

```julia
mdp = GridWorld(sx=100, sy=100, rs=rstates, rv=rvect)
```

Finally, the solver can be created using the function approximation object and other necessary parameters
(this model is explicit), and the MDP can be solved:

```julia
approx_solver = LocalApproximationRandomSolver(interp, verbose=true, max_iterations=1000, is_mdp_generative=false)
approx_policy = solve(approx_solver, mdp)
```

The API for querying the final policy object is identical to `DiscreteValueIteration`, i.e. the `action` and `value` functions can be called for the solved MDP:

```julia
v = value(approx_policy, s)
a = action(approx_policy, s)
```