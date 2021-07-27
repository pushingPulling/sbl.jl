#=
composite_interface:
- Julia version: 
- Author: Dan
- Date: 2021-06-07
=#

include("../COMMON/common.jl")
include("selectable.jl")
include("timeStamp.jl")

import Base.convert

abstract type CompositeInterface <: Selectable end


#=  Preorder, Neutral-Left-Right iterator
    (first current object, then DFS-like left subtree,
    then DFS-like right subtree)
=#

#iterative, not stateless
#saves a lot of info in a stack
#if collecting and then iterating over an array is fine, could use collect_recursive
Base.iterate(c :: CompositeInterface) = (c, CompositeInterface[c])

function Base.iterate(_ :: CompositeInterface, stack :: Vector{CompositeInterface})
    cp = last(stack)
    if cp.first_child_ !== nothing
        return (cp.first_child_, push!(stack, cp.first_child_))
    else
        if cp.next_ !== nothing
            stack[end] = cp.next_
            return (cp.next_, stack)
        else # backtracks
            pop!(stack)
            while !isempty(stack)
                if !isdefined(last(stack),:next_)
                    println(typeof(last(stack)), " ",last(stack))
                end
                cp = last(stack).next_
                if cp !== nothing
                    stack[end] = cp
                    return (cp, stack)
                end
                pop!(stack)
            end
            return nothing
        end
    end
end


Base.length(C::CompositeInterface) = countDescendants(C)
Base.eltype(::CompositeInterface) = CompositeInterface



#returns true if `this` is Descendant Of `other`, else false
isDescendantOf(this::T, other::S) where {T,S <: CompositeInterface} = begin
    cur::CompositeInterface = this
    while !isnothing(cur.parent_)
        cur = cur.parent_
        (cur == other) && return true
    end
    return false
end

getAtom(root::T, name::AbstractString) where T<:CompositeInterface = begin
    for atom in AtomIterator(root)
        if atom.name_ == name
            return atom
        end
    end
    return nothing
end

remove_child(root::T, child_node::S) where{T,S <: CompositeInterface} = begin
    # avoid self-removal and removal of ancestors
    if root == child_node || isDescendantOf(root, child_node)
        return false
    end

    #if child has no parent, we cannot remove it
    if isnothing(child_node.parent_)
        return false
    end

    #remove child from the list of children
    if root.first_child_ == child_node
        root.first_child_ = root.first_child_.next_

        if (!isnothing(root.first_child_))
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


get_children(node::T) where T <: CompositeInterface = begin

    if node.first_child_ !== nothing
        cur = node.first_child_
        children = (typeof(node.first_child_))[node.first_child_]
        while cur.next_ !== nothing
            push!(children,cur.next_)
            cur = cur.next_
        end
        return children

    end

end

#appends new_node to old_node
appendchild(old_node::T, new_node::S) where {T,S <: CompositeInterface} = begin
    #avoid self-appending and appending of parent nodes
    if old_node == new_node || isDescendantOf(new_node, old_node)
       return nothing
    end
    #check if new_node is already the last child of old_node
    if new_node == old_node.last_child_
        return nothing
    end

    # if composite has a parent, remove it from there
    if !isnothing(new_node.parent_)
        removeChild(new_node.parent_, new_node);
    end

    # insert it
    if isnothing(old_node.last_child_)

        # its the only child - easy!
        old_node.first_child_ = old_node.last_child_ = new_node

    else

        # append it to the list of children
        old_node.last_child_.next_ = new_node
        new_node.previous_ = old_node.last_child_
        old_node.last_child_ = new_node
    end

    new_node.parent_ = old_node
    if typeof(old_node) != Atom
        old_node.number_of_children_ += 1
    end
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

countDescendants_iterate(node::Type) where {Type <: CompositeInterface} = begin
    number_of_descendants::Size = 0
    for descendants in node
        number_of_descendants += 1
    end
    return number_of_descendants
end


countDescendants(node::Type) where {Type <: CompositeInterface} = begin
    number_of_descendants::Size = 1
    if isnothing(node.first_child_)
        return 1
    end

    cur = node.first_child_
    number_of_descendants += countDescendants(cur)
    while !isnothing(cur.next_)
        number_of_descendants += countDescendants(cur.next_)
        cur = cur.next_
    end
    return number_of_descendants
end

countAtoms(node::CompositeInterface) = begin
    number_of_atoms::Size = 0
    if isnothing(node.first_child_)
        if isa(node,Atom)
            return 1
        else
            return 0
        end
    end

    cur = node.first_child_
    number_of_atoms += countAtoms(cur)
    while !isnothing(cur.next_)
        number_of_atoms += countAtoms(cur.next_)
        cur = cur.next_
    end
    return number_of_atoms
end

#order: NLR
recursive_collect(node::Type1, collectType::Type{Type2}) where {Type1, Type2 <: CompositeInterface} = begin
    #performs a collect on current node and all its ancestors
    vec = Vector{CompositeInterface}()

    recursive_collect(node::Type1,vec::Vector{CompositeInterface}, collectType::Type{Type2}) where {Type1, Type2 <: CompositeInterface} = begin
        if collectType == CompositeInterface
            push!(vec,node)
        end
        (typeof(vec) == collectType) && push!(vec,node)

        if !isnothing(node.first_child_)
            cur = node.first_child_
            recursive_collect(cur,vec,collectType)
            while !isnothing(cur.next_)
               recursive_collect(cur.next_,vec,collectType)
                cur = cur.next_
            end
        end
    end
    recursive_collect(node,vec,collectType)
    return vec
end

Base.collect(node::T) where T <: CompositeInterface = begin
    return recursive_collect(node,CompositeInterface)
end

collectAtoms(node::CompositeInterface) = begin
    recursive_collect(node,Atom)
end

collectResidues(node::CompositeInterface) = begin
    recursive_collect(node,Residue)
end

collectChains(node::CompositeInterface) = begin
    recursive_collect(node,Chain)
end

function clearSelectionTree(x::CompositeInterface)
    for node in x
        deselect(x)
    end
end

countChildren(comp::CompositeInterface) = begin
    count = 0
    if !isnothing(comp.first_child_)
        count = 1
        cur = comp.first_child_
        while !isnothing(cur.next_)
            count += 1
            cur = cur.next_
        end
    end
    return count
end

getName(comp::CompositeInterface) = begin
    if typeof(comp) != Chain
        return comp.name_
    else
        return comp.id_
    end
end

Base.show(io::IO, comp::CompositeInterface) = print(io, typeof(comp)," \"",getName(comp), "\" with ",
countChildren(comp), " child",countChildren(comp) == 1 ? "" : "ren", " containing ", countAtoms(comp)," Atoms.")




