#=
ring_perception_processor:
- Julia version: 
- Author: Dan
- Date: 2021-08-05
=#

include("../KERNEL/dataformats.jl")
include("../STRUCTURE/simple_molecular_graph.jl")
using Bijections

struct PathMessage
    beep    ::BitVector
    nfirst  ::Node
    nlast   ::Node
    efirst  ::Edge
    PathMessage(beep::BitVector, nfirst::Node, nlast::Node,efirst::Edge) = new(beep,nfirst,nlast,efirst)
end

nodeIsNew(beep::BitVector, tnode::Node) = begin
    for (i,bit) in enumerate(beep)
        if bit
            edge::Edge = index_to_bond[i]
            if edge.source_ == tnode || edge.target_ == tnode
                return false
            end
        end
    end
    return true
end

struct BalducciParams
    rings               ::Vector{BitVector}     #SSSR detected by algorithm
    matrix_             ::Vector{BitVector}     #matrix for independecy tests
    forwarded_rings     ::Vector{BitVector}     #rings of i-th phase to be forwarded to ring selector
    tested_beers        ::Vector{BitVector}     #already tested beers
    all_small_rings     ::Vector{Atom}          #contains all 3 to 6 membered rings after the procedure of the Balducci-Pearlman algorithm
    all_small_beers     ::Vector{BitVector}     #contains 3 to 6 membered rings as beers

    balducciParams() = new(BitVector[], BitVector[],BitVector[],BitVector[],Atom[],BitVector[])
end

struct TNode
    receive_buffer  ::Vector{PathMessage}
    send_buffer     ::Vector{PathMessage}
    TNode() = new(PathMessage[], PathMessage[])
end

getBalducciParams(params::BalducciParams) = begin
    return(params.rings  ,
           params.matrix_         ,
           params.forwarded_rings ,
           params.tested_beers    ,
           params.all_small_rings,
           params.all_small_beers)
end

setBalducciParams(rings::Vector{BitVector},matrix::Vector{BitVector},forwarded_rings::Vector{BitVector},
    tested_beers::Vector{BitVector},all_small_rings::Vector{Atom},all_small_beers::Vector{BitVector}) = begin
    params.rings           = rings
    params.matrix          = matrix
    params.forwarded_rings = forwarded_rings
    params.tested_beers    = tested_beers
    params.all_small_rings = all_small_rings
    params.all_small_beers = all_small_beers
end



calculateSSSR(root::CompositeInterface) = begin
    println(length(collectBonds(root)) ," ", length(collectAtoms(root)))
    if length(collectBonds(root)) - length(collectAtoms(root)) + 1 < 1
        return
    end

    graph = MolecularGraph(root)
    to_delete::Vector{Edge}

    for edge in graph
        bond_type = edge.bond_.bond_type_
        if bond_type == TYPE__HYDROGEN || bond_type == TYPE__DISULPHIDE_BRIDGE
            push!(to_delete, edge.bond_)
        end
    end

    for edge in to_delete
        deleteEdge(graph, edge)
    end

    sssr = BalducciPearlmanAlgorithm(graph)

    for atom in collectAtoms(root)
        if !hasProperty(atom,"InRing")
            setProperty(atom,("InRing",false))
        end
    end

    return sssr
end

BalducciPearlmanRingSelector_(beer::BitVector, params::BalducciParams) = begin
    rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings_ ,all_small_beers = getBalducciParams(params)

    if isempty(rings)
       push!(rings, beer)
       push!(matrix, beer)
       return BalducciParams(rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings)
    end

    new_beer::BitVector = deepcopy(beer)
    hi_bit::Int64 = 0
    r_begin::Int64 = 0

    for i in 1:length(new_beer)
        if new_beer[i]
            r = r_begin
            while(r< length(matrix))
                for c in 1:length(matrix[r])
                    if matrix[r][c]
                        hi_bit = c
                        break
                    end
                end
                if i == hi_bit
                    r_begin = r+1
                    new_beer1= matrix[r]
                    break
                end
            end
        end
    end

    if sum(new_beer) < 3
        return BalducciParams(rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings)
    end

    beer_index::Int64 = findfirst(x->x, new_beers)  #finds the first "true" value in vector


    cur_col::Int64 = 0
    for (i,row) in enumerate(matrix)
        while !row[cur_col]
            cur_col += 1
        end

        if cur_col > beer_index
            target_position = i
            break
        end
    end
    insert!(matrix, i, new_beers)

    push!(rings, beer)
    return BalducciParams(rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings)
