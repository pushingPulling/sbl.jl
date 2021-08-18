#=
mincycle:
- Julia version: 
- Author: Dan
- Date: 2021-08-16
=#
include("../STRUCTURE/simple_molecular_graph.jl")
using DataStructures

mutable struct BackpointingNode <: AbstractNode
    adjacent_edges_ ::Vector{Edge}
    atom_           ::Atom
    parent_         ::BackpointingNode
    BackpointingNode(at::Atom) = (x = new(Edge[], at); x.parent_ = x)
end

collectPathToRoot(node::BackpointingNode) = begin
    path::Vector{BackpointingNode} = BackpointingNode[]
    cur::BackpointingNode = node
    while cur.parent_ != cur
        push!(path, cur)
        cur = cur.parent_
    end
    push!(path, cur)
    return path
end

searchfunc(edge::Edge,node::BackpointingNode)= begin
    ( (edge.source_ == node && edge.target_ == node.parent_) ||
        (edge.target_ == node && edge.source_ == node.parent_) )
end

collectBackpathEdges(path::Vector{BackpointingNode}) = begin
    #make sure path[1] contains a node whose parent you dont care about
    edge_path::Vector{Edge} = Edge[]
    for node in reverse(path[1:end-1])
        pos_in_vector = findfirst(x->searchfunc(x,node), node.adjacent_edges_)
        pushfirst!(edge_path, node.adjacent_edges_[pos_in_vector])
    end
    return edge_path
end

breadthFirstSearchMCB(graph::MolecularGraph, root::Node, deep::Bool=true) = begin
#iterating over a tree of node with type Node and making a bfs with nodetype BackpointingNode
    bfs = MolecularGraph(BackpointingNode)
    q::Queue{Node} = Queue{Node}()
    visited_nodes::Set{Node} = Set{Node}()

    #init: the root node's parent is itself
    previous_bfs_node::BackpointingNode = newNode(bfs,root.atom_, BackpointingNode)
    temp::BackpointingNode = previous_bfs_node  #dummy initilization to keep temp alive through loop
    push!(visited_nodes, root)
    cur = root
    depth::Int64 = 0

    while true
        for edge in collectPartnerEdges(cur)
            neighbour::Node = edge.source_ == cur ? edge.target_ : edge.source_
            if !(neighbour in visited_nodes)
                push!(visited_nodes, neighbour)
                enqueue!(q, neighbour)

                temp = newNode(bfs, neighbour.atom_, BackpointingNode)
                temp.parent_ = previous_bfs_node
                newEdge(bfs, edge.bond_)
            end
        end
        isempty(q) && break
        cur = dequeue!(q)
        previous_bfs_node = bfs.atoms_to_nodes_[cur.atom_]
        depth+=1
        if !deep && depth > BALL_HALF_OF_MAX_RING_SIZE
            break
        end
    end
    return bfs
end


minimum_cycle_basis(graph::MolecularGraph) = begin
    num_nodes = getNumberOfNodes(graph)
    num_edges = getNumberOfEdges(graph)

    mcb::Vector{Vector{Edge}} = Vector{Edge}[]
    tested_cycles::Set{Vector{Edge}} = Set{Edge}()


    i = 1
    for node in collectNodes(graph)
        i += 1
        bfs = breadthFirstSearchMCB(graph, node)
        bfs_bonds =  Set([x.bond_ for x in collectEdges(bfs)])
        graph_bonds =  Set([x.bond_ for x in collectEdges(graph)])
        edges_not_in_bfs = [graph.bonds_to_edges_[x] for x in setdiff(graph_bonds, bfs_bonds)]
        #each edge that is not in the bfs will create a cycle if restored
        for edge in edges_not_in_bfs
            #create cycles and put them into mcb or prune them
            #let `edge` = (w,x). Make the cycle: Path(w to node) + Path(x to node) + (w,x)
            #but only if node is the lowest common ancestor of w,x
            w::BackpointingNode = bfs.atoms_to_nodes_[edge.source_.atom_]
            x::BackpointingNode = bfs.atoms_to_nodes_[edge.target_.atom_]
            w_nodes = collectPathToRoot(w)
            x_nodes = collectPathToRoot(x)
            #if node is not the lca then the 2nd-to-last node on the paths will be the same
            if w_nodes[end-1] == x_nodes[end-1]
                continue;
            end
            w_path = collectBackpathEdges(w_nodes)
            x_path = collect(reverse(collectBackpathEdges(x_nodes)))

            new_cycle = vcat(w_path, x_path, edge)
            (new_cycle in tested_cycles) && break
            push!(tested_cycles, new_cycle)

            #test if linearly independent
            for (i,cyc1) in enumerate(mcb)
                for cyc2 in mcb[i+1:end]
                    (new_cycle == symdiff(cyc1, cyc2)) && break
                end
            end

            pos_in_mcb = findfirst(x->length(x) > length(new_cycle), mcb)
            isnothing(pos_in_mcb) && (pos_in_mcb = 1)
            insert!(mcb, pos_in_mcb, new_cycle)

            if length(mcb) == num_edges - num_nodes +1
                return mcb
            end
        end
    end
end


SSSR(root::CompositeInterface) = begin
    if length(collectBonds(root)) - length(collectAtoms(root)) + 1 < 1
        return
    end

    graph = MolecularGraph(root)
    to_delete::Vector{Edge} = Edge[]

    for edge in collectEdges(graph)
        bond_type = edge.bond_.bond_type_
        if bond_type == TYPE__HYDROGEN || bond_type == TYPE__DISULPHIDE_BRIDGE
            push!(to_delete, edge.bond_)
        end
    end

    for edge in to_delete
        deleteEdge(graph, edge)
    end
    sssr = minimum_cycle_basis(graph)
    ring_atoms = Set{Atom}()
    for edge in Iterators.flatten(sssr)
        push!(ring_atoms, edge.source_.atom_, edge.target_.atom_)
    end

    for atom in ring_atoms
        setProperty(atom,("InRing",true))
    end

    for atom in collectAtoms(root)
        if !hasProperty(atom,"InRing")
            setProperty(atom,("InRing",false))
        end
    end
    return sssr, ring_atoms
end

#problems: -makes a bfs for every node in the graph: insane cost
            #-> limit to depth 20?