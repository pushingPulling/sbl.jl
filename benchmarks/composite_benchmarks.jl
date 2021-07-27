#=
composite_benchmarks:
- Julia version: 
- Author: Dan
- Date: 2021-06-04
=#

#----------------------------BENCHMARKS-------------------------------

#create x Nodes, make them into a random tree and iterate over it
#create a histogram of element types

include("../src/KERNEL/common.jl")
include("../src/CONCEPT/common.jl")
include("../src/KERNEL/common.jl")
include("../src/CONCEPT/Composite.jl")

using Random
using BenchmarkTools
using Statistics
using Printf
Base.show(io::IO, f::Float64) = @printf(io, "%.4f", f)

seed = 42
rng = MersenneTwister(seed)
NUM_ELEMS = convert(Int64,1e5)
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


function populateTree(Atoms::Vector{Atom}, Elements::Vector{Element})
    count = 2
    root = System()
    stack = Vector{CompositeInterface}()
    NUM_CHILDREN = 10
    node_counter = 0

    push!(stack, root)
    root.next_ = nothing
    root.properties_ = 1
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
        tempArr = Atom[]
        if num_children != 0
            popfirst!(stack)
            for i = 1:num_children
                temp = Atoms[node_counter+i]
                temp.serial_ = count
                count += 1
                push!(tempArr, temp)
                appendchild(cur,temp)
            end
                node_counter += num_children
                for item in tempArr
                    push!(stack, item)
                end

        end
        #debug_i += 1
    end
    return root
end

root = populateTree(Atoms, Elements)
AbstractTrees.printnode(io::IO, x::Composite) = print(io, x.trait_.name_)

#----------------------------------------

BenchmarkTools.DEFAULT_PARAMETERS.samples = 100
t = @benchmark recursive_collect(root, Atom)
print("recurs_collect ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")

