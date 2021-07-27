#=
system:
- Julia version: 
- Author: Dan
- Date: 2021-06-01
=#
include("../CONCEPT/composite_interface.jl")
import BioStructures

mutable struct System <: CompositeInterface
    name_                                       ::Union{String,Nothing}
    number_of_children_                         ::Union{Size,Nothing}
    parent_                                     ::Union{CompositeInterface, Nothing}
    previous_                                   ::Union{CompositeInterface, Nothing}
    next_                                       ::Union{CompositeInterface, Nothing}
    first_child_                                ::Union{CompositeInterface, Nothing}
    last_child_                                 ::Union{CompositeInterface, Nothing}
    properties_                                 ::Union{UInt64,Nothing}
    contains_selection_                         ::Union{Bool,Nothing}
    number_of_selected_children_                ::Union{Size,Nothing}
    number_of_children_containing_selection_    ::Union{Size,Nothing}
    selection_stamp_                            ::Union{TimeStamp,Nothing}
    modification_stamp_                         ::Union{TimeStamp,Nothing}
    trait_                                      ::Union{CompositeInterface, Nothing}
    selected_                                   ::Bool
    System()= new(nothing,nothing,nothing,nothing,nothing,nothing,nothing,nothing,
                    nothing,nothing,nothing,nothing,nothing,nothing,false)

    System( name_                                       ::Union{String,Nothing},
            number_of_children_                         ::Union{Size,Nothing},
            parent_                                     ::Union{CompositeInterface, Nothing},
            previous_                                   ::Union{CompositeInterface, Nothing},
            next_                                       ::Union{CompositeInterface, Nothing},
            first_child_                                ::Union{CompositeInterface, Nothing},
            last_child_                                 ::Union{CompositeInterface, Nothing},
            properties_                                 ::Union{UInt64,Nothing},
            contains_selection_                         ::Union{Bool,Nothing},
            number_of_selected_children_                ::Union{Size,Nothing},
            number_of_children_containing_selection_    ::Union{Size,Nothing},
            selection_stamp_                            ::Union{TimeStamp,Nothing},
            modification_stamp_                         ::Union{TimeStamp,Nothing},
            trait_                                      ::Union{CompositeInterface, Nothing},
            selected_                                   ::Union{Bool,Nothing}

            ) = new(name_                                   ,
                    number_of_children_                     ,
                    parent_                                 ,
                    previous_                               ,
                    next_                                   ,
                    first_child_                            ,
                    last_child_                             ,
                    properties_                             ,
                    contains_selection_                     ,
                    number_of_selected_children_            ,
                    number_of_children_containing_selection_,
                    selection_stamp_                        ,
                    modification_stamp_                     ,
                    trait_                                  ,
                    selected_
                    )
end

System(mod::BioStructures.Model) = System("", countchains(mod),
    nothing,nothing,nothing,nothing,nothing,UInt64(0),false,0,0,nothing,nothing,nothing,false)

System() = System("",0,nothing,nothing,nothing,nothing,nothing,UInt64(0),false,0,0,nothing,nothing,nothing,false)

