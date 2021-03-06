@def SRI begin
  chi1 = .5*(ΔW.^2 - Δt)/sqΔt #I_(1,1)/sqrt(h)
  chi2 = .5*(ΔW + ΔZ/sqrt(3)) #I_(1,0)/h
  chi3 = 1/6 * (ΔW.^3 - 3*ΔW*Δt)/Δt #I_(1,1,1)/h

  H0[:]=zeros(size(u)...,length(α))
  H1[:]=zeros(size(u)...,length(α))
  for i = 1:length(α)
    if numVars == 1
      A0temp = 0.0
      B0temp = 0.0
      A1temp = 0.0
      B1temp = 0.0
    else
      A0temp = zeros(size(u))
      B0temp = zeros(size(u))
      A1temp = zeros(size(u))
      B1temp = zeros(size(u))
    end
    for j = 1:i-1
      @inbounds A0temp += A₀[i,j]*f(H0[..,j],t + c₀[j]*Δt)
      @inbounds B0temp += B₀[i,j]*σ(H1[..,j],t + c₁[j]*Δt)
      @inbounds A1temp += A₁[i,j]*f(H0[..,j],t + c₀[j]*Δt)
      @inbounds B1temp += B₁[i,j]*σ(H1[..,j],t + c₁[j]*Δt)
    end
    H0[..,i] = u + A0temp*Δt + B0temp.*chi2
    H1[..,i] = u + A1temp*Δt + B1temp*sqΔt
  end
  if numVars == 1
    atemp = 0.0
    btemp = 0.0
    E₂temp= 0.0
  else
    atemp = zeros(size(u))
    btemp = zeros(size(u))
    E₂    = zeros(size(u))
    E₁temp= zeros(size(u))
  end
  for i = 1:length(α)
    @inbounds ftemp = f(H0[..,i],t+c₀[i]*Δt)
    @inbounds atemp += α[i]*ftemp
    @inbounds btemp += (β₁[i]*ΔW + β₂[i]*chi1).*σ(H1[..,i],t+c₁[i]*Δt)
    @inbounds E₂    += (β₃[i]*chi2 + β₄[i]*chi3).*σ(H1[..,i],t+c₁[i]*Δt)
    if i<3 #1 or 2
      E₁temp += ftemp
    end
  end
  E₁ = Δt*E₁temp

  if adaptive
    #No adaptivity until publication
  else
    u = u + Δt*atemp + btemp + E₂
  end
end

@def SRIVectorized begin
  chi1 = .5*(ΔW.^2 - Δt)/sqΔt #I_(1,1)/sqrt(h)
  chi2 = .5*(ΔW + ΔZ/sqrt(3)) #I_(1,0)/h
  chi3 = 1/6 * (ΔW.^3 - 3*ΔW*Δt)/Δt #I_(1,1,1)/h
  H0[:]=zeros(uType,4)
  H1[:]=zeros(uType,4)
  for i = 1:length(α)
    H0temp = u + Δt*dot(vec(A₀[i,:]),f(H0,t + c₀*Δt)) + chi2*dot(vec(B₀[i,:]),σ(H1,t+c₁*Δt))
    H1[i]  = u + Δt*dot(vec(A₁[i,:]),f(H0,t + c₀*Δt)) + sqΔt*dot(vec(B₁[i,:]),σ(H1,t+c₁*Δt))
    H0[i] = H0temp
  end
  fVec = f(H0,t+c₀*Δt)
  E₁ = Δt*(fVec[1]+fVec[2])
  E₂ = dot(β₃*chi2 + β₄*chi3,σ(H1,t+c₁*Δt))
  if adaptive
    #No adaptivity until publication
  else
    u = u + Δt*dot(α,fVec) + dot(β₁*ΔW + β₂*chi1,σ(H1,t+c₁*Δt)) + E₂
  end
end

@def SRAVectorized begin
  chi2 = .5*(ΔW + ΔZ/sqrt(3)) #I_(1,0)/h
  H0[:]=zeros(length(α))
  for i = 1:length(α)
    H0[i] = u + Δt*dot(vec(A₀[i,:]),f(H0,t + c₀*Δt)) + chi2*dot(vec(B₀[i,:]),σ(H0,t+c₁*Δt))
  end
  fVec = f(H0,t+c₀*Δt)
  E₁ = Δt*(fVec[1]+fVec[2])
  E₂ = dot(β₂*chi2,σ(H0,t+c₁*Δt))
  if adaptive
    #No adaptivity until publication
  else
    u = u + Δt*dot(α,f(H0,t+c₀*Δt)) + dot(β₁*ΔW,σ(H0,t+c₁*Δt)) + E₂
  end
end

