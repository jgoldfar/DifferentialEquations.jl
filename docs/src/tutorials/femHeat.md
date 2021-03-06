# Heat Equation Finite Element Method Example

In this example we will solve the heat equation ``u_t=Δu+f``. To do this, we define
a HeatProblem which contains the function ``f`` and the boundary conditions. We
specify one as follows:

```julia
"Example problem which starts with 0 and solves with ``f(u)=1-u/2``"
function heatProblemExample_birthdeath()
  f(u,x,t)  = ones(size(x,1)) - .5u
  u₀(x) = zeros(size(x,1))
  return(HeatProblem(u₀,f))
end
prob = heatProblemExample_birthdeath()
```

Here the equation we chose was nonlinear since ``f`` depends on the variable ``u``.
Thus we specify f=f(u,x,t). If ``f`` did not depend on u, then we would specify f=f(x,t).
We do need to specify ``gD`` (the Dirichlet boundary condition) and ``gN`` (the Neumann
boundary condition) since both are zero. ``u0`` specifies the initial condition. These together
give a HeatProblem object which holds everything which specifies a Heat Equation Problem.

We then generate a mesh. We will solve the equation on the parabolic cylinder
[0,1]^2 x [0,1]. You can think of this as the cube, or at every time point from 0
to 1, the domain is the unit square. To generate this mesh, we use the command

```julia
T = 1
Δx = 1//2^(3)
Δt = 1//2^(7)
femMesh = parabolic_squaremesh([0 1 0 1],Δx,Δt,T,"Neumann")
```  

We then call the solver

```julia
sol = solve(femMesh::FEMmesh,prob::HeatProblem,alg="Euler")
```

Here we have chosen to use the Euler algorithm to solve the equation. Other algorithms
and their descriptions can be found in the solvers part of the documentation.
