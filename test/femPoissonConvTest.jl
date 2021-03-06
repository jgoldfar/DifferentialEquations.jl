######
##FEM Poisson Δx Convergence Tests
######
using DifferentialEquations,LaTeXStrings

Δxs = 1.//2.^(4:-1:2) # 4 for testing, use 7 for good graph
prob = poissonProblemExample_wave()

sim = testConvergence(Δxs::AbstractArray,prob::PoissonProblem)

#Plot Result
dxstring = L"\Delta x"
plot(sim,xguide=dxstring)

#Returns true if convergence is like Δx^2 in L2
sim.𝒪est["L2"]-2 <.1