"""
solve(prob::SDEProblem,tspan=[0,1];Δt=0)

Solves the SDE as defined by prob with initial Δt on the time interval tspan.
If not given, tspan defaults to [0,1]. If

### Keyword Arguments

* fullSave: Saves the result at every saveSteps steps. Default is false.
saveSteps: If fullSave is true, then the output is saved every saveSteps steps.
* alg: String which defines the solver algorithm. Defult is "SRI". Possibilities are:
  * "EM"- The Euler-Maruyama method.
  * "RKMil" - An explicit Runge-Kutta discretization of the strong Order 1.0 Milstein method.
  * "SRA" - The strong Order 1.5 method for additive SDEs due to Rossler.
  * "SRI" - The strong Order 1.5 method for diagonal/scalar SDEs due to Rossler. Most efficient.
"""
function solve(prob::SDEProblem,tspan::AbstractArray=[0,1];Δt::Number=0,fullSave::Bool = false,
              saveSteps::Int = 1,alg::AbstractString="SRI",adaptive=false,γ=2.0,
              abstol=1e-3,reltol=1e-2,qmax=4,δ=1/6,maxIters::Int = round(Int,1e9),
              Δtmax=nothing,Δtmin=nothing,
              discardLength=1e-15,adaptiveAlg="RSwM3",progressBar=false,tType=typeof(Δt))

  @unpack prob: f,σ,u₀,knownSol,sol, numVars, sizeu
  adaptive = false #No adaptivity until publication
  tspan = vec(tspan)
  if tspan[2]-tspan[1]<0 || length(tspan)>2
    error("tspan must be two numbers and final time must be greater than starting time. Aborting.")
  end
  if Δtmax == nothing
    Δtmax = tType((tspan[2]-tspan[1])/2)
  end
  if Δtmin == nothing
    Δtmin = tType(1e-10)
  end

  uType = typeof(u₀)

  T = tspan[2]
  t = tspan[1]
  u = u₀
  if numVars == 1
    W = 0.0
    Z = 0.0
  else
    W = zeros(sizeu)
    Z = zeros(sizeu)
  end

  if fullSave
    uFull = GrowableArray(u)
    tFull = Vector{tType}(0)
    WFull = GrowableArray(W)
    push!(tFull,t)
  end

  atomLoaded = isdefined(Main,:Atom)

  #PreProcess

  if alg=="SRI"
    SRI = constructSRIW1()
    @unpack SRI: c₀,c₁,A₀,A₁,B₀,B₁,α,β₁,β₂,β₃,β₄
    if numVars == 1
      H0 = Array{eltype(u)}(length(α))
      H1 = Array{eltype(u)}(length(α))
    else
      H0 = Array{eltype(u)}(size(u)...,length(α))
      H1 = Array{eltype(u)}(size(u)...,length(α))
    end
    if adaptive
      #No adaptivity until publication
    end
  elseif alg=="SRA"
    SRA = constructSRA1()
    @unpack SRA: c₀,c₁,A₀,B₀,α,β₁,β₂
    if numVars == 1
      H0 = Array{eltype(u)}(length(α))
    else
      H0 = Array{eltype(u)}(size(u)...,length(α))
    end
  end
  if numVars == 1
    rands = ChunkedArray(randn)
  else
    rands = ChunkedArray(randn,u)
  end

  if alg == "Euler"
    order = 0.5
  elseif alg == "RKMil"
    order = 1.0
  else
    order = 1.5
  end

  if Δt == 0
    #No init Δt determiniation until publication.
    error("User must supply Δt")
  end

  sqΔt = sqrt(Δt)

  if adaptive && fullSave
    ΔtFull = Vector{tType}(0)
    push!(ΔtFull,Δt)
  end

  maxStackSize = 0
  maxStackSize2= 0
  iter = 0
  ΔW = sqΔt*next(rands) # Take one first
  ΔZ = sqΔt*next(rands) # Take one first

  while t < T
    iter += 1

    if alg=="EM"
      u = u + Δt.*f(u,t) + σ(u,t).*ΔW
    elseif alg=="RKMil"
      K = u + Δt.*f(u,t)
      L = σ(u,t)
      utilde = K + L.*sqΔt
      u = K+L.*ΔW+(σ(utilde,t)-σ(u,t))./(2sqΔt).*(ΔW.^2 - Δt)
    elseif alg=="SRA" && numVars == 1
      @SRAVectorized
    elseif alg=="SRI" && numVars > 1 #Only for explicit
      @SRI
    elseif alg=="SRI" && numVars == 1 #Only for explicit
      @SRIVectorized
    end
    if adaptive
      #No adaptivity until publication.
    else # Non adaptive
      t = t + Δt
      W = W + ΔW
      Z = Z + ΔZ
      ΔW = sqΔt*next(rands)
      ΔZ = sqΔt*next(rands)
      if fullSave && iter%saveSteps==0
        push!(uFull,u)
        push!(tFull,t)
        push!(WFull,W)
      end
    end
    (atomLoaded && progressBar) ? Main.Atom.progress(t/T) : nothing #Use Atom's progressbar if loaded
  end


  if knownSol
    uTrue = sol(u₀,t,W)
    if fullSave
      solFull = GrowableArray(sol(u₀,tFull[1],WFull[1]))
      for i in 2:size(WFull,1)
        push!(solFull,sol(u₀,tFull[i],WFull[i]))
      end
      WFull = copy(WFull)
      uFull = copy(uFull)
      solFull = copy(solFull)
      if !adaptive
        ΔtFull = Δt*ones(length(t))
      end
      return(SDESolution(u,uTrue,W=W,uFull=uFull,tFull=tFull,ΔtFull=ΔtFull,WFull=WFull,solFull=solFull,maxStackSize=maxStackSize))
    else
      return(SDESolution(u,uTrue,W=W,maxStackSize=maxStackSize))
    end
  else #No known sol
    if fullSave
      if !adaptive
        ΔtFull = Δt*ones(length(t))
      end
      uFull = copy(uFull)
      return(SDESolution(u,uFull=uFull,W=W,tFull=tFull,ΔtFull=ΔtFull,maxStackSize=maxStackSize))
    else
      return(SDESolution(u,W=W,maxStackSize=maxStackSize))
    end
  end
end
