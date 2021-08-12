#=
simple_molecular_graph:
- Julia version: 
- Author: Dan
- Date: 2021-08-04
=#

include("../KERNEL/kernel_functions.jl")
abstract type AbstractNode end
abstract type AbstractMolGraph end

mutable struct Edge
    source_ ::AbstractNode
    target_ ::AbstractNode
    bond_   ::Bond
    Edge(source::AbstractNode, target::AbstractNode, bond::Bond) = new(source, target, bond)
end
Base.show(io::IO, edge::Edge) = print(io, "E[$(edge.source_) | $(edge.target_)]")


mutable struct Node <: AbstractNode
    adjacent_edges_ ::Vector{Edge}
    atom_           ::Atom
    Node(at::Atom) = new(Edge[], at)
end

Base.show(io::IO, node::Node) = print(io, "N[$(node.atom_.serial_)]")


#atoms_to_nodes_ relates atoms to nodes in this Graph and bodns_to_edges_ bonds to edges
 #
mutable struct MolecularGraph <: AbstractMolGraph

    atoms_to_nodes_::Dict{Atom,Node}
    bonds_to_edges_::Dict{Bond,Edge}
    MolecularGraph() = new(Dict{Atom,Node}(), Dict{Bond,Edge}())

end


collectNodes(graph::MolecularGraph) = begin
    return values(graph.atoms_to_nodes_)
end

collectPartnerNodes(node::Node) = begin
    return [x.source_ == node ? x.target_ : x.source_ for x in values(node.adjacent_edges_)]
end

collectPartnerEdges(node::Node) = begin
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

newNode(graph::MolecularGraph, at::Atom) = begin
    if haskey(graph.atoms_to_nodes_, at)
        return false
    end
    graph.atoms_to_nodes_[at] = Node(at)
end

deleteEdge(graph::MolecularGraph, e::Edge) = begin
    source = e.source_
    target = e.target_
    delete!(graph.bonds_to_edges_,e.bond_)
    filter!(x -> !(x == e),source.adjacent_edges)
    filter!(x -> !(x == e),target.adjacent_edges)
end

deleteNode(graph::MolecularGraph,node::Node) = begin
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

MolecularGraph(root::T) where T<:Union{System, Chain, Residue} = begin
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