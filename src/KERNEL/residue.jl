#=
fragment:
- Julia version:
- Author: Dan
- Date: 2021-06-01
=#
include("../CONCEPT/composite_interface.jl")

import BioStructures

mutable struct Residue <: CompositeInterface
    res_name_                                   ::Union{String,Nothing}
    number_of_children_                         ::Union{Size,Nothing}
    parent_                                     ::Union{Nothing,CompositeInterface}
    previous_                                   ::Union{Nothing,CompositeInterface}
    next_                                       ::Union{Nothing,CompositeInterface}
    first_child_                                ::Union{Nothing,CompositeInterface}
    last_child_                                 ::Union{Nothing,CompositeInterface}
    properties_                                 ::Union{UInt64,Nothing}
    contains_selection_                         ::Union{Bool,Nothing}
    number_of_selected_children_                ::Union{Size,Nothing}
    number_of_children_containing_selection_    ::Union{Size,Nothing}
    selection_stamp_                            ::Union{TimeStamp,Nothing}
    modification_stamp_                         ::Union{TimeStamp,Nothing}
    trait_                                      ::Union{Nothing,CompositeInterface}
    insertion_code_                             ::Union{Char,Nothing}
    is_disordered_                              ::Union{Bool,Nothing}
    res_number_                                 ::Union{Int64,Nothing}
    is_hetero_                                  ::Union{Bool,Nothing}
    selected_                                   ::Bool

    Residue() = new(nothing,nothing,nothing,nothing,nothing,nothing,nothing,nothing,nothing,
    nothing,nothing,nothing,nothing,nothing,nothing,nothing,nothing,nothing,false)

    Residue(res_name_                                   ::Union{String,Nothing},
            number_of_children_                         ::Union{Size,Nothing},
            parent_                                     ::Union{Nothing,CompositeInterface},
            previous_                                   ::Union{Nothing,CompositeInterface},
            next_                                       ::Union{Nothing,CompositeInterface},
            first_child_                                ::Union{Nothing,CompositeInterface},
            last_child_                                 ::Union{Nothing,CompositeInterface},
            properties_                                 ::Union{UInt64,Nothing},
            contains_selection_                         ::Union{Bool,Nothing},
            number_of_selected_children_                ::Union{Size,Nothing},
            number_of_children_containing_selection_    ::Union{Size,Nothing},
            selection_stamp_                            ::Union{TimeStamp,Nothing},
            modification_stamp_                         ::Union{TimeStamp,Nothing},
            trait_                                      ::Union{Nothing,CompositeInterface},
            insertion_code_                             ::Union{Char,Nothing},
            is_disordered_                              ::Union{Bool,Nothing},
            res_number_                                 ::Union{Int64,Nothing},
            is_hetero_                                  ::Union{Bool,Nothing},
            selected_                                   ::Union{Bool,Nothing}) = new(


            res_name_,
            number_of_children_,
            parent_,
            previous_,
            next_,
            first_child_,
            last_child_,
            properties_,
            contains_selection_,
            number_of_selected_children_,
            number_of_children_containing_selection_,
            selection_stamp_,
            modification_stamp_,
            trait_,
            insertion_code_,
            is_disordered_,
            res_number_,
            is_hetero_,
            selected_
        )
end
Residue(res_name::String,num_of_children::Int64, ins_code::Char, res_number::Int64,hetero::Bool) =
    Residue(res_name,num_of_children,nothing,nothing,nothing,nothing,nothing,
            nothing,nothing,nothing,nothing,nothing,nothing,nothing,ins_code, false,res_number,hetero,false)


Residue(res::BioStructures.Residue) = Residue(res.name,countatoms(res,expand_disordered = false), res.ins_code,res.number,res.het_res)
Residue(res::BioStructures.DisorderedResidue) = nothing #change this if we need disorderedRes


Base.show(io::IO, res::Residue) = print(io,
    "Residue ($(res.is_hetero_ ? "hetero" : "non-hetero")) with ",
    "name $(res.res_name_), ",
    "$(countAtoms(res)) atoms"
)