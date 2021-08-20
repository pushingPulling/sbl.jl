#=
chain:
- Julia version: 
- Author: Dan
- Date: 2021-06-01
=#
export
    Chain, getName


mutable struct Chain <: CompositeInterface
    id_                                         ::Union{Char, Nothing}
    number_of_children_                         ::Union{Int64,Nothing}
    parent_                                     ::Union{CompositeInterface, Nothing}
    previous_                                   ::Union{CompositeInterface, Nothing}
    next_                                       ::Union{CompositeInterface, Nothing}
    first_child_                                ::Union{CompositeInterface, Nothing}
    last_child_                                 ::Union{CompositeInterface, Nothing}
    properties_                                 ::Vector{Tuple{String,UInt8}}
    contains_selection_                         ::Union{Bool,Nothing}
    number_of_selected_children_                ::Union{Int64,Nothing}
    number_of_children_containing_selection_    ::Union{Int64,Nothing}
    selection_stamp_                            ::Union{TimeStamp,Nothing}
    modification_stamp_                         ::Union{TimeStamp,Nothing}
    trait_                                      ::Union{CompositeInterface, Nothing}
    selected_                                   ::Bool
    Chain() = new(nothing,nothing,nothing,nothing,nothing,nothing,nothing,Vector{Tuple{String,UInt8}}(),
                    nothing,nothing,nothing,nothing,nothing,nothing,false)
    Chain(   id_                                         ::Union{Char, Nothing},
             number_of_children_                         ::Union{Int64,Nothing},
             parent_                                     ::Union{CompositeInterface, Nothing},
             previous_                                   ::Union{CompositeInterface, Nothing},
             next_                                       ::Union{CompositeInterface, Nothing},
             first_child_                                ::Union{CompositeInterface, Nothing},
             last_child_                                 ::Union{CompositeInterface, Nothing},
             properties_                                 ::Vector{Tuple{String,UInt8}},
             contains_selection_                         ::Union{Bool,Nothing},
             number_of_selected_children_                ::Union{Int64,Nothing},
             number_of_children_containing_selection_    ::Union{Int64,Nothing},
             selection_stamp_                            ::Union{TimeStamp,Nothing},
             modification_stamp_                         ::Union{TimeStamp,Nothing},
             trait_                                      ::Union{CompositeInterface, Nothing},
             selected_                                   ::Bool

         ) = new(   id_                                     ,
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

getName(chain::Chain) = !isnothing(chain.id_) ? (chain.id_) : "-"

