#=
simple_molecular_graph:
- Julia version: 
- Author: Dan
- Date: 2021-08-04
=#

include("../KERNEL/kernel_functions.jl")
abstract type AbstractNode end
abstract type AbstractMolGraph end
import Base.==


mutable struct Edge
    source_ ::AbstractNode
    target_ ::AbstractNode
    bond_   ::Bond
    Edge(source::AbstractNode, target::AbstractNode, bond::Bond) = new(source, target, bond)
end
Base.show(io::IO, edge::Edge) = print(io, "E[$(edge.source_) | $(edge.target_)]")
(==)(x::Edge, y::Edge) = return (x === y || x.bond_ == y.bond_)


mutable struct Node <: AbstractNode
    adjacent_edges_ ::Vector{Edge}
    atom_           ::Atom
    Node(at::Atom) = new(Edge[], at)
end
Base.show(io::IO, node::AbstractNode) = print(io, "N[$(node.atom_.serial_)]")


#atoms_to_nodes_ relates atoms to nodes in this Graph and bodns_to_edges_ bonds to edges
 #
mutable struct MolecularGraph <: AbstractMolGraph

    atoms_to_nodes_::Dict{Atom,AbstractNode}
    bonds_to_edges_::Dict{Bond,Edge}
    MolecularGraph() = new(Dict{Atom,AbstractNode}(), Dict{Bond,Edge}())
    MolecularGraph(NodeType) = new(Dict{Atom,NodeType}(), Dict{Bond,Edge}())

end


collectNodes(graph::MolecularGraph) = begin
    return values(graph.atoms_to_nodes_)
end

collectPartnerNodes(node::AbstractNode) = begin
    return [x.source_ == node ? x.target_ : x.source_ for x in values(node.adjacent_edges_)]
end

collectPartnerEdges(node::AbstractNode) = begin
    return values(node.adjacent_edges_)
end

collectEdges(graph::MolecularGraph) = begin
    return values(graph.bonds_to_edges_)
end

getNumberOfNodes(graph::MolecularGraph) = begin
    return length(graph.atoms_to_nodes_)
end

getNumberOfEdges(graph::MolecularGraph) = begin
    return length(graph.bonds_to_edges_)
end

newNode(graph::MolecularGraph, at::Atom, NodeType::Type{typ} = Node) where typ<:AbstractNode = begin
    if haskey(graph.atoms_to_nodes_, at)
        return false
    end
    temp::NodeType = NodeType(at)
    graph.atoms_to_nodes_[at] = temp
    return temp
end

deleteEdge(graph::MolecularGraph, e::Edge) = begin
    source = e.source_
    target = e.target_
    delete!(graph.bonds_to_edges_,e.bond_)
    filter!(x -> !(x == e),source.adjacent_edges)
    filter!(x -> !(x == e),target.adjacent_edges)
end

deleteNode(graph::MolecularGraph,node::AbstractNode) = begin
    for edge in node.adjacent_edges_
        deleteEdge(graph, edge)
    end
    delete!(graph.atoms_to_bodes_, node.atom_)
end

newEdge(graph::MolecularGraph, bond::Bond) = begin
    if haskey(graph.bonds_to_edges_, bond)
        return false
    end

    if !haskey(graph.atoms_to_nodes_, bond.source_) || !haskey(graph.atoms_to_nodes_, bond.target_)
        return false
    end

    temp = Edge(graph.atoms_to_nodes_[bond.source_], graph.atoms_to_nodes_[bond.target_], bond)
    graph.bonds_to_edges_[bond] = temp
    push!(graph.atoms_to_nodes_[bond.source_].adjacent_edges_, temp)
    push!(graph.atoms_to_nodes_[bond.target_].adjacent_edges_, temp)
end

MolecularGraph(root::T, NodeType::Type{typ} = Node) where typ<:AbstractNode where T<:Union{System, Chain, Residue} = begin
    graph = MolecularGraph()
    atoms = collectAtoms(root)
    for at in atoms
        newNode(graph, at)
    end

    for bond in collectBonds(atoms)
        newEdge(graph, bond)
    end
    return graph
end


breadthFirstSearch(graph::MolecularGraph, root::Node, NodeType::Type{typ} = Node) where typ<:AbstractNode = begin
    bfs = MolecularGraph(NodeType)
    q::Queue{NodeType} = Queue{NodeType}()
    visited_nodes::Set{NodeType} = Set{NodeType}()
    cur::NodeType = root
    newNode(bfs,root.atom_, NodeType)
    push!(visited_nodes, root)
    cur = root
    while true
        for edge in collectPartnerEdges(cur)
            neighbour::Node = edge.source_ == cur ? edge.target_ : edge.source_
            if !(neighbour in visited_nodes)
                push!(visited_nodes, neighbour)
                enqueue!(q, neighbour)

                newNode(bfs, neighbour.atom_, BackpointingNode)
                newEdge(bfs, edge.bond_)
            end
        end
        isempty(q) && break
        cur = dequeue!(q)
    end
    return bfs
end