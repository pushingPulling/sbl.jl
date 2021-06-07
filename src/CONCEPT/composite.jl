#=
composite:
- Julia version: 
- Author: Dan
- Date: 2021-06-04
=#
#=
composite:
- Julia version:
- Author: Dan
- Date: 2021-06-01
=#

include("../KERNEL/atom.jl")
include("../KERNEL/atomContainer.jl")
include("../KERNEL/bond.jl")
include("../COMMON/common.jl")
include("../CONCEPT/timeStamp.jl")

const CompositeType = Union{Atom,AtomContainer,Bond ,Nothing}   #can remove nothing


mutable struct Composite
    number_of_children_::Size
    parent_::Union{Composite,Missing}
    previous_::Union{Composite,Missing}
    next_::Union{Composite,Missing}
    first_child_::Union{Composite,Missing}
    last_child_::Union{Composite,Missing}
    properties_::UInt64
    contains_selection_::Bool
    number_of_selected_children_::Size
    number_of_children_containing_selection_::Size
    selection_stamp_::Union{TimeStamp,Nothing}
    modification_stamp_::Union{TimeStamp,Nothing}
    trait_::CompositeType

    #default constructor
    Composite() = new()
    Composite(xd::Bool) = new(0,missing,missing,missing,missing,missing,missing,0,false
    ,0,0,nothing,nothing,nothing)

    #full constructor
    Composite(
        number_of_children::Size,
        parent::Composite,
        previous::Composite,
        next::Composite,
        first_child::Composite,
        last_child::Composite,
        properties::UInt8,
        contains_selection::Bool,
        number_of_selected_children::Size,
        number_of_children_containing_selection::Size,
        selection_stamp::TimeStamp,
        modification_stamp::TimeStamp,
        trait::CompositeType,
    ) = begin

        new(
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
            trait,
        )
    end

end
#partial constructor: Refs to other Composites and the obj itself
Composite(
    number_of_children::Size,
    parent::Composite,
    prev::Composite,
    next::Composite,
    first_child::Composite,
    last_child::Composite,
    trait,
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


#=  Preorder, Neutral-Left-Right iterator
    (first current object, then DFS-like left subtree,
    then DFS-like right subtree)
=#

#iterative
Base.iterate(C::Composite, state = ([], 1)) = begin
    stack::Vector{Composite} = state[1]
    count::Int64 = state[2]
    #subtree_root::Composite
    #cur::Composite

    if !isempty(stack)
        subtree_root = stack[1]
        popfirst!(stack)
    else
        subtree_root = C
        (count != 1) && return nothing
    end


    if !ismissing(subtree_root.first_child_)
        cur = subtree_root.first_child_
        while cur != subtree_root.last_child_
            push!(stack, cur)
            cur = cur.next_
        end
        push!(stack, cur)
    end
    count += 1
    return (subtree_root, (stack, count))
end


#recursive






#returns true if `this` is Descendant Of `other`, else false
isDescendantOf(this::Composite, other::Composite) = begin
    cur::Composite = this
    while !ismissing(cur.parent_)
        cur = cur.parent_
        (cur == other) && return true
    end
    return false
end

remove_child(root::Composite, child_node::Composite) = begin
    # avoid self-removal and removal of ancestors
    if root == child_node || isDescendantOf(root, child_node)
        return false
    end

    #if child has no parent, we cannot remove it
    if ismissing(child_node.parent_)
        return false
    end

    #remove child from the list of children
    if root.first_child_ == child_node
        root.first_child_ = root.first_child_.next_

        if (!ismissing(root.first_child_))
            first_child_->previous_ = missing
        else
            root.last_child_ = missing
        end

        root.child.next_ = missing
    else
        if root.last_child_ == child_node
            root.last_child_ = child_node.previous_
            root.last_child_.next_ = child_node.previous_ = missing
        else
            child_node.previous_.next_ = child_node.next_

            child_node.next_.previous_ = child_node.previous_

            child_node.previous_ = child_node.next_ = missing
        end
    end

    # delete the child`s parent pointer
    child_node.parent_ = missing

    # adjust some counters
    number_of_children_ -= 1

    #=
    if (child_node.contains_selection_)
        number_of_children_containing_selection_ -= 1
        if (child_node.selected_)
            number_of_selected_children_ -= 1
        end
    end

    # update the selection
    updateSelection_();

    # update modification time stamp
    stamp(MODIFICATION);
    =#
    return true

end


#appends new_node to old_node
appendchild(old_node::Composite, new_node::Composite) = begin
    #avoid self-appending and appending of parent nodes
    if old_node == new_node || isDescendantOf(new_node, old_node)
       return nothing
    end
    #check if new_node is already the last child of old_node
    if new_node == old_node.last_child_
        return nothing
    end

    # if composite has a parent, remove it from there
    if !ismissing(new_node.parent_)
        removeChild(new_node.parent_, new_node);
    end

    # insert it
    if ismissing(last_child_)

        # its the only child - easy!
        old_node.first_child_ = old_node.last_child_ = new_node

    else

        # append it to the list of children
        old_node.last_child_.next_ = new_node
        new_node.previous_ = old_node.last_child_
        old_node.last_child_ = new_node
    end

    new_node.parent_ = old_node
    number_of_children_ += 1
    #=

    # update modification time stamp
    old_node.last_child_.stamp(MODIFICATION);

    # update selection counters
    if (new_node.containsSelection())
        number_of_children_containing_selection_ += 1
        if (new_node.selected_)
            number_of_selected_children_+=1
        end
        # recursively update the nodes` states
        (old_node.)updateSelection_();
    end
    =#

end

countDescendants_iterate(node::Composite) = begin
    number_of_descendants::Size = 0
    for descendants in node
        number_of_descendants += 1
    end
    return number_of_descendants
end


countDescendants(node::Composite) = begin
    number_of_descendants::Size = 1
    if ismissing(node.first_child_)
        return 1
    end

    cur = node.first_child_
    number_of_descendants += countDescendants_recursive(cur)
    while !ismissing(cur.next_)
        number_of_descendants += countDescendants_recursive(cur.next_)
        cur = cur.next_
    end
    return number_of_descendants
end
#TODO:
#=Composite needs
    iterators
       ancester(const) + reverse
       children + reverse
       childcomposite? + reverse
       bidirectional iterator composite + reverse

   iterators to end and begin; maybe just give max/min index?
=#