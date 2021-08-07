#=
composite:
- Julia version: 
- Author: Dan
- Date: 2021-06-04
=#

include("timeStamp.jl")
include("composite_interface.jl")
import BioStructures


mutable struct Composite <: CompositeInterface
    name_                                       ::String
    number_of_children_                         ::Size
    parent_                                     ::Union{CompositeInterface, Nothing}
    previous_                                   ::Union{Nothing, CompositeInterface}
    next_                                       ::Union{CompositeInterface, Nothing}
    first_child_                                ::Union{CompositeInterface, Nothing}
    last_child_                                 ::Union{CompositeInterface, Nothing}
    properties_                                 ::UInt64
    contains_selection_                         ::Bool
    number_of_selected_children_                ::Size
    number_of_children_containing_selection_    ::Size
    selection_stamp_                            ::Union{TimeStamp,Nothing}
    modification_stamp_                         ::Union{TimeStamp,Nothing}
    trait_                                      ::Union{Nothing,CompositeInterface}

    #default constructor
    Composite() = new()
    Composite(xd::Bool) = new(0,nothing,nothing,nothing,nothing,nothing,nothing,0,false
    ,0,0,nothing,nothing,nothing)

    #full constructor
    Composite(
        name_                                   ::String,
        number_of_children                      ::Size,
        parent                                  ::Composite,
        previous                                ::Composite,
        next                                    ::Composite,
        first_child                             ::Composite,
        last_child                              ::Composite,
        properties                              ::UInt8,
        contains_selection                      ::Bool,
        number_of_selected_children             ::Size,
        number_of_children_containing_selection ::Size,
        selection_stamp                         ::TimeStamp,
        modification_stamp                      ::TimeStamp,
        trait                                   ::CompositeInterface

    ) = new(
            name_,
            number_of_children,
            parent,
            previous,
            next,
            first_child,
            last_child,
            properties,
            contains_selection,
            number_of_selected_children,
            number_of_children_containing_selection,
            selection_stamp,
            modification_stamp,
            trait
        )
end
#partial constructor: Refs to other Composites and the obj itself
Composite(
    number_of_children              ::Size,
    parent                          ::CompositeInterface,
    prev                            ::CompositeInterface,
    next                            ::CompositeInterface,
    first_child                     ::CompositeInterface,
    last_child                      ::CompositeInterface,
    trait                           ::CompositeInterface
) = begin

    Composite(
        number_of_children,
        parent,
        prev,
        next,
        first_child,
        last_child,
        0,
        false,
        false,
        0,
        0,
        nothing,
        nothing,
        trait,
    )
end




#ToDo copy constr from system
Composite(mod::BioStructures.Model) = Composite("", countchains(mod),
    nothing,nothing,nothing,nothing,nothing,UInt64(0),false,0,0,nothing,nothing,nothing)

Composite() = Composite("",0,nothing,nothing,nothing,nothing,nothing,UInt64(0),false,0,0,nothing,nothing,nothing)