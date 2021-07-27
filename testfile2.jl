using DataFrames
include("src/KERNEL/residue.jl")
include("src/CONCEPT/composite.jl")
include("src/KERNEL/atom.jl")
include("src/KERNEL/chain.jl")
include("src/KERNEL/system.jl")

import Base.convert
using BioStructures

struc = read("1EN2.pdb", PDB)

mutable struct DataFrameSystem
    models::DataFrame
    chains::DataFrame
    residues::DataFrame
    atoms::DataFrame
    DataFrameSystem() = new()
    DataFrameSystem(
        models::DataFrame,
        chains::DataFrame,
        residues::DataFrame,
        atoms::DataFrame,
    ) = new(models, chains, residues, atoms)
end

#note: this does not copy "disorderedatoms"
DataFrameSystem(P::BioStructures.ProteinStructure) = begin
    DataFrameSystem(
        DataFrame(collectmodels(P)),
        DataFrame(collectchains(P)),
        DataFrame(collectresidues(P)),
        DataFrame(collectatoms(P)),
    )
end

#note: this does not copy "disorderedatoms"
convert(::DataFrameSystem, P::BioStructures.ProteinStructure) = DataFrameSystem(P)

#note: this does not copy "disorderedatoms"
convert(::Type{T} where T<:CompositeInterface, P::BioStructures.ProteinStructure) = begin
println("hgre")

    #=
    function assign_atoms_to_residue(intern_residue::Residue,bio_residue::BioStructures.Residue)
        temp_atoms = Atom[]
        for p_atom in bio_residue #atom
            if isdisorderedatom(p_atom)
                break;
            end
            push!(temp_atoms, Atom(p_atom))
        end
        for i in 1:length(temp_atoms)
            temp_atoms[i].next_ = temp_atoms[i+1]
            temp_atoms[i].first_child_ = temp_atoms[i].last_child_ = nothing
            temp_atoms[i].parent_ = intern_residue
        end
        temp_atoms[end].next_ = nothing

        intern_residue.first_child_ = temp_atoms[begin]
        intern_residue.last_child_ = temp_atoms[end]
        return intern_residue
    end

    =#
    #=
    function assign_residues_to_chain(intern_chain::Chain, bio_chain::BioStructures.Chain)
        temp_residues = Residue[]
        for p_residue in bio_chain #atom

            push!(temp_residues, Residue(p_residue))

        end

        for i in 1:length(temp_residues)
            temp_residues[i].next_ = temp_residues[i+1]
            temp_residues[i].first_child_ = temp_residues[i].last_child_ = nothing
            temp_residues[i].parent_ = intern_chain
        end
        temp_residues[end].next_ = nothing

        intern_chain.first_child_ = temp_residues[begin]
        intern_chain.last_child_ = temp_residues[end]
        return intern_chain
    end
    =#

    function assign_x_to_y(
        intern_parent::Union{Atom,Residue,Chain,System},
        bioStructures_parent::Union{
            BioStructures.Atom,
            BioStructures.Residue,
            BioStructures.Chain,
            BioStructures.Model,
        },
        intern_type::Union{Atom,Residue,Chain,System},
        bioStructures_type::Union{
            BioStructures.Atom,
            BioStructures.Residue,
            BioStructures.Chain,
            BioStructures.Model,
        },
        children_array::Union{
            Vector{Atom},
            Vector{Residue},
            Vector{Chain},
            Vector{System},
        }
    )
        println("hgre")
        if intern_type == Atom
            intern_children_array = intern_type[]
        else
            intern_children_array = children_array
        end

        if intern_type == Atom

            for bioStructures_child in bioStructures_parent #atom

                push!(intern_children_array, intern_type(bioStructures_child))

            end
        end

        for i = 1:length(intern_children_array)
            intern_children_array[i].next_ = intern_children_array[i+1]
            if intern_type == Atom
                intern_children_array[i].first_child_ =
                    intern_children_array[i].last_child_ = nothing
            end
            intern_children_array[i].parent_ = intern_parent
        end
        intern_children_array[end].next_ = nothing
        intern_children_array[end].parent_ = intern_parent


        intern_parent.first_child_ = temp_intern_children_array[begin]
        intern_parent.last_child_ = temp_intern_children_array[end]
        return intern_parent
    end

    assign_chains_to_system(
        intern_system::System,
        bio_model::BioStructures.Model,
    ) = begin
        assign_x_to_y(intern_System, bio_model, System, BioStructures.Model)
    end

    assign_residues_to_chain(
        intern_chain::Chain,
        bio_chain::BioStructures.Chain,
    ) = begin
        assign_x_to_y(intern_chain, bio_chain, Chain, BioStructures.Chain)
    end

    assign_atoms_to_residue(
        intern_residue::Residue,
        bio_residue::BioStructures.Residue,
    ) = begin
        assign_x_to_y(intern_residue, bio_residue, Residue, BioStructures.Residue)
    end

    #=
    function assign_chains_to_system(intern_system::System, bio_model::BioStructures.Model)
        temp_chains = Chains[]
        for p_chain in bio_model #atom

            push!(temp_chains, Chain(p_chain))

        end

        for i in 1:length(temp_chains)
            temp_chains[i].next_ = temp_chains[i+1]
            temp_chains[i].first_child_ = temp_chains[i].last_child_ = nothing
            temp_chains[i].parent_ = intern_system
        end
        temp_chains[end].next_ = nothing

        intern_system.first_child_ = temp_chains[begin]
        intern_system.last_child_ = temp_chains[end]
        return intern_system
    end
    =#
    println("hgre")
    new_systems = System[]
    for model in P              #System
        temp_system = System(model)
        println("hgre")
        new_chains = Chain[]
        for chain in model#chain
            temp_chain = Chain(chain)
            new_residues = Residue[]
            for residue in chain    #fragment.residue
                temp_residue = Residue(residue)
                temp_residue =
                    assign_atoms_to_residue(temp_residue, residue)

                push!(new_residues, temp_residue)
            end

            temp_chain = assign_residues_to_chain(temp_chain, chain)
            push!(new_chains, temp_chain)

        end
        temp_system = assign_chains_to_system(temp_system, model)
        push!(new_systems, temp_system)
    end

    #this produces a system holding systems
    root_system = System()      #maybe write contructor here?
    for i = 1:length(new_systems)-1
        new_systems[i].next_ = new_systems[i+1]
        new_systems[i].parent_ = root_system
    end
    new_systems[end].next_ = nothing
    new_systems[end].parent_ = root_System

    root_system.first_child_ = new_system[begin]
    root_system.last_child_ = new_system[end]
    return root_system

end

println(System <: CompositeInterface)
test = convert(System, struc)

