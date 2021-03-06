# Defining a SDE Problem

To define an SDE Problem, you simply need to give the forcing function ``f``,
the noise function `σ`, and the initial condition ``u₀`` which define an SDE

```math
du = f(u,t)dt + Σσᵢ(u,t)dWⁱ
```

`f` and `σ` should be specified as `f(u,t)` and  `σ(u,t)` respectively, and `u₀`
should be an AbstractArray whose geometry matches the desired geometry of `u`.
Note that we are not limited to numbers or vectors for `u₀`, one is allowed to
provide `u₀` as arbitrary matrices / higher dimension tensors as well. A vector
of `σ`s can also be defined to determine an SDE of higher Ito dimension.

## Problem Type

```@docs
DifferentialEquations.SDEProblem
```

## Example Problems
```@docs
DifferentialEquations.twoDimlinearSDEExample
DifferentialEquations.cubicSDEExample
DifferentialEquations.linearSDEExample
DifferentialEquations.multiDimAdditiveSDEExample
DifferentialEquations.waveSDEExample
DifferentialEquations.additiveSDEExample
```
