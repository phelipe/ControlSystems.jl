Base.eltype{T}(::Type{Poly{T}}) = T
Base.eltype{T}(::Type{TransferFunction{T}}) = T
Base.eltype{T}(::Type{SisoZpk{T}}) = T
Base.eltype{T}(::Type{SisoRational{T}}) = T
Base.eltype{T}(::Type{StateSpace{T}}) = T


primitivetype{T}(::Type{Poly{T}}) = primitivetype(T)
primitivetype{T}(::Type{TransferFunction{T}}) = primitivetype(T)
primitivetype{T}(::Type{SisoZpk{T}}) = primitivetype(T)
primitivetype{T}(::Type{SisoRational{T}}) = primitivetype(T)
primitivetype(::Type{SisoGeneralized}) = Float64
primitivetype{T}(::Type{StateSpace{T}}) = primitivetype(T)
primitivetype{T<:Number}(::Type{T}) = T
primitivetype{T,N,P<:AbstractArray{T,N}}(::Type{P}) = primitivetype(T)
primitivetype(x) = primitivetype(typeof(x)) # Fallback method
primitivetype{T}(::Type{T}) = T # Catch all


arraytype{T}(::Type{Poly{T}}) = arraytype(T)
arraytype{T}(::Type{TransferFunction{T}}) = arraytype(T)
arraytype{T}(::Type{SisoZpk{T}}) = arraytype(T)
arraytype{T}(::Type{SisoRational{T}}) = arraytype(T)
arraytype{T}(::Type{StateSpace{T}}) = arraytype(T)

arraytype{T<:Number}(::Type{T}) = T
arraytype{T,N,P<:AbstractArray{T,N}}(::Type{P}) = P
arraytype(x) = arraytype(typeof(x)) # Fallback method
arraytype{T}(::Type{T}) = T # Catch all

responsetype{T<:Real}(::Type{T}) = T
responsetype{T<:Complex}(::Type{T}) = promote_type(T.types...)
responsetype(x) = typeof(x) # Fallback method
responsetype{T}(::Type{T}) = T # Catch all

primitivereal(x) = responsetype(primitivetype(x))

# Abstract type pyramid =============================================================
Base.promote_rule{T, S}(::Type{Poly{T}}, ::Type{Poly{S}}) = Poly{promote_type(T, S)}

Base.promote_rule{T,S}(::Type{StateSpace{T}}, ::Type{StateSpace{S}}) = StateSpace{promote_type(T, S)}
Base.promote_rule(::Type{TransferFunction}, ::Type{StateSpace}) = StateSpace
Base.promote_rule(::Type{SisoTf}, ::Type{StateSpace}) = StateSpace
Base.promote_rule(::Type{SisoZpk}, ::Type{StateSpace}) = StateSpace
Base.promote_rule(::Type{SisoRational}, ::Type{StateSpace}) = StateSpace

Base.promote_rule{T,S}(::Type{TransferFunction{T}}, ::Type{TransferFunction{S}}) = TransferFunction{promote_type(T, S)}
Base.promote_rule(::Type{SisoTf}, ::Type{TransferFunction}) = TransferFunction
Base.promote_rule(::Type{SisoZpk}, ::Type{TransferFunction}) = TransferFunction
Base.promote_rule(::Type{SisoRational}, ::Type{TransferFunction}) = TransferFunction

# Base.promote_rule{T,S}(::Type{SisoTf{T}}, ::Type{SisoTf{S}}) = SisoTf{promote_type(T, S)}
Base.promote_rule(::Type{SisoZpk}, ::Type{SisoTf}) = SisoTf
Base.promote_rule(::Type{SisoRational}, ::Type{SisoTf}) = SisoTf

Base.promote_rule{T,S}(::Type{SisoZpk{T}}, ::Type{SisoZpk{S}}) = SisoZpk{promote_type(T, S)}
Base.promote_rule(::Type{SisoRational}, ::Type{SisoZpk}) = SisoZpk