end

toggleBit(x::BitVector, i) =  (a[i] ⊻= 1)


send(tnode::TNode,node_to_tnode::Bijection{Node,TNode}, index_to_edge::Bijection{Int64,Edge}) = begin
    for pm in tnode.send_buffer
        a::Node = node_to_tnode(tnode)
        for edge in getPartnerEdges(a)
            tnode::TNode
            if partner.source_ == a
                partner = node_to_tnode[edge.target_]
            else
                partner = node_to_tnode[edge.source_]
            end

            if partner != pm.nlast
                new_pm = PathMessage(pm.beep, pm.nfirst, tnode, pm.efirst)
                if !new_pm.beep[index_to_edge(edge) && nodeIsNew(new_pm.beep, node_to_tnode(partner))]
                    new_pm.beep[index_to_edge(edge)] = 1
                    push!(partner.receive_buffer, new_pm)
                end
            end
        end
    end
    #clear the send_buffer
    return TNode(tnode.receive_buffer, PathMessage[])
end


receive(tnode::TNode, forwarded_rings::Vector{BitVector}) = begin
    A_Type = Dict{Edge,Dict{TNode, Vector{PathMessage}}}
    array_A::A_Type = A_Type()
    do_not_forward::Vector{BitVector} = BitVecor[]
    for pm in tnode.recieve_buffer
        push!(array_a[pm.efirst][pm.nfirst], pm)
    end

    for tnode_to_pm_vector in array_A
        for (tnode,pm_vector) in pairs(tnode_to_pm_vector)

            if length(pm_vector) > 1
                 new_message = PathMesage[]
                 push!(new_message, pm_vector[0])
                 push!(do_not_forward, [pm.beep for pm in pm_vector[2:end]])
                 tnode_to_pm_vector[tnode] = new_message
            end
        end
    end

    array_B::Dict{tnode, Vector{PathMessage}} = Dict{tnode, Vector{PathMessage}}()
    for tnode_to_pm_vector in array_A
        for (tnode1,pm_vector1) in pairs(tnode_to_pm_vector)
            for (tnode2,pm_vector2) in pairs(tnode_to_pm_vector)
                if haveSigleIntersection(tnode1.beep, tnode2.beep)
                    beer::BitVector = tnode1.beep .| tnode2.beep    # .| is the broadcasted or operator
                    push!(forwarded_rings, beer)    #in params?
                    push!(do_not_forward, vector1.beep, vector2.beep)
                end
            end
            push!(array_b[tnode1], pm_vector1[0])
        end
    end

    #handle collisions
    for (tnode,pm_vector) in pairs(array_B)
        for i in 1:length(pm_vector)
            for j in i:length(pm_vector)
                if haveZeroIntersection(pm_vector[i].beep, pm_vector[j].beep)
                    beer = pm_vector[i].beep .| pm_vector[j].beep
                    push!(forwarded_rings, beer)
                    push!(do_not_forward, pm_vector[i].beep, pm_vector[j].beep)
                end
            end
        end
    end


    for pm in tnode.recieve_buffer
        has::Bool = false
        for bitvec_vector in do_not_forward
            if pm.beep == bitvec_vector
                has = true
                break
            end
        end

        if !has
            push!(tnode.send_buffer, pm)
        end
    end

    return TNode(PathMessage[], tnode.send_buffer)
end


