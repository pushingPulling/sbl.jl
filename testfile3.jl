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
    convert(::Type{T} where T<:CompositeInterface, Prot::BioStructures.ProteinStructure) = begin


        function assign_x_to_y(
            intern_parent::Union{Atom,Residue,Chain,System},
            bioStructures_parent::Union{
                BioStructures.Atom,
                BioStructures.Residue,
                BioStructures.Chain,
                BioStructures.Model
            },
            intern_child_type::Union{Type{Atom},Type{Residue},Type{Chain},Type{System}},
            bioStructures_type::Union{
                Type{BioStructures.Atom},
                Type{BioStructures.Residue},
                Type{BioStructures.Chain},
                Type{BioStructures.Model}
            },
            children_array::Union{
                Vector{Atom},
                Vector{Residue},
                Vector{Chain},
                Vector{System}
            }
        )
            if intern_child_type == Atom
                intern_children_array = intern_child_type[]
            else
                intern_children_array = children_array
            end

            if intern_child_type == Atom

                for bioStructures_child in bioStructures_parent #atom
                    if!isdisordered(bioStructures_child)
                        push!(intern_children_array, Atom(bioStructures_child))
                    end
                end
            end

            for i = 1:length(intern_children_array)-1
                intern_children_array[i].next_ = intern_children_array[i+1]
                intern_children_array[i].parent_ = intern_parent
            end
            intern_children_array[end].next_ = nothing
            intern_children_array[end].parent_ = intern_parent


            intern_parent.first_child_ = intern_children_array[begin]
            intern_parent.last_child_ = intern_children_array[end]
            return intern_parent
        end

        assign_chains_to_system(
            intern_system::System,
            bio_model::BioStructures.Model,
            new_chains::Vector{Chain}
        ) = begin
            assign_x_to_y(intern_System, bio_model, Chain, BioStructures.Model, new_chains)
        end

        assign_residues_to_chain(
            intern_chain::Chain,
            bio_chain::BioStructures.Chain,
            new_residues::Vector{Residue}
        ) = begin
            assign_x_to_y(intern_chain, bio_chain, Residue, BioStructures.Chain, new_residues)
        end

        assign_atoms_to_residue(
            intern_residue::Residue,
            bio_residue::BioStructures.Residue,
        ) = begin
            assign_x_to_y(intern_residue, bio_residue, Atom, BioStructures.Residue,Atom[])
        end


        new_systems = System[]
        for model in Prot              #System
            temp_system = System(model)
            new_chains = Chain[]
            for chain in model#chain
                temp_chain = Chain(chain)
                new_residues = Residue[]
                for residue in chain    #fragment.residue
                    temp_residue = Residue(residue)
                    if !isdisorderedres(residue)
                        temp_residue = assign_atoms_to_residue(temp_residue, residue)
                        push!(new_residues, temp_residue)
                    end
                end
                temp_chain = assign_residues_to_chain(temp_chain, chain,new_residues)
                push!(new_chains, temp_chain)
            end
            temp_system = assign_chains_to_system(temp_system, model, new_chains)
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

test = convert(System, struc)

