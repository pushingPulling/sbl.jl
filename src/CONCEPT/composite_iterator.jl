#=
composir_iterator:
- Julia version:
- Author: Dan
- Date: 2021-06-15
=#
include("composite_interface.jl")
include("../KERNEL/system.jl")
include("../KERNEL/chain.jl")
include("../KERNEL/residue.jl")
include("../KERNEL/atom.jl")
abstract type CompositeIterator end
using Base: SizeUnknown
import Base.collect

function iterate_over_subtype(target_type::T) where T <: CompositeInterface
    end

mutable struct SystemIterator <:CompositeIterator
    node::CompositeInterface
end

mutable struct ChainIterator <: CompositeIterator
    node::CompositeInterface
end

mutable struct ResidueIterator <: CompositeIterator
    node::CompositeInterface
end

mutable struct AtomIterator <: CompositeIterator
    node::CompositeInterface
end


const iterator_to_composite = Dict{Type{T} where T<: CompositeIterator,Type{S} where S <: CompositeInterface}(
        SystemIterator => System,
        ChainIterator => Chain,
        ResidueIterator => Residue,
        AtomIterator => Atom
    )

const composite_to_iterator = Dict{Type{T} where T<: CompositeInterface,Type{S} where S <: CompositeIterator}(
        System => SystemIterator,
        Chain => ChainIterator,
        Residue => ResidueIterator,
        Atom => AtomIterator
    )



Base.length(::T) where T <: CompositeIterator = SizeUnknown()
Base.eltype(::T) where T <: CompositeIterator = iterator_to_composite[T]

#usage: for item in ChainIterator(someNode) ... end
Base.iterate(s :: T) where T <: CompositeIterator = begin

    while s.node.parent_ !== nothing
        s.node = s.node.parent_
    end
    stack = T[s]
    travel = T[]


    cur_type = typeof(s.node)
    skip_types = nothing

    if T == SystemIterator
        if cur_type != Composite
            return (s.node,(T[],s))
        else
            return (s.node.first_child_,(T[],T(s.node.first_child_)))
        end
    elseif T == ChainIterator
        skip_types = SA[System]
        stop_types = SA[Residue,Atom]
    elseif T == ResidueIterator
        skip_types = SA[System, Chain]
        stop_types = SA[Atom]
    elseif T == AtomIterator
        skip_types = SA[System,Chain, Residue]
        stop_types = SA[]
    end

    while !isempty(stack)
        cur = pop!(stack)
        #see if first is here
        if cur.node.first_child_ !== nothing
            if !(typeof(cur.node.first_child_) in skip_types)
                if typeof(cur.node.first_child_) in stop_types
                    nothing
                else
                    push!(travel, T(cur.node.first_child_))
                end
            else
                push!(stack, T(cur.node.first_child_))
            end
        end
        #see if nex tis here
        if cur.node.next_ !== nothing
            push!(stack, T(cur.node.next_))
        end
    end
    isempty(travel) && return nothing
    cp = last(travel)
    pop!(travel)
    return (cp.node,(travel,cp))
end

function Base.iterate(_ :: T, state::Tuple{Vector{T},Union{Nothing,T}}) where T <: CompositeIterator
    stack = state[1]

    if state[2] !== nothing
        cp = state[2]
        if cp.node.first_child_ !== nothing &&
            typeof(cp.node.first_child_) == iterator_to_composite[T]
            push!(stack, T(cp.node.first_child_))
        end
        if cp.node.next_ != nothing
            push!(stack,T(cp.node.next_))
        end

    end
    stack = state[1]
    isempty(stack) && return nothing
    cp = last(stack)
    if cp.node.first_child_ !== nothing &&
            typeof(cp.node.first_child_) == iterator_to_composite[T]
        stack[end] = T(cp.node.first_child_)
        return (cp.node,(stack,nothing))
    end
    if cp.node.next_ !== nothing
        stack[end] = T(cp.node.next_)
        return (cp.node, (stack,nothing))
    else # backtracks
        while !isempty(stack)
            cp = last(stack)
            if cp.node.next_ !== nothing
                stack[end] = cp
                return (cp.node, (stack,nothing))
            end
            pop!(stack)
            return (cp.node,(stack,nothing))
        end
        return nothing
    end

end

Base.collect(iter::T) where T<:CompositeIterator = begin
#=
    stack = (iterator_to_composite[T])[]
    for item in iter
        push!(stack,item)
    end
    return stack
    =#
    recursive_collect(iter.node, iterator_to_composite[T])
end