#=
ring_perception_processor:
- Julia version: 
- Author: Dan
- Date: 2021-08-05
=#
export SSSR

SSSR(root::CompositeInterface) = begin
    if length(collectBonds(root)) - length(collectAtoms(root)) + 1 < 1
        println("No cycles possible")
        return Vector{Edge}[], Set{Atom}()
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
    sssr::Vector{Vector{Edge}} = minimum_cycle_basis(graph)
    ring_atoms::Set{Atom} = Set{Atom}()
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
