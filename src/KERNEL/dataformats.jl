#=
dataformats:
- Julia version: 
- Author: Dan
- Date: 2021-06-14
=#

include("../COMMON/common.jl")
include("residue.jl")
include("../../src/CONCEPT/composite.jl")
include("atom.jl")
include("chain.jl")
include("system.jl")
include("../CONCEPT/composite_iterator.jl")


using DataFrames
import Base.convert
using BioStructures


mutable struct DataFrameSystem
    models  ::DataFrame
    chains  ::DataFrame
    residues::DataFrame
    atoms   ::DataFrame
    DataFrameSystem() = new(nothing,nothing,nothing,nothing)
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
        DataFrame(collectatoms(P))
    )
end

#note: this does not copy "disorderedatoms"
convert(::DataFrameSystem, P::BioStructures.ProteinStructure) = DataFrameSystem(P)


#note: this does not copy "disorderedatoms"
#gives different number of atoms than Proteinstructures
convert(return_type::Type{T} where T<:CompositeInterface, Prot::BioStructures.ProteinStructure) = begin


    #converts the children of a BioStructures-node to the matching intern (KERNEL) type
    #and then connects the new children to their siblings and their parent.
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

        #receives a vector containing the children of intern_parent
        intern_children_array = children_array
        if intern_child_type == Atom
            intern_children_array = intern_child_type[]
        end

        #since atoms have no children, simply collect them
        if intern_child_type == Atom
            for bioStructures_child in bioStructures_parent #atom
                if !isdisorderedatom(bioStructures_child)
                    push!(intern_children_array, Atom(bioStructures_child))
                end
            end
        end

        #then connect the children to their siblings
        for i = 1:length(intern_children_array)-1
            intern_children_array[i].next_ = intern_children_array[i+1]
            intern_children_array[i].parent_ = intern_parent
        end
        if length(intern_children_array) > 0
            intern_children_array[end].next_ = nothing
            intern_children_array[end].parent_ = intern_parent
            #connect the childern to the parent
            intern_parent.first_child_ = intern_children_array[begin]
            intern_parent.last_child_ = intern_children_array[end]
        end

        return intern_parent
    end

    assign_chains_to_system(
        intern_system::System,
        bio_model::BioStructures.Model,
        new_chains::Vector{Chain}
    ) = begin
        assign_x_to_y(intern_system, bio_model, Chain, BioStructures.Model, new_chains)
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
    for model in Prot   #iterate over BioStructures Types
        #create a system-object
        #create a vector for holding the children of the system
        temp_system = System(model)
        new_chains = Chain[]
        for chain in model
            temp_chain = Chain(chain)
            new_residues = Residue[]
            for residue in chain
                #for each residue in the chain, collect the residue's atoms and connect them
                temp_residue = Residue(residue)
                if !isdisorderedres(residue)
                    temp_residue = assign_atoms_to_residue(temp_residue, residue)
                    push!(new_residues, temp_residue)
                end
            end
            #the vector with the residues is finalized. assign the residues to the chain
            temp_chain = assign_residues_to_chain(temp_chain, chain,new_residues)
            push!(new_chains, temp_chain)
        end
        #the vector with the chains is finalized. assign the chain to the system
        temp_system = assign_chains_to_system(temp_system, model, new_chains)
        push!(new_systems, temp_system)
    end

    root_system = return_type()      #root of type T to return
    root_system.name_ = Prot.name

    #assign the systems to the root
    for i = 1:length(new_systems)-1
        new_systems[i].next_ = new_systems[i+1]
        new_systems[i].parent_ = root_system
    end
    new_systems[end].next_ = nothing
    new_systems[end].parent_ = root_system

    root_system.first_child_ = new_systems[begin]
    root_system.last_child_ = new_systems[end]
    root_system.next_ = nothing
    return root_system
end

#parse bonds from PDB file. Reads only "CONECT" and "SSBOND" entries
#this is a complimentary function to BioStructures parser, which does not parse bonds
PDBparseBonds(internal_representation::CompositeInterface, path::String) = begin

    return internal_representation
end

# BioStructures reads structure and internal parser only the bonds
System(path::String, input_format::FileFormats) = begin
    struc = read(path, BioStructures.PDB)
    internal_representation = convert(System, struc)
    internal_representation = PDBparseBonds(internal_representation, path)
    return internal_representation
end



BioStructures.ProteinStructure(comp::Composite) = begin

    result = BioStructures.ProteinStructure(comp.name_)

    i = 1       #counter to build Models

    #recursive behaviour:
    #for each KERNEL-node create a BioStructures equivalent and
    #an empty vector to place its children in. Then create their children in the same manner.
    #after finalizing the children, finalize the BioStructures node by putting all
    #the children in a Dict and merge it with the BioStructure node's Dict
    temp_models = BioStructures.Model[]
    for model in SystemIterator(comp)
        #for each KERNEL.system iterate over the chains to create a BioStructures.Model
        temp_model = BioStructures.Model(i,result)
        i += 1
        chains = get_children(model)
        temp_chains = BioStructures.Chain[]

        for chain in chains
            temp_chain = BioStructures.Chain(chain.id,temp_model)
            residues = get_children(chain)
            push!(temp_chain.res_list,[item.res_name_ for item in residues]...)
            residues = get_children(chain)
            temp_residues = BioStructures.Residue[]

            for residue in residues
                temp_residue = BioStructures.Residue(residue.res_name_, residue.res_number_,
                    residue.insertion_code_,residue.is_hetero_,temp_chain)
                atoms = get_children(residue)
                temp_atoms = BioStructures.Atom[]
                if atoms != nothing
                    for atom in atoms
                        push!(temp_atoms, BioStructures.Atom(atom,temp_residue))
                    end
                end
                push!(temp_residue.atom_list, [elem.name for elem in temp_atoms]...)
                merge!(temp_residue.atoms, Dict{String,AbstractAtom}(
                    at.name => at for at in temp_atoms
                ))
                push!(temp_residues, temp_residue)
            end
            merge!(temp_chain.residues,Dict{String,AbstractResidue}(
                    res.name => res for res in temp_residues
            ))
            push!(temp_chains, temp_chain)
        end
        merge!(temp_model.chains,Dict{String,BioStructures.Chain}(
                    ch.id => ch for ch in temp_chains
        ))
        push!(temp_models,temp_model)
    end
    merge!(result.models, Dict{Int,BioStructures.Model}(
        md.number => md for md in temp_models
    ))
    return result
end

#constructor for copyinga KERNEL-atom
BioStructures.Atom(at::Atom,BSres::BioStructures.Residue) = begin
    return BioStructures.Atom(at.serial_, at.name_, Char(42),
    Vector{Float64}([at.position_[1],at.position_[2],at.position_[3]]),
    at.occupancy_, at.temp_factor_, string(at.element_.symbol_),
    at.charge_ == nothing ? "" : at.charge_,
    BSres)
end



#=
code to examine the missing atoms&residues
test = convert(System, struc)
println(typeof(test))
println(countAtoms(test), " Atoms")
println(countatoms(struc))
df = DataFrameSystem(struc)
names = collect(df.atoms[:,:atomname])
tempvec = String[]
for item in test
   if isa(item,Atom)
       push!(tempvec,item.name_)
   end
end

println(length(tempvec))

for i in 1:705
    if strip(tempvec[i]) != strip(names[i])
        println(tempvec[i], " ", names[i], " ", i)
    end
end
println(names[705:end])
=#
