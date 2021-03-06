# DifferentialEquations.jl

[![Join the chat at https://gitter.im/ChrisRackauckas/DifferentialEquations.jl](https://badges.gitter.im/ChrisRackauckas/DifferentialEquations.jl.svg)](https://gitter.im/ChrisRackauckas/DifferentialEquations.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status](https://travis-ci.org/ChrisRackauckas/DifferentialEquations.jl.svg?branch=master)](https://travis-ci.org/ChrisRackauckas/DifferentialEquations.jl) [![Build status](https://ci.appveyor.com/api/projects/status/032otj4kh462tq2l/branch/master?svg=true)](https://ci.appveyor.com/project/ChrisRackauckas/differentialequations-jl/branch/master) [![Coverage Status](https://coveralls.io/repos/github/ChrisRackauckas/DifferentialEquations.jl/badge.svg?branch=master)](https://coveralls.io/github/ChrisRackauckas/DifferentialEquations.jl?branch=master) [![codecov](https://codecov.io/gh/ChrisRackauckas/DifferentialEquations.jl/coverage.svg?branch=master)](https://codecov.io/gh/ChrisRackauckas/DifferentialEquations.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://ChrisRackauckas.github.io/DifferentialEquations.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://ChrisRackauckas.github.io/DifferentialEquations.jl/latest)

This is a package for solving numerically solving differential equations in Julia by Chris Rackauckas. The purpose of this package is to supply efficient Julia implementations of solvers for various differential equations. Equations within the realm of this package include ordinary differential equations (ODEs), stochastic ordinary differential equations (SODEs or SDEs), stochastic partial differential equations (SPDEs), partial differential equations (with both finite difference and finite element methods), and differential delay equations.

All of the algorithms are thoroughly tested to ensure accuracy. Convergence tests  are included in the [test/](test/) folder if you're interested.
The algorithms were also tested to show correctness with nontrivial behavior such as Turing morphogenesis. If you find any equation where there seems
to be an error, please open an issue.

This package is for efficient and parallel implementations of research-level algorithms, many of which are quite recent. These algorithms aim to be optimized for HPC applications, including the use of GPUs, Xeon Phis, and multi-node parallelism. With the easy to use plot/convergence testing algorithms, this package also provides a good sandbox for developing novel numerical schemes. Since this package is designed for long computations, one of the features of this package is the existence of tools for inspecting a long calculation. These include optional printing and, if the user is using Juno, a progress meter (with time estimates once implemented on Juno's end).

If you have any questions, or just want to chat about solvers/using the package, please feel free to message me in the Gitter channel. For bug reports, feature requests, etc., please submit an issue.

## Note on Compatibility

The v0.0.3 release is the last release targetting Julia v0.4. Future development will be targeting Julia v0.5 and does not guerentee backwards compatibility with v0.4. That said, most of the code should work. The only breaking change may be within the dependency ChunkedArrays which will require a very different method of parallelism in future versions, and thus one should make sure to use the tag for v0.4 in ChunkedArrays.

# Using the package

To install the package, use the following command inside the Julia REPL:
```julia
Pkg.add("DifferentialEquations")
```

For all of the latest features, switch to the master branch via:

```julia
Pkg.checkout("DifferentialEquations")
```

To load the package, use the command

```julia
using DifferentialEquations
```

To understand the package in more detail, check out the examples codes in [test/](test/).
Note that for many of the examples in the test folder, you may wish to run them at
lower Δx or Δt. These values were taken to be large in order make unit tests run faster!
For the most up to date information, please contact me [via the repository Gitter](https://gitter.im/ChrisRackauckas/DifferentialEquations.jl)
or [read the latest documentation](http://chrisrackauckas.github.io/DifferentialEquations.jl/latest/)

## ODE Example

In this example we will solve the equation

```math
du/dt = f(u,t)
```

where ``f(u,t)=αu``. We know via Calculus that the solution to this equation is
``u(t)=u₀*exp(α*t)``. To solve this numerically, we define a problem type by
giving it the equation and the initial condition:

```julia
"""Example problem with solution ``u(t)=u₀*exp(α*t)``"""
function linearODEExample(;α=1,u₀=1/2)
  f(u,t) = α*u
  sol(u₀,t) = u₀*exp(α*t)
  return(ODEProblem(f,u₀,sol=sol))
end
prob = linearODEExample()
```

Notice that for this equation the solution is known so we passed it to the ODEProblem.
The package can use this information to calculate errors, test convergence, and make
plots. However, this is optional and simply for demonstration purposes.

Then we setup some parameters:

```julia
Δt = 1//2^(4) #The initial timestepping size. It will automatically assigned if not given.
tspan = [0,1] # The timespan. This is the default if not given.
```

We then send these items to the solver.

```julia
sol =solve(prob::ODEProblem,tspan,Δt=Δt,fullSave=true,alg="Euler")
```

Plotting commands are provided via a recipe to Plots.jl. To plot the solution
object, simply call plot:

```julia
plot(sol,plottrue=true)
#Use Plots.jl's gui() command to display the plot.
Plots.gui()
#Shown is both the true solution and the approximated solution.
```

## SDE Example

In this example we will solve the equation

```math
du = f(u,t)dt + Σσᵢ(u,t)dWⁱ
```

where ``f(u,t)=αu`` and ``σ(u,t)=βu``. We know via Stochastic Calculus that the
solution to this equation is ``u(t,W)=u₀*exp((α-(β^2)/2)*t+β*W)``. To solve this
numerically, we define a problem type by giving it the equation and the initial
condition:

```julia
"""Example problem with solution ``u(t,W)=u₀*exp((α-(β^2)/2)*t+β*W)``"""
function linearSDEExample(;α=1,β=1,u₀=1/2)
  f(u,t) = α*u
  σ(u,t) = β*u
  sol(u₀,t,W) = u₀*exp((α-(β^2)/2)*t+β*W)
  return(SDEProblem(f,σ,u₀,sol=sol))
end
prob = linearSDEExample()
Δt = 1//2^(4) #The initial timestepping size. It will automatically assigned if not given.
tspan = [0,1] # The timespan. This is the default if not given.
```

and then we pass this information to the solver and plot:

```julia
#We can solve using the classic Euler-Maruyama algorithm:
sol =solve(prob::SDEProblem,tspan,Δt=Δt,fullSave=true,alg="EM")
plot(sol,plottrue=true)
#Use Plots.jl's gui() command to display the plot.
gui()
```

We can choose a very state of the art high Strong order solver as well:

```julia
#We can choose a better method as follows:
sol =solve(prob::SDEProblem,tspan,Δt=Δt,fullSave=true,alg="SRI")
plot(sol,plottrue=true)
gui()
```

## Poisson Equation Finite Element Method Example

In this example we will solve the Poisson Equation Δu=f. The code for this example can be found in [test/introductionExample.jl](test/introductionExample.jl). For our example, we will take the linear equation where `f(x) = sin(2π.*x[:,1]).*cos(2π.*x[:,2])`. For this equation we know that solution is `u(x,y,t)= sin(2π.*x).*cos(2π.*y)/(8π*π)` with gradient `Du(x,y) = [cos(2*pi.*x).*cos(2*pi.*y)./(4*pi) -sin(2π.*x).*sin(2π.*y)./(4π)]`. Thus, we define a PoissonProblem as follows:

```julia
"Example problem with solution: ``u(x,y)= sin(2π.*x).*cos(2π.*y)/(8π*π)``"
function poissonProblemExample_wave()
  f(x) = sin(2π.*x[:,1]).*cos(2π.*x[:,2])
  sol(x) = sin(2π.*x[:,1]).*cos(2π.*x[:,2])/(8π*π)
  Du(x) = [cos(2*pi.*x[:,1]).*cos(2*pi.*x[:,2])./(4*pi) -sin(2π.*x[:,1]).*sin(2π.*x[:,2])./(4π)]
  return(PoissonProblem(f,sol,Du))
end
prob = poissonProblemExample_wave()
```

Note that in this case since the solution is known, the Dirichlet boundary condition `gD` is automatically set to match the true solution. If the solution is unknown, one would instead define a PoissonProblem via `PoissonProblem(f,gD=gD,gN=gN)` where `gD` are the Dirichlet boundary conditions and `gN` are the Neumann boundary conditions. If the boundary conditions are unspecified, they default to zero. The code for other example problems can be found in [src/examples/exampleProblems.jl](src/examples/exampleProblems.jl).

To solve the problem we specified, we first have to generate a mesh. Here we will simply generate a mesh of triangles on the square [0,1]x[0,1] with Δx=2^(-5). To do so, we use the code:

```julia
Δx = 1//2^(5)
femMesh = notime_squaremesh([0 1 0 1],Δx,"Dirichlet")
```

Note that by specifying "Dirichlet" our boundary conditions is set on all boundaries to Dirichlet. This gives an FEMmesh object which stores a finite element mesh in the same layout as [iFEM](http://www.math.uci.edu/~chenlong/programming.html). Notice this code shows that the package supports the use of rationals in meshes. Other numbers such as floating point and integers can be used as well. Finally, to solve the equation we use

```julia
sol = solve(femMesh::FEMmesh,prob::PoissonProblem,solver="GMRES")
```

solve takes in a mesh and a PoissonProblem and uses the solver to compute the solution. Here the solver was chosen to be GMRES. Other solvers can be found in the documentation. This returns a FEMSolution object which holds data about the solution, such as the solution values (u), the true solution (uTrue), error estimates, etc. To plot the solution, we use the command

```julia
plot(sol,plottrue=true)
```

This gives us the following plot:

<img src="/src/examples/introductionExample.png" width="750" align="middle"  />

### Finite Element Stochastic Heat Equation

The last equation we will solve in this introductory example will be a nonlinear stochastic heat equation u_t=Δu+f+gdW with forcing function `f(u)=.5-u`, noise function `g(u)=100u^2` and
initial condition `u0=0`. We would expect this system to rise towards the deterministic steady state `u=2` (but stay in mean a bit below it due to 1st order "Milstein" effects), gaining more noise as it increases. This is specified as follows:

```julia
"Example problem which starts with 0 and solves with f(u)=1-.5u"
function heatProblemExample_stochasticbirthdeath()
  f(u,x,t)  = ones(size(x,1)) - .5u
  u₀(x) = zeros(size(x,1))
  σ(u,x,t) = 100u.^2
  return(HeatProblem(u₀,f,σ=σ,stochastic=stochastic))
end
```

As shown in [femStochasticHeatAnimationTest.jl](/test/femStochasticHeatAnimationTest.jl), we use the following code create an animation of the solution:

```julia
T = 5
Δx = 1//2^(4)
Δt = 1//2^(12)
femMesh = parabolic_squaremesh([0 1 0 1],Δx,Δt,T,"Neumann")
pdeProb = heatProblemExample_stochasticbirthdeath()

res = fem_solveheat(femMesh::FEMmesh,pdeProb::HeatProblem,alg="Euler",fullSave=true)
solplot_animation(res::FEMSolution;zlim=(0,2),cbar=false)
```

<img src="/src/examples/stochasticHeatAnimation.gif" width="750" align="middle" />

# Supported Equations

For PDEs, one can optionally specify a noise equation. The solvers currently have
stochastic variants for handling Gaussian Space-time white noise SPDEs.

* ODEs
* SODEs
* (Stochastic) PDEs
    * Linear Poisson Equation
    * Semi-linear Poisson Equation
    * Linear Heat Equation
    * Semi-linear Heat Equation (aka Reaction-Diffusion Equation)

# Implemented Solvers

For PDEs, [method] denotes an additional version for handling stochastic partial
differential equations. The implemented methods for solving implicit equations
are denoted by the implicit solvers at the bottom. Currently, nonlinear solving
techniques are provided by [NLSolve.jl](https://github.com/EconForge/NLsolve.jl).

SDE solvers and ODE solvers take in general sized inputs. For example, if u₀ is
a matrix (and your problem functions are designed to work with matrices), then
the solver will use the matrices without error.

* ODEs
  * Optimized Explicit Solvers
    * Euler
    * Midpoint Method
    * RK4
  * General Explicit (Adaptive) Runge-Kutta Methods
    * Huen's Method
    * Cash-Karp
    * Runge-Kutta-Fuhlberg (RKF) 4/5
    * Ralston's Method
    * Bogaki-Shampine
    * Dormand-Prince 4/5
    * Runge-Kutta-Fuhlberg (RKF) 7/8
    * Dormand-Prince 7/8
  * Stiff Solvers
    * Implicit Euler
    * Trapezoidal
    * Rosenbrock32
* SODEs
  * Euler-Maruyama
  * Milstein
  * Rossler-SRK
* (Stochastic) PDEs
  * Finite Element Solvers
    * Semilinear Poisson Equation
      * See implicit solvers
    * Semilinear Heat Equation (Reaction-Diffusion)
      * Forward Euler [Maruyama]
      * Backward Euler (using [NLSolve.jl](https://github.com/EconForge/NLsolve.jl)) [Maruyama]
      * Semi-implicit Crank-Nicholson [Maruyama]
      * Semi-implicit Backward Euler [Maruyama]
    * Linear Heat Equation
      * Forward Euler [Maruyama]
      * Backward Euler [Maruyama]
      * Crank-Nicholson [Maruyama]
* Implicit Solvers
  * Direct
  * Factorizations (LU, Cholesky, QR, SVD)
  * Conjugate-Gradient
  * GMRES


# Roadmap

* SODE Solvers
  * Adaptive-SRK
* (Stochastic) PDE Solvers
  * Finite difference solvers:
    * Semi-linear Heat Equation (Reaction-Diffusion Equation)
    * Semi-linear Poisson Equation
    * Wave Equation
    * Transport Equation
    * Stokes Equation
    * Implicit Integration Factor (IIF) Maruyama
    * Implicit Integration Factor (IIF) Milstein
