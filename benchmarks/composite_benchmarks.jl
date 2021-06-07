#=
composite_benchmarks:
- Julia version: 
- Author: Dan
- Date: 2021-06-04
=#

#----------------------------BENCHMARKS-------------------------------

#create x Nodes, make them into a random tree and iterate over it
#create a histogram of element types

include("../src/CONCEPT/composite.jl")

using Random
using BenchmarkTools
using Statistics
using Printf
Base.show(io::IO, f::Float64) = @printf(io, "%.4f", f)

seed = 42
rng = MersenneTwister(seed)
NUM_ELEMS = convert(Int64,1e4)
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


function populateTree(Atoms::Vector{Atom}, Elements::Vector{Element})
    count = 2
    root = Composite()
    stack = Vector{Composite}()
    NUM_CHILDREN = 10
    node_counter = 0

    push!(stack, root)
    root.trait_ = Atoms[node_counter+1]
    root.next_ = missing
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
        tempArr = Composite[]
        if num_children != 0
            popfirst!(stack)
            for i = 1:num_children
                temp = Composite()
                temp.trait_ = Atoms[node_counter+i]
                temp.first_child_ = missing
                temp.next_ = missing
                temp.properties_ = count
                count += 1
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

Base.length(C::Composite) = NUM_ELEMS

#=
dict = initializeDict()
t = @benchmark iterateOverTree(root,dict)
print("Tree ")
t1 = mean(t.times)/1e6
println(t," ", t1,"ms")

x = convert(Vector{Composite},collect(root))
dict = initializeDict()

t = @benchmark iterateOverVector(x,dict)
print("Vector ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")

println("tree_time / array_time = $(t1/t2)")
=#
#--------------------------------------------------------
t = @benchmark countDescendants_iterate(root)
print("iter ")
t1 = mean(t.times)/1e6
println(t," ", t1,"ms")

t = @benchmark countDescendants_(root)
print("recurs ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")

println("iter= $(countDescendants_iterate(root)),  rec= $(countDescendants_recursive(root))")

println("iter / recurs = $(t1/t2)")
#-------------------------------------------------------





dict1 = initializeDict()
dict2 = initializeDict()
println(iterateOverTree(root,dict1) == iterateOverVector(x,dict2))

