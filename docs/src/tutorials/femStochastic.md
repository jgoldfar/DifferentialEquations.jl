# Stochastic Finite Element Examples

For most problem types, we can additionally specify them as a stochastic
problem by giving the appropriate optional arguments to the constructor. These
arguments are a function σ which is the function multiplied to the Brownian
increments ``dW``, and stochastic, a boolean which we put as true for when the equation
is stochastic. Another keyword that is optional is noiseType which specifies the
type of noise (the "color" of the noise). By default this is Gaussian (Space-time)
White Noise.

The following examples show how to change the tutorial problems into stochastic problems.

## Finite Element Stochastic Poisson Equation

We can solve the same PDE as in the Poisson Tutorial except as the stochastic PDE,
 ``-Δu=f+gdW``, with additive space-time white noise by specifying the problem as:

```julia
"Example problem with deterministic solution: ``u(x,y)= sin(2π.*x).*cos(2π.*y)/(8π*π)``"
function poissonProblemExample_noisyWave()
  f(x) = sin(2π.*x[:,1]).*cos(2π.*x[:,2])
  sol(x) = sin(2π.*x[:,1]).*cos(2π.*x[:,2])/(8π*π)
  Du(x) = [cos(2*pi.*x[:,1]).*cos(2*pi.*x[:,2])./(4*pi) -sin(2π.*x[:,1]).*sin(2π.*x[:,2])./(4π)]
  σ(x) = 5 #Additive noise
  return(PoissonProblem(f,sol,Du,σ=σ))
end
```

using the same solving commands as shown in [femStochasticPoissonSolo.jl](https://github.com/ChrisRackauckas/DifferentialEquations.jl/tree/master/src/test/femStochasticPoissonSolo.jl).
This gives the following plot:

<img src="https://raw.githubusercontent.com/ChrisRackauckas/DifferentialEquations.jl/master/src/examples/introductionStochasticExample.png" width="750" align="middle" />

## Finite Element Stochastic Heat Equation

This will solve a nonlinear stochastic heat equation u_t=Δu+f+gdW with forcing function `f(u)=.5-u`,
noise function `g(u)=100u^2` and initial condition `u0=0`. We would expect this system
to rise towards the deterministic steady state `u=2` (but stay in mean a bit below
it due to 1st order "Milstein" effects), gaining more noise as it increases.
This is specified as follows:

```julia
"Example problem which starts with 0 and solves with ``f(u)=1-u/2`` with noise ``σ(u)=10u^2``"
function heatProblemExample_stochasticbirthdeath()
  f(u,x,t)  = ones(size(x,1)) - .5u
  u₀(x) = zeros(size(x,1))
  σ(u,x,t) = 1u.^2
  return(HeatProblem(u₀,f,σ=σ))
end
```

As shown in [femStochasticHeatAnimationTest.jl](https://github.com/ChrisRackauckas/DifferentialEquations.jl/tree/master/src/test/femStochasticHeatAnimationTest.jl),
we use the following code create an animation of the solution:

```julia
T = 5
Δx = 1//2^(3)
Δt = 1//2^(11)
femMesh = parabolic_squaremesh([0 1 0 1],Δx,Δt,T,"Neumann")
prob = heatProblemExample_stochasticbirthdeath()

sol = solve(femMesh::FEMmesh,prob::HeatProblem,alg="Euler",fullSave=true,solver="LU")
animate(sol::FEMSolution;zlim=(0,3),cbar=false)
```

<img src="https://raw.githubusercontent.com/ChrisRackauckas/DifferentialEquations.jl/master/src/examples/stochasticHeatAnimation.gif" width="750" align="middle" />