BalducciPearlmanAlgorithm(graph::MolecularGraph) = begin
    #usage: node_to_tnode[node] => returns a TNode
    #usage: node_to_tnode(tnode) => returns a Node
    # it updates operations on it autmatically
    rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings ,all_small_beers = BalducciParams()

    num_nodes = getNumberOfNodes(graph)
    num_edges = getNumberOfEdges(graph)
    node_to_tnode::Bijection{Node,TNode} = Bijection{Node,TNode}(node => TNode() for node in getNodes(graph))
    index_to_edge::Bijection{Int64,Edge} = Bijection{Int64,Edge}(i => edge for (i,edge) in enumerate(getEdges(graph)))

    sssr::Vector{Vector{Atom}} = Vector{Atom}[]

    for node in getNodes(graph)
        for partner in getPartnerNodes(node)
            #pm::PathMessage = PathMessage()
            beep::BitVector = falses((num_nodes))
            toggleBit(beep, index_to_edge(partner))
            #pm.beep
            tnode::TNode

            if partner.source_ == node
                 tnode = node_to_tnode[partner.target_]
            else
                 tnode = node_to_tnode[partner.source_]
            end
            pm = PathMessage(beep, tnode,tnode, partner)
            push!(node_to_tnode[node].send_buffer, pm)
        end
    end
    num_rings::Int64 = num_edges - num_nodes +1

    count = 1
    while length(rings != num_rings)
        for node in graph
            node_to_tnode[node] = send(node_to_tnode[node],node_to_tnode::Bijection{Node,TNode}, index_to_edge::Bijection{Int64,Edge})
        end
        for node in graph
            node_to_tnode[node], forwarded_rings = receive(node_to_tnode[node],forwarded_rings)
        end

        even_sized::Vector{BitVector} = BitVector[]

        for bit_vec in forwarded_rings
            if sum(bit_vec) == 2*count -1
                if !(bit_vec in tested_beers)
                    push!(tested_beers, bit_vec)
                    rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings_ ,all_small_beers =
                        BalducciPearlmanRingSelector_(bit_vec,
                            BalducciParams(rings, matrix ,forwarded_rings ,tested_beers
                                                            ,all_small_rings_ ,all_small_beers))
                    if sum(bit_vec) == 3 ||sum(bit_vec) == 5
                        push!(all_small_beers, bit_vec)
                    end
                end
            else
                push!(even_sized, bit_vec)
            end
        end

        #even sized
        for bit_vec in even_sized
            if !(bit_vec in tested_beers)
                push!(tested_beers, bit_vec)
                rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings_ ,all_small_beers =
                    BalducciPearlmanRingSelector_(bit_vec,
                        BalducciParams(rings, matrix ,forwarded_rings ,tested_beers
                                                        ,all_small_rings_ ,all_small_beers))
                if sum(bit_vec) == 4 ||sum(bit_vec) == 6
                    push!(all_small_beers, bit_vec)
                end
            end
        end

        forwarded_rings = BitVector[]

        if count > BALL_QSAR_RINGPERCEEPTIONPROCESSOR_MAX_RUNS
            throw(TooManyIterationsException(BALL_QSAR_RINGPERCEEPTIONPROCESSOR_MAX_RUNS))
        end
    end

    for ring in rings
        in_ring::Set{Atom} = Set{Atom}()
        ring_atoms = Atom[]
        for j in 1:length(ring)
            if ring[j]
                b::Edge = index_to_edge[j].bond_
                setProperty(b, ("InRing",true))
                setProperty(b.source_.atom_, ("InRing",true))
                setProperty(b.target_.atom_, ("InRing",true))
                if !(b.source_.atom_ in in_ring)
                    push!(in_ring, b.source_.atom_)
                    push!(ring_atoms, b.source_.atom_)
                end

                if !(b.target_.atom_ in in_ring)
                    push!(in_ring, b.target_.atom_)
                    push!(ring_atoms, b.target_.atom_)
                end
            end
        end
        push!(sssr, ring_atoms)
    end

    for small_beer in all_small_beers
        in_ring::Set{Atom} = Set{Atom}()
        ring_atoms = Atom[]
        for j in 1:length(small_beer)
            if small_beer[j]
                b = index_to_edge[j].bond_
                setProperty(b, ("InRing",true))
                setProperty(b.source_.atom_, ("InRing",true))
                setProperty(b.target_.atom_, ("InRing",true))
                if !(b.source_.atom_ in in_ring)
                    push!(in_ring, b.source_.atom_)
                    push!(ring_atoms, b.source_.atom_)
                end

                if !(b.target_.atom_ in in_ring)
                    push!(in_ring, b.target_.atom_)
                    push!(ring_atoms, b.target_.atom_)
                end
            end
        end
        push!(all_small_rings, ring_atoms)
    end

    return rings

end

