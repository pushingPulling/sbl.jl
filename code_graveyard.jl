include("src/KERNEL/atom.jl")
include("src/KERNEL/atomContainer.jl")
include("src/KERNEL/bond.jl")
include("src/COMMON/common.jl")
include("src/CONCEPT/timeStamp.jl")
const CompositeType = Union{Atom,AtomContainer,Bond} #,nothing}?


mutable struct Composite
    number_of_children_::Size
    parent_::Composite
    previous_::Composite
    next_::Composite
    first_child_::Union{Composite,Missing}
    last_child_::Composite
    properties_::UInt8
    contains_selection_::Bool
    number_of_selected_children_::Size
    number_of_children_containing_selection_::Size
    selection_stamp_::TimeStamp
    modification_stamp_::TimeStamp
    trait_::CompositeType

    #default constructor
    Composite() = new()

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
Base.iterate(C::Composite, state = ([], 1)) = begin
    stack::Vector{Ref{Composite}} = state[1]
    count::Int64 = state[2]
    #subtree_root::Composite
    #cur::Composite

    if !isempty(stack)
        subtree_root = stack[1][]
        popfirst!(stack)
    else
        subtree_root = C
        (count != 1) && return nothing
    end

    if !ismissing(subtree_root.first_child_)
        cur = subtree_root.first_child_
        while cur != subtree_root.last_child_
            push!(stack, Ref(cur))
            cur = cur.next_
        end
        push!(stack, Ref(cur))
    end

    count += 1
    return (subtree_root, (stack, count))
end

a_element = Atom()
a_element.name_ = "a"
b_element = Atom()
b_element.name_ = "b"
c_element = Atom()
c_element.name_ = "c"
d_element = Atom()
d_element.name_ = "d"
e_element = Atom()
e_element.name_ = "e"
x_element = Atom()
x_element.name_ = "x"

a = Composite()
b = Composite()
c = Composite()
d = Composite()
e = Composite()
x = Composite()

a.trait_ = a_element
b.trait_ = b_element
c.trait_ = c_element
d.trait_ = d_element
e.trait_ = e_element
x.trait_ = x_element

a.first_child_ = x
a.last_child_ = b

x.first_child_ = missing
x.next_ = b

b.first_child_ = c
b.last_child_ = d


c.first_child_ = e
c.last_child_ = e
c.next_ = d

e.first_child_ = missing
d.first_child_ = missing

for item in a
    println(item.trait_.name_)
end

using Random
seed = 42
rng = MersenneTwister(seed)
NUM_ELEMS = convert(Int64,1e3)
println("Num elems: $NUM_ELEMS \n")

function initializeDict()
    result_dict = Dict{Symbol,Int64}()
    for item in instances(Symbol)
        result_dict[item] = 0
    end
    return result_dict
end
num_symbols = length(instances(Symbol))
Elements = Vector{Element}(undef, NUM_ELEMS)
Atoms = Vector{Atom}(undef, NUM_ELEMS)
Composites = Vector{Composite}(undef, NUM_ELEMS)

for i = 1:NUM_ELEMS
    elem = Element()
    elem.symbol_ = Symbol(rand(rng, (0:num_symbols-1)))
    Elements[i] = elem

    atom = Atom()
    atom.element_ = elem
    atom.name_ = string(i)
    Atoms[i] = atom
end

#build tree
#have up to y children per Node. each child is insterted into a stack
#and awaits getting children
test  =0
function populateTree(Atoms::Vector{Atom}, Elements::Vector{Element})
    root = Composite()
    stack = Vector{Composite}()
    NUM_CHILDREN = 10
    node_counter = 0

    push!(stack, root)
    root.trait_ = Atoms[node_counter+1]
    node_counter += 1
    #debug_i = 0
    while node_counter < NUM_ELEMS
        #println("iter $debug_i: $(length(stack))")
        if isempty(stack)
            println("STACK: $stack")
            throw(DomainError(stack, "too many childless nodes"))
        end
        cur = stack[1]


        num_children = rand(rng, 0:NUM_CHILDREN)
        (num_children + node_counter) > NUM_ELEMS ?
        (num_children = NUM_ELEMS - node_counter) : nothing
        tempArr = Composite[]
        if num_children != 0
            popfirst!(stack)
            for i = 1:num_children
                temp = Composite()
                temp.trait_ = Atoms[node_counter+i]
                temp.first_child_ = missing
                if node_counter > 980
                    global test = temp
                end
                push!(tempArr, temp)
            end

            if num_children > 1
                for i = 1:length(tempArr)-1
                    tempArr[i].next_ = tempArr[i+1]
                end
                node_counter += num_children


                cur.first_child_ = tempArr[1]
                cur.last_child_ = tempArr[end]

                for item in tempArr
                    push!(stack, item)
                end
            end
        end
        #debug_i += 1
    end
    return root
end
root = populateTree(Atoms, Elements)

function iterateOverTree(root::Composite, hist::Dict{Symbol,Int64})
    for item in root
        hist[item.trait_.element_.symbol_] += 1
    end
    return hist
end

function iterateOverVector(arr::Vector{Composite},hist::Dict{Symbol,Int64})
    for item in arr
        hist[item.trait_.element_.symbol_] += 1
    end
    return hist
end

using BenchmarkTools
using Statistics
using Continuables

corange(n::Integer) = @cont begin
  for i in 1:n
    cont(i)
  end
end



simple1(n::Integer) = begin
    stack = []
    for i in 1:n
        push!(stack,i)
    end
    return stack
end

simple2(n::Integer) = begin
    stack = Array{Int64}(undef,n)
    for i in 1:n
        stack[i] = i
    end
    return stack
end



num = convert(Int64,1e7)
#=
t = @benchmark collect(corange(num))
print("corange ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")

t = @benchmark simple1(num)
print("simple ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")

t = @benchmark simple2(num)
print("simple ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")
=#

#trash
count = 0
iterateMy(::Nothing) = nothing
iterateMy(x::Composite) = @cont begin
    global count += 1
    println(count)
    cont(x.trait_.name_)
    if !ismissing(x.first_child_)
        cur = x.first_child_
        println("here")
        iterateMy(cur)

        fun()
        while cur != x.last_child_
            println("here2")
            cont(iterateMy(cur.next_))
            iterateMy(cur.next_)
            fun()
            cur = cur.next_
        end
    end
end

using AbstractTrees

mutable struct lil
    next
    child
    name
    lil() = new()
end

AbstractTrees.children(l::lil) = [x for x in l.child]
a = lil()
a.name = "a"
b = lil()
b.name = "b"
c = lil()
c.name = "c"
d = lil()
d.name = "d"
e = lil()
e.name = "e"
f = lil()
f.name = "f"
g = lil()
g.name = "g"

a.child = [b,d,e]
b.child = [c]
e.child = [f,g]
c.child = []
d.child = []
f.child = []
g.child = []


AbstractTrees.printnode(io::IO, node::lil) = print(io, node.name)
x = Tree(a)
print_tree(a)

for item in PreOrderDFS(x)
    print(item.name)
    end