Base.promote_rule{T,S}(::Type{SisoRational{T}}, ::Type{SisoRational{S}}) = SisoRational{promote_type(T, S)}

Base.promote_rule(::Type{SisoTf}, ::Type{SisoGeneralized}) = SisoGeneralized # ??


# Promotion of Real ===============================================================
Base.promote_rule{S<:TransferFunction{<:SisoTf}}(::Type{S}, ::Type{<:Real}) = S
Base.promote_rule{T<:SisoZpk}(::Type{T}, ::Type{<:Real}) = T
Base.promote_rule{T}(::Type{SisoRational{T}}, ::Type{<:Real}) = SisoRational{T}
Base.promote_rule{T}(::Type{StateSpace{T}}, ::Type{<:Real}) = StateSpace{T}
Base.promote_rule{S<:TransferFunction{<:SisoTf},T<:Real}(::Type{S}, ::Union{Type{Array{T,2}},Type{Array{T,1}}}) = S


# Less abstract promotions
Base.promote_rule(::Type{TransferFunction{SisoRational}}, ::Type{TransferFunction{SisoZpk}}) = TransferFunction{SisoZpk}
Base.promote_rule(::Type{TransferFunction{SisoTf}}, ::Type{TransferFunction{SisoGeneralized}}) = TransferFunction{SisoGeneralized}


function Base.promote_rule{T<:StateSpace,P<:TransferFunction}(::Type{T}, ::Type{P})  #where T <: StateSpace where P <: TransferFunction
    S = promote_type(primitivereal(P), primitivereal(T)) # TODO: this is not correct for P <: zpk, in which case the StateSpace system gets complex matrices
    StateSpace{Matrix{S}}
end


function Base.promote_rule{T1c<:SisoZpk,T2c<:SisoRational}(::Type{T1c}, ::Type{T2c})
    upper_type = SisoZpk
    inner_type = promote_type(arraytype(T1c), arraytype(T2c))
    upper_type{inner_type}
end



# @show siso_type = promote_type(eltype.(systems)...)
# if isleaftype(siso_type)
#     siso_type = siso_type.name.wrapper
# end
# # array_type = promote_type(arraytype.(systems)...)
# # mat = hcat([(e->convert(siso_type{array_type}, e)).(s.matrix) for s in systems]...)
# @show promote_type([s.matrix for s in systems]...)


Base.convert{T}(::Type{Poly{T}}, p::Poly) = Poly(convert(T, p.a))
Base.convert{T<:Real}(::Type{<:TransferFunction}, b::T) = tf([b])
Base.convert{T<:Real}(::Type{<:TransferFunction{<:SisoRational}}, b::T) = tf(b)
Base.convert{T<:Real}(::Type{<:TransferFunction{<:SisoZpk}}, b::T) = zpk(b)
Base.convert{T<:Real}(::Type{<:TransferFunction{<:SisoGeneralized}}, b::T) = tfg(b)

Base.convert(::Type{<:TransferFunction{<:SisoZpk}}, s::TransferFunction) = zpk(s)
Base.convert(::Type{<:TransferFunction{<:SisoRational}}, s::TransferFunction) = tf(s)
Base.convert(::Type{<:TransferFunction{<:SisoGeneralized}}, s::TransferFunction) = tfg(s)


function Base.convert{T<:Real,S<:TransferFunction}(::Type{S}, b::VecOrMat{T})
    r = Matrix{S}(size(b,2),1)
    for j=1:size(b,2)
        r[j] = vcat(map(k->convert(S,k),b[:,j])...)
    end
    hcat(r...)
end

function Base.convert(::Type{<:SisoZpk}, sys::SisoRational)
    if length(sys.num) == 0
        return SisoZpk(primitivetype(sys)[],primitivetype(sys)[],0)
    elseif all(sys.den == zero(sys.den))
        error("Zero denominator, this should not be possible")
    else
        return SisoZpk(roots(sys.num),roots(sys.den),sys.num[1]/sys.den[1])
    end
end

