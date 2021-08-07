#=
atom:
- Julia version: 
- Author: Dan
- Date: 2021-06-01
=#

include("PTE.jl")
include("bond.jl")
using StaticArrays
import BioStructures
using Distances: euclidean, sqeuclidean

mutable struct Atom <: AtomInterface    #AtomInterface inherits from CompositeInterface
    parent_         ::Union{Nothing,CompositeInterface}
    previous_       ::Union{Nothing,CompositeInterface}
    next_           ::Union{Nothing,CompositeInterface}
    first_child_    ::Union{CompositeInterface, Nothing}
    last_child_     ::Union{CompositeInterface, Nothing}
    name_           ::Union{String,Nothing}
    type_name_      ::Union{String,Nothing}
    element_        ::Union{Element,Nothing}
    radius_         ::Union{Float64,Nothing}
    type_           ::Union{UInt8,Nothing}
    number_of_bonds_::Union{UInt8,Nothing}
    formal_charge_  ::Union{Index,Nothing}
    position_       ::Union{SVector{3,Float64},Nothing}
    charge_         ::Union{Float64,Nothing}
    velocity_       ::Union{SVector{3,Float64},Nothing}
    force_          ::Union{SVector{3,Float64},Nothing}
    occupancy_      ::Union{Float64, Nothing}
    serial_         ::Union{Int64,Nothing}
    temp_factor_    ::Union{Float64,Nothing}
    selected_       ::Bool
    bonds_          ::Dict{Atom, Bond}
    properties_     ::Vector{Tuple{String,UInt8}}

    Atom() = new(nothing,nothing,nothing,nothing,nothing,nothing,nothing,
    nothing,nothing,nothing,nothing,nothing,nothing,nothing,nothing,nothing,
    nothing,nothing,nothing,false,Dict{Atom, Bond}(),Vector{Tuple{String,UInt8}}())


        Atom(   parent_         ,
                previous_       ,
                next_           ,
                first_child_    ,
                last_child_     ,
                name_           ,
                type_name_      ,
                element_        ,
                radius_         ,
                type_           ,
                number_of_bonds_,
                formal_charge_  ,
                position_       ,
                charge_         ,
                velocity_       ,
                force_          ,
                occupancy_      ,
                serial_         ,
                temp_factor_

            )   = new(parent_         ,
                    previous_       ,
                    next_           ,
                    first_child_    ,
                    last_child_     ,
                    name_           ,
                    type_name_      ,
                    element_        ,
                    radius_         ,
                    type_           ,
                    number_of_bonds_,
                    formal_charge_  ,
                    position_       ,
                    charge_         ,
                    velocity_       ,
                    force_          ,
                    occupancy_      ,
                    serial_         ,
                    temp_factor_    ,
                    false,
                    BondsDict(),
                    Vector{Tuple{String,Int8}}()
            )
end

const BondsDict = Dict{Atom, Bond}

Atom(   atomname::String, x::Float64, y::Float64, z::Float64,
        elem::String, charge::Union{Float64,Nothing},
         occupancy::Float64,serial::Int64, temp_factor::Float64) = begin

        Atom(nothing,
            nothing,
            nothing,
            nothing,
            nothing,
            atomname,
            nothing,
            Element(capitalize(elem)),
            nothing,
            nothing,
            nothing,
            nothing,
            SA_F64[x,y,z],
            charge,
            nothing,
            nothing,
            occupancy,
            serial,
            temp_factor)
    end

Atom(res::BioStructures.DisorderedAtom) = nothing #change this if we need disorderedatoms

getBonds(at::Atom) = at.bonds_

collectBonds(atoms::Vector{Atom}) = begin
    bonds::Vector{Bond} = Bond[]
    for at in atoms
        push!(bonds, values(getBonds(at))...)
    end
    return bonds
end

Atom(res::BioStructures.Atom) = begin
    return Atom(String(strip(res.name)), res.coords[1],res.coords[2],res.coords[3],String(strip(res.element)),
    (strip(res.charge) == "") ? nothing : parse(Float64,res.charge),
    res.occupancy, res.serial, res.temp_factor)
end

setFormalCharge(at::Atom, new_charge::Index) = begin at.formal_charge_ = new_charge end

Base.show(io::IO, at::Atom) = print(io, "Atom[",
    #"$( (isnothing(at.element_)) ? "-" : string(at.element_.symbol_) )|",
    "$(at.element_.symbol_)|",
    "$( (isnothing(at.parent_) || isnothing(at.parent_.name_)) ? "-" : at.parent_.name_ )]")


