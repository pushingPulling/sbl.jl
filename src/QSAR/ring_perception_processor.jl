#=
ring_perception_processor:
- Julia version: 
- Author: Dan
- Date: 2021-08-05
=#

include("../STRUCTURE/simple_molecular_graph.jl")

abstract type TNodeAbs end

struct PathMessage
    beep    ::BitVector
    nfirst  ::TNodeAbs
    nlast   ::TNodeAbs
    efirst  ::Edge
    PathMessage(beep::BitVector, nfirst::TNodeAbs, nlast::TNodeAbs,efirst::Edge) = new(beep,nfirst,nlast,efirst)
end

struct BalducciParams
    rings               ::Vector{BitVector}     #SSSR detected by algorithm
    matrix              ::Vector{BitVector}     #matrix for independecy tests
    forwarded_rings     ::Vector{BitVector}     #rings of i-th phase to be forwarded to ring selector
    tested_beers        ::Vector{BitVector}     #already tested beers
    all_small_rings     ::Vector{Atom}          #contains all 3 to 6 membered rings after the procedure of the Balducci-Pearlman algorithm
    all_small_beers     ::Vector{BitVector}     #contains 3 to 6 membered rings as beers

    BalducciParams() = new(BitVector[], BitVector[],BitVector[],BitVector[],Atom[],BitVector[])
    BalducciParams(rings::Vector{BitVector}, matrix::Vector{BitVector}, forwarded_rings::Vector{BitVector},
                    tested_beers::Vector{BitVector}, all_small_rings::Vector{Atom},
                    all_small_beers::Vector{BitVector}) = new(rings, matrix, forwarded_rings,
                                                    tested_beers, all_small_rings, all_small_beers)
end

tnode_counter = 0
struct TNode <: TNodeAbs
    receive_buffer  ::Vector{PathMessage}
    send_buffer     ::Vector{PathMessage}
    serial::Int64
    TNode() = begin global tnode_counter += 1; new(PathMessage[], PathMessage[], tnode_counter) end
    TNode(receive_buffer_::Vector{PathMessage}, send_buffer_::Vector{PathMessage}) = begin global tnode_counter += 1;new(
                                                                receive_buffer_, send_buffer_, tnode_counter) end
    TNode(receive_buffer_::Vector{PathMessage}, send_buffer_::Vector{PathMessage}, serial::Int64) = new(
                                    receive_buffer_, send_buffer_, serial)
end

Base.show(io::IO, tn::TNode) = print(io, "TN[$(tn.serial )]")


nodeIsNew(beep::BitVector, node::Node, index_to_edge::Bijection{Int64,Edge}) = begin
    for (i,bit) in enumerate(beep)
        if bit
            edge::Edge = index_to_edge[i]
            if edge.source_ == node || edge.target_ == node
                return false
            end
        end
    end
    return true
