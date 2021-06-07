#=
atom:
- Julia version: 
- Author: Dan
- Date: 2021-06-01
=#
include("../COMMON/common.jl")
using StaticArrays

include("PTE.jl")
mutable struct Atom
    name_           ::String
    type_name_      ::String
    element_        ::Element
    radius_         ::Float64
    type_           ::UInt8
    number_of_bonds_::UInt8
    formal_charge_  ::Index
    position_       ::SVector{3,Float64}
    charge_         ::Float64
    velocity_       ::SVector{3,Float64}
    force_          ::SVector{3,Float64}
    Atom() = new()

end