function Base.convert(::Type{<:SisoRational}, sys::SisoZpk)
    num = prod(zp2polys(sys.z))*sys.k
    den = prod(zp2polys(sys.p))
    return SisoRational(num, den)
end

Base.convert(::Type{<:SisoGeneralized}, sys::SisoRational) = SisoGeneralized(sprint(print_compact, sys))
Base.convert(::Type{<:SisoGeneralized}, sys::SisoZpk) = convert(SisoGeneralized, convert(SisoRational, sys))
Base.convert(::Type{<:SisoRational}, sys::SisoGeneralized) = SisoRational(sys.expr)
Base.convert(::Type{<:SisoZpk}, sys::SisoGeneralized) = convert(SisoZpk, SisoRational(sys.expr))
Base.convert(::Type{<:SisoTf}, b::Real) = Base.convert(SisoRational, b)
Base.convert{T<:Real}(::Type{<:SisoZpk}, b::T) = SisoZpk(T[], T[], b)
Base.convert{T<:Real}(::Type{<:SisoRational}, b::T) = SisoRational([b], [one(T)])
Base.convert{T1}(::Type{SisoRational{Vector{T1}}}, t::SisoRational) =  SisoRational(Poly(T1.(t.num.a)),Poly(T1.(t.den.a)))
Base.convert(::Type{<:StateSpace}, t::Real) = ss(t)

function Base.convert(::Type{<:StateSpace}, t::TransferFunction)
    if !isproper(t)
        error("System is improper, a state-space representation is impossible")
    end
    ny, nu = size(t)
    mat = t.matrix
    # TODO : These are added due to scoped for blocks, but is a hack. This
    # could be much cleaner.
    Ac = Bc = Cc = Dc = A = B = C = D = Array{eltype(mat)}(0, 0)
    for i=1:nu
        for j=1:ny
            a, b, c, d = siso_tf_to_ss(mat[j, i])
            if j > 1
                # vcat
                Ac = blkdiag(Ac, a)
                Bc = vcat(Bc, b)
                Cc = blkdiag(Cc, c)
                Dc = vcat(Dc, d)
            else
                Ac, Bc, Cc, Dc = a, b, c, d
            end
        end
        if i > 1
            # hcat
            A = blkdiag(A, Ac)
            B = blkdiag(B, Bc)
            C = hcat(C, Cc)
            D = hcat(D, Dc)
        else
            A, B, C, D = Ac, Bc, Cc, Dc
        end
    end
    A, B, C = balance_statespace(A, B, C)[1:3]
    return ss(A, B, C, D, t.Ts, inputnames=t.inputnames, outputnames=t.outputnames)
end

function Base.convert{T<:AbstractNumberMatrix}(::Type{StateSpace{T}}, s::StateSpace)
    AT = promote_type(T, arraytype(s))
    StateSpace{AT}(AT(s.A),AT(s.B),AT(s.C),AT(s.D), s.Ts, s.statenames, s.inputnames, s.outputnames)
end

Base.zero{T}(p::Poly{T}) = Poly(zeros(eltype(T),1))
Base.zero{T}(::Type{Poly{T}}) = Poly(zeros(eltype(T),1))
Base.one{T}(p::Poly{T}) = Poly(ones(eltype(T),1))
Base.one{T}(::Type{Poly{T}}) = Poly(ones(eltype(T),1))

# Promote_op types
Base.promote_op{T<:SisoTf}(::Any, ::Type{T}, ::Type{T}) = T

#Just default SisoTf to SisoRational
SisoTf(args...) = SisoRational(args...)

Base.zero(::Type{<:SisoTf}) = zero(SisoRational)
Base.zero(::SisoTf) = zero(SisoRational)
Base.zero(::Type{<:SisoZpk}) = SisoZpk(Float64[],Float64[],0.0)
Base.zero(::SisoZpk) = Base.zero(SisoZpk)
Base.zero{T}(::Type{SisoRational{T}}) = SisoRational(zero(Poly{T}), one(Poly{T}))
Base.zero{T}(::SisoRational{T}) = Base.zero(SisoRational{T})