end
getBalducciParams(params::BalducciParams) = begin
    return(params.rings  ,
           params.matrix         ,
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

haveSingleIntersection(beep1::BitVector, beep2::BitVector) = begin
    is_found::Bool = false
    for i in 1:length(beep1)
        if beep1[i] && beep2[i]
            if is_found
                 return false
            else
                is_found = true
            end
        end
    end
    return is_found
end

haveZeroIntersection(beep1::BitVector, beep2::BitVector) = begin
    return !any(beep1[i] && beep2[i] for i in 1:length(beep1))
end


calculateSSSR(root::CompositeInterface) = begin
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

    sssr,params = BalducciPearlmanAlgorithm(graph)

    for atom in collectAtoms(root)
        if !hasProperty(atom,"InRing")
            setProperty(atom,("InRing",false))
        end
    end

    return sssr, params
end

BalducciPearlmanRingSelector_(beer::BitVector, params::BalducciParams) = begin
    rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings ,all_small_beers = getBalducciParams(params)

    if isempty(rings)
        push!(rings, beer)
        push!(matrix, beer)
        return BalducciParams(rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings, all_small_beers)
    end

    new_beer::BitVector = deepcopy(beer)
    hi_bit::Int64 = 1
    r_begin::Int64 = 1

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
                    new_beer .⊻= matrix[r]
                    break
                end
                r +=1
            end
        end
    end

    if sum(new_beer) < 3
        return BalducciParams(rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings, all_small_beers)
    end

    beer_index::Int64 = findfirst(x->x, new_beer)  #finds the first "true" value in vector

    inserted = false
    cur_col::Int64 = 1
    for (i,row) in enumerate(matrix)
        while !row[cur_col]
            cur_col += 1
        end
        if cur_col > beer_index
            insert!(matrix, i, new_beer)
            inserted = true
            break
        end
    end
    !inserted && insert!(matrix, length(matrix), new_beer)

    push!(rings, beer)
    return BalducciParams(rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings,all_small_beers )
end

toggleBit(x::BitVector, i) =  (x[i] ⊻= 1)


send(tnode::TNode, node_to_tnode::Bijection{Node,TNode}, index_to_edge::Bijection{Int64,Edge}) = begin
    for pm in tnode.send_buffer
        a::Node = node_to_tnode(tnode)
        for edge in collectPartnerEdges(a)
            if edge.source_ == a
                partner::TNode = node_to_tnode[edge.target_]
            else
                partner = node_to_tnode[edge.source_]
            end

            if (partner != pm.nlast) && !pm.beep[index_to_edge(edge)] &&
                        nodeIsNew(pm.beep, node_to_tnode(partner), index_to_edge)
                new_pm = PathMessage(pm.beep, pm.nfirst, tnode, pm.efirst)
                new_pm.beep[index_to_edge(edge)] = true
                push!(partner.receive_buffer, new_pm)
                #println("sender: receivebuf ", length(partner.receive_buffer), " ", partner, " snd: ", tnode)
            end
        end
    end
    #clear the send_buffer
    return TNode(tnode.receive_buffer, PathMessage[],tnode.serial)
end


receive(tnode::TNode, forwarded_rings::Vector{BitVector}) = begin
    A_Type = Dict{Edge,Dict{TNode, Vector{PathMessage}}}
    array_A::A_Type = A_Type()
    do_not_forward::Vector{BitVector} = BitVector[]

    #println("start dumbo")
    for pm in tnode.receive_buffer
        if !haskey(array_A, pm.efirst)
            #println("nothas ", pm.efirst)
            array_A[pm.efirst] = Dict{TNode, Vector{PathMessage}}()
            array_A[pm.efirst][pm.nfirst] = PathMessage[pm]
        end
        push!(array_A[pm.efirst][pm.nfirst], pm)
    #    println("len pmvec ",length(array_A[pm.efirst][pm.nfirst]))
    end
    #println("end dumbo")

    #merge the messages
    for tnode_to_pm_vector in values(array_A)
        for (tnode, pm_vector) in pairs(tnode_to_pm_vector)
            if length(pm_vector) > 1
                 println("receive $(tnode.serial) newsmsg")
                 println("receive ")
                 new_message = PathMessage[]
                 push!(new_message, pm_vector[1])
                 push!(do_not_forward, [pm.beep for pm in pm_vector[2:end]]...)
                 #delete!(tnode_to_pm_vector, tnode)
                 tnode_to_pm_vector[tnode] = new_message
            end
        end
    end

    #inverse edge collisions
    array_B::Dict{TNode, Vector{PathMessage}} = Dict{TNode, Vector{PathMessage}}()
    tnode_to_pms = collect(values(array_A))
    for tnode_to_pm_vector in values(array_A)
    println("values array_A ", values(array_A))

        #take out 2 dicts of values(array_A) and compare dict1.pm to dict2.pm
    #for i in 1:length(tnode_to_pms)
        #for j in i+1:length(tnode_to_pms)




        tnodes = collect(keys(tnode_to_pm_vector))
        pm_vectors = collect(values(tnode_to_pm_vector))
        println("receive $(tnode.serial) lenpm $(length(pm_vectors))")
        for i in 1:length(pm_vectors)
            for j in i + 1:length(pm_vectors)
                if haveSingleIntersection(pm_vectors[i][1].beep, pm_vectors[j][1].beep)
                    beer::BitVector = pm_vectors[i][1].beep .| pm_vectors[j][1].beep    # .| is the broadcasted or operator
                    println("receive $(tnode.serial) sum beer = $(sum(beer))")
                    push!(forwarded_rings, beer)    #in params?
                    push!(do_not_forward, pm_vectors[i].beep, pm_vectors[j].beep)
                end
            end
            if !haskey(array_B, tnodes[i])
                array_B[tnodes[i]] = PathMessage[]
            end
            push!(array_B[tnodes[i]], pm_vectors[i][1])
        end
    end

    #handle collisions
    for (tnode,pm_vectors) in pairs(array_B)
        for i in 1:length(pm_vectors)
            for j in i+1:length(pm_vectors)
                if haveZeroIntersection(pm_vectors[i].beep, pm_vectors[j].beep)
                    beer = pm_vectors[i].beep .| pm_vectors[j].beep
                    push!(forwarded_rings, beer)
                    push!(do_not_forward, pm_vectors[i].beep, pm_vectors[j].beep)
                end
            end
        end
    end


    for pm in tnode.receive_buffer
        if !(pm.beep in do_not_forward)
            push!(tnode.send_buffer, pm)
        end
    end

    return TNode(PathMessage[], tnode.send_buffer, tnode.serial), forwarded_rings
end


BalducciPearlmanAlgorithm(graph::MolecularGraph) = begin
    #usage: node_to_tnode[node] => returns a TNode
    #usage: node_to_tnode(tnode) => returns a Node
    # it updates operations on it autmatically
    current_params = BalducciParams()

    rings = current_params.rings
    matrix = current_params.matrix
    forwarded_rings = current_params.forwarded_rings
    tested_beers = current_params.tested_beers
    all_small_rings = current_params.all_small_rings
    all_small_beers  = current_params.all_small_beers

    num_nodes = getNumberOfNodes(graph)
    num_edges = getNumberOfEdges(graph)

    node_to_tnode::Bijection{Node,TNode} = Bijection{Node,TNode}()
    for node in collectNodes(graph)
        node_to_tnode[node] = TNode()
    end

    index_to_edge::Bijection{Int64,Edge} = Bijection{Int64,Edge}()
    for (i,edge) in enumerate(collectEdges(graph))
        index_to_edge[i] = edge
    end

    sssr::Vector{Vector{Atom}} = Vector{Atom}[]

    #fill in the messages
    for node in collectNodes(graph)
        for edge in collectPartnerEdges(node)
        #edge.source_ == node && println(node.atom_.serial_, " ", edge)
            beep::BitVector = falses((num_nodes))
            toggleBit(beep, index_to_edge(edge))

            if edge.source_ == node
                 tnode::TNode = node_to_tnode[edge.target_]
            else
                 tnode = node_to_tnode[edge.source_]
            end
            pm = PathMessage(beep, tnode, tnode, edge)
            push!(node_to_tnode[node].send_buffer, pm)
        end
    end
    #println("tnodes - expect 1 tnode per edge,len: $(length(node_to_tnode))")
    #foreach(println, node_to_tnode)
    num_rings::Int64 = num_edges - num_nodes +1
    count::Int64 = 1

    graph_nodes = collectNodes(graph)
#--------------------
    while length(rings) < num_rings
        println("iter ",count)
        count += 1
        for node in graph_nodes
            temp_tnode::TNode = send(node_to_tnode[node], node_to_tnode, index_to_edge)
            delete!(node_to_tnode, node)
            node_to_tnode[node] = temp_tnode
        end

        println("forw before rec", forwarded_rings)
        for node in graph_nodes
            (temp_tnode::TNode, forwarded_rings) = receive(node_to_tnode[node],forwarded_rings)
            delete!(node_to_tnode, node)
            node_to_tnode[node] = temp_tnode
        end
        println("forw after rec", forwarded_rings)

        even_sized::Vector{BitVector} = BitVector[]
        for bit_vec in forwarded_rings
            println("sum before s1 ", sum(bit_vec), !(bit_vec in tested_beers))
            if sum(bit_vec) == 2*count -1
                if !(bit_vec in tested_beers)
                    push!(tested_beers, bit_vec)
                    println("rings before s1 ", length(rings))
                    println("matri before s1 ", length(matrix))
                    rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings_ ,all_small_beers =
                            getBalducciParams(BalducciPearlmanRingSelector_(bit_vec,
                                    BalducciParams(rings, matrix ,forwarded_rings ,tested_beers
                                                            ,all_small_rings_ ,all_small_beers)))
                    println("rings after s1 ", length(rings))
                    println("matri after s1 ", length(matrix))
                    if sum(bit_vec) == 3 ||sum(bit_vec) == 5
                        push!(all_small_beers, bit_vec)
                    end
                end
            else
                push!(even_sized, bit_vec)
            end
        end

        #even sized
        dcount = 0
        for bit_vec in even_sized
            println("sum before s2 ", sum(bit_vec), !(bit_vec in tested_beers))
            if !(bit_vec in tested_beers)
                push!(tested_beers, bit_vec)
                println("rings before s2 ", length(rings))
                println("matri before s2 ", length(matrix))
                rings, matrix ,forwarded_rings ,tested_beers ,all_small_rings ,all_small_beers =
                getBalducciParams(BalducciPearlmanRingSelector_(bit_vec,
                        BalducciParams(rings, matrix ,forwarded_rings ,tested_beers
                                                        ,all_small_rings ,all_small_beers)))
                println("rings after s2 ", length(rings))
                println("matri after s2 ", length(matrix))
                if sum(bit_vec) == 4 || sum(bit_vec) == 6
                    push!(all_small_beers, bit_vec)
                end
            end
            dcount += 1
        end
        forwarded_rings = BitVector[]
        if count > BALL_QSAR_RINGPERCEEPTIONPROCESSOR_MAX_RUNS
            throw(TooManyIterationsException(BALL_QSAR_RINGPERCEEPTIONPROCESSOR_MAX_RUNS))
        end
        println()
    end

    for ring in rings
        in_ring::Set{Atom} = Set{Atom}()
        ring_atoms::Vector{Atom} = Atom[]
        for j in 1:length(ring)
            if ring[j]
                b::Bond = index_to_edge[j].bond_
                setProperty(b, ("InRing",true))
                setProperty(b.source_, ("InRing",true))
                setProperty(b.target_, ("InRing",true))
                if !(b.source_ in in_ring)
                    push!(in_ring, b.source_)
                    push!(ring_atoms, b.source_)
                end

                if !(b.target_ in in_ring)
                    push!(in_ring, b.target_)
                    push!(ring_atoms, b.target_)
                end
            end
        end
        push!(sssr, ring_atoms)
    end

    for small_beer in all_small_beers
        in_ring::Set{Atom} = Set{Atom}()
        ring_atoms::Vector{Atom} = Atom[]
        for j in 1:length(small_beer)
            if small_beer[j]
                b = index_to_edge[j].bond_
                setProperty(b, ("InRing",true))
                setProperty(b.source_, ("InRing",true))
                setProperty(b.target_, ("InRing",true))
                if !(b.source_ in in_ring)
                    push!(in_ring, b.source_)
                    push!(ring_atoms, b.source_)
                end

                if !(b.target_ in in_ring)
                    push!(in_ring, b.target_)
                    push!(ring_atoms, b.target_)
                end
            end
        end
        push!(all_small_rings, ring_atoms)
    end

    return sssr, BalducciParams(rings, matrix ,forwarded_rings ,tested_beers
                                                        ,all_small_rings ,all_small_beers)

end

