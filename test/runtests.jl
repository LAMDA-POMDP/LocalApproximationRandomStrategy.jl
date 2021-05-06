using POMDPModels
using POMDPs
using POMDPModelTools
using StaticArrays
using Random
using DiscreteValueIteration
using GridInterpolations
using LocalFunctionApproximation
using LocalApproximationRandomStrategy
using POMDPLinter: show_requirements, get_requirements
using Test

@testset "all" begin

    println("Testing Requirements")
    gifa = LocalGIFunctionApproximator(RectangleGrid([0.0, 1.0], [0.0, 1.0]))
    @test_skip @requirements_info LocalApproximationRandomSolver(gifa) SimpleGridWorld()
    show_requirements(get_requirements(POMDPs.solve, (LocalApproximationRandomSolver(gifa), SimpleGridWorld())))
end
