#=
kernel_functions:
- Julia version: 
- Author: Dan
- Date: 2021-07-27
=#

include("dataformats.jl")
import Base.<, Base.>
using BioStructures

#this code creates an ordering reflecting the hierarchy of the kernel classes
#e.g. System > Chain is true, System < Chain is false, System < System is false
const comparisonops = [:<,:>]
const kerneltype = [Atom,Residue,Chain,System]
for x in kerneltype
    for y in kerneltype
        for op in comparisonops
            @eval Base.$op(::Type{$x},::Type{$y}) =
                  (Base.$op(findfirst(lambda -> lambda == $x,$kerneltype),
                           findfirst(lambda -> lambda == $y,$kerneltype)))
        end
    end
end


import Base.findfirst
findfirst(start_node::CompositeInterface,target_type::Type{T}, chain_attributes=(),
        residue_attributes=(), atom_attributes=()) where T<:CompositeInterface = begin

    target_type > Chain && return nothing
    cur_node::CompositeInterface = start_node

    if typeof(cur_node) > Chain && !isempty(chain_attributes)
        for ch in collectChains(cur_node)
            if all([ch[attr] == value for (attr,value) in pairs(chain_attributes)])
                cur_node = ch
                break
            end
        end
    end

    target_type > Residue && return nothing

    if typeof(cur_node) > Residue && !isempty(residue_attributes)
        for res in collectResidues(cur_node)
            if all([res[attr] == value for (attr,value) in pairs(residue_attributes)])
                cur_node = res
                break
            end
        end
    end

    target_type > Atom && return nothing

    if typeof(cur_node) > Atom && !isempty(atom_attributes)
        for at in collectAtoms(cur_node)
            if all([at[attr] == value for (attr,value) in pairs(atom_attributes)])
                cur_node = at
                break
            end
        end
    end

    cur_node == start_node && return nothing
    return cur_node
end
