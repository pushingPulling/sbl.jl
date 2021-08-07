#=
dataformats:
- Julia version: 
- Author: Dan
- Date: 2021-06-14
=#


include("../CONCEPT/composite_iterator.jl")


using DataFrames
import Base.convert
using BioStructures

import Base.getindex

Base.getindex(x::CompositeInterface,sy::Core.Symbol) = Base.getfield(x,sy)

#following `getindex` functions are slow and only for convenience
#idea to speed it up: only collect when underlying system has been changed.
Base.getindex(x::System, i::Int) = collectChains(x)[i]
Base.getindex(x::Chain, i::Int) = collectResidues(x)[i]
Base.getindex(x::Chain, i::Int) = collectAtoms(x)[i]


#metaprogramming which defines an order of the types: System > Chain > Residue > Atom
const ops = [:<,:>]
const type = [Atom,Residue,Chain,System]
for x in type
    for y in type
        for op in ops
            @eval Base.$op(::Type{$x},::Type{$y}) =
                  (Base.$op(findfirst(lambda -> lambda == $x,$type),
                           findfirst(lambda -> lambda == $y,$type)))
        end
    end
end


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

    latest_res_number::Int64 = 0   #needed because C++ Ball simply includes both residues when
                                #there is multiple possible ones
    new_systems = System[]
    for model in Prot   #iterate over BioStructures Types
        #create a system-object
        #create a vector for holding the children of the system
        temp_system = System(model)
        new_chains = Chain[]
        for chain in model
            temp_chain = Chain(chain)
            new_residues = Residue[]
            for residue in collectresidues(chain,expand_disordered=true)
                #for each residue in the chain, collect the residue's atoms and connect them
                if residue.number != latest_res_number
                    temp_residue = Residue(residue)
                    temp_residue = assign_atoms_to_residue(temp_residue, residue)
                    push!(new_residues, temp_residue)
                    latest_res_number += 1
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



findall(start_node::CompositeInterface,target_type::Type{T}, chain_attributes=(),
        residue_attributes=(), atom_attributes=()) where T<:CompositeInterface = begin

    target_type > Chain && return start_node

    result = target_type[]
    cur_node::CompositeInterface = start_node

    if typeof(cur_node) > Chain && !isempty(chain_attributes)
        for ch in collectChains(cur_node)
            if all([ch[attr] == value for (attr,value) in pairs(chain_attributes)])
                cur_node = ch
                if target_type == Chain
                    push!(result,ch)
                end
                break
            end
        end
    end

    if target_type > Residue
        if cur_node == start_node
            return nothing
        else
            return result
        end
    end

    if typeof(cur_node) > Residue && !isempty(residue_attributes)
        for res in collectResidues(cur_node)
            if all([res[attr] == value for (attr,value) in pairs(residue_attributes)])
                cur_node = res
                if target_type == Residue
                    push!(result,res)
                end
                break
            end
        end
    end

    if target_type > Atom
        if cur_node == start_node
            return nothing
        else
            return result
        end
    end

    if typeof(cur_node) > Atom && !isempty(atom_attributes)
        for at in collectAtoms(cur_node)
            if all([at[attr] == value for (attr,value) in pairs(atom_attributes)])
                cur_node = at
                if target_type == Atom
                    push!(result,at)
                end
                break
            end
        end
    end

    cur_node == start_node && return nothing
    return result

end

import Base.findfirst
findfirst(start_node::CompositeInterface,target_type::Type{T}, chain_attributes=(),
        residue_attributes=(), atom_attributes=()) where T<:CompositeInterface = begin

    target_type > Chain && return start_node
    cur_node::CompositeInterface = start_node

    if typeof(cur_node) > Chain && !isempty(chain_attributes)
        for ch in collectChains(cur_node)
            if all([ch[attr] == value for (attr,value) in pairs(chain_attributes)])
                cur_node = ch
                break
            end
        end
    end

    if target_type > Residue
        if cur_node == start_node
            return nothing
        else
            return cur_node
        end
    end

    if typeof(cur_node) > Residue && !isempty(residue_attributes)
        for res in collectResidues(cur_node)
            if all([res[attr] == value for (attr,value) in pairs(residue_attributes)])
                cur_node = res
                break
            end
        end
    end

    if target_type > Atom
        if cur_node == start_node
            return nothing
        else
            return cur_node
        end
    end

    if typeof(cur_node) > Atom && !isempty(atom_attributes)
        for at in collectAtoms(cur_node)
            if all([at[attr] == value for (attr,value) in pairs(atom_attributes)])
                cur_node = at
                break
            end
        end
    end

    cur_node == start_node && return nothing
    return cur_node
end


#unfortunately BioStructures parses Atoms differently from C++Ball, which this function corrects
fill_in_missing_atoms(internal_representation::CompositeInterface, path::String) = begin
#ATOM lines in a PDB record whose residue 'alternate location indicator' is "A" are parsed by C++Ball
    seen_atom = false
    open(path) do file
        for line in eachline(file)
            if startswith(line, "ATOM") && line[17] == 'A'
                chain_id = string(line[22])
                residue_number = parse(Int64,strip(line[23:26]))
                target_residue = findfirst(internal_representation, Residue, (id_ = chain_id,), (res_number_ = residue_number,))

                name::String = strip(line[13:16])
                x::Float64 = parse(Float64,line[31:38])
                y::Float64 = parse(Float64,line[39:46])
                z::Float64 = parse(Float64,line[47:54])
                elem::String = strip(line[77:78])
                charge::Union{Float64,Nothing} = strip(line[79:80]) == "" ? nothing : parse(Float64,line[79:80])
                occupancy::Union{Float64,Nothing} = strip(line[55:60]) == "" ? nothing : parse(Float64,line[55:60])
                serial::Int = parse(Int,strip(line[7:11]))
                temp_factor::Union{Float64,Nothing} = strip(line[61:66]) == "" ? nothing : parse(Float64,line[61:66])
                #appendchild to residue - find right res w/ findfirst
                #use the right Atom() constructor
                appendChild(target_residue, Atom(name,x,y,z,elem,charge,occupancy,serial,temp_factor))
                seen_atom = true
            end

            if startswith(line,"HETATM") && seen_atom
                return internal_representation
            end
        end
    end
    return internal_representation
end

parseConectLine(line::String) = begin
    bonding_atoms = Int[ parse(Int,strip(line[7:11])) ]
    len_line = length(line)
    if length(line) == 16
        tokens = String[line[12:16]]
    elseif length(line) == 21
        tokens = String[line[12:16], line[17:21]]
    elseif length(line) == 26
        tokens = String[line[12:16], line[17:21],
                line[22:26]]
    else
        tokens = String[line[12:16], line[17:21],
                line[22:26], line[27:31]]
    end

    for x in tokens
        if strip(x) != ""
            push!(bonding_atoms, parse(Int,strip(x)))
        end
    end
    return bonding_atoms
end

parseAtomLine(line::String,serial::Int64) = begin

    name::String = strip(line[13:16])
    x::Float64 = parse(Float64,line[31:38])
    y::Float64 = parse(Float64,line[39:46])
    z::Float64 = parse(Float64,line[47:54])
    elem::String = strip(line[77:78])
    occupancy::Union{Float64,Nothing} = strip(line[55:60]) == "" ? nothing : parse(Float64,line[55:60])
    temp_factor::Union{Float64,Nothing} = strip(line[61:66]) == "" ? nothing : parse(Float64,line[61:66])

    if length(line) >= 80
        charge::Union{Float64,Nothing} = strip(line[79:80]) == "" ? nothing : parse(Float64,line[79:80])
    else
        charge = nothing
    end

    result = Atom(name,x,y,z,elem,charge,occupancy,serial,temp_factor)
    if startswith(line,"HET")
        setProperty(result,("hetero",true))
    end

    return result
end


SSBond = Tuple{Char,Int64}    #Tuple of chain_id and residue_number


compare_ssbonds(b1::SSBond, b2::SSBond) = begin
    b1[1] < b2[1] && return true
    b1[1] == b2[1] && b1[2] < b2[2] && return true
    return false
end


parseSSBondLine(line::String) = begin
    ssbond1 = (line[16], parse(Int,strip(line[18:21])))
    ssbond2 = (line[30] ,parse(Int,strip(line[32:35])))
    return (ssbond1, ssbond2)
end #returns 2 ssbonds
#only use following Function to build a System initially

PDBparseBonds(internal_representation::CompositeInterface, path::String) = begin
    #parse bonds from PDB file. Reads only "CONECT" and "SSBOND" entries
    #this is a complimentary function to BioStructures parser, which does not parse bonds


    add_amino_acid_properties_to_residues(internal_representation::CompositeInterface) = begin
        residues = collectResidues(internal_representation)
        for res in residues
            if getName(res) in Amino_Acids
                setProperty(res, ("amino_acid",true))
            end
        end
    end


    # `ssbonds` holds all the ssbonds in order of appearance in the file
    ssbonds = Vector{SSBond}()

    # When reading the atoms from the file, relate the atom to an SSBond endpoint
    ssbonds_to_atoms = Dict{SSBond, Int64}() #mapping ssbonds to atom serial number

    #List of pairs of atoms bonded by a SSBond
    ssbond_pairs = Vector{Tuple{SSBond,SSBond}}()

    atoms_vec = collectAtoms(internal_representation)
    atoms = Dict{Int64, Atom}(at.serial_ => at for at in atoms_vec)

    seen_ssbonds = false
    current_ssbond_index = 1


    open(path) do file
        for line in eachline(file)
            if startswith(line, "SSBOND")
                pair = parseSSBondLine(line)
                push!(ssbond_pairs, pair)
                push!(ssbonds, pair...)
                seen_ssbonds = true
            end

            if seen_ssbonds && !startswith(line,"SSBOND")
                sort!(ssbonds, alg=InsertionSort, lt = compare_ssbonds)
                seen_ssbonds = false
            end

            if (current_ssbond_index <= length(ssbonds)) && startswith(line,"ATOM")
                #find items from SSBOND
                current_ssbond = ssbonds[current_ssbond_index]
                #replace "SG" with a list of possible names of atoms which engage in ssbonds
                if ( (line[22], parse(Int,strip(line[23:26]))) == current_ssbond ) && (strip(line[13:16]) == "SG")

                    ssbonds_to_atoms[current_ssbond] = parse(Int64,strip(line[7:11]))
                    current_ssbond_index += 1

                end
            end

            if startswith(line, "CONECT")
                bonding_atom_serials = parseConectLine(line)
                for serial in bonding_atom_serials[2:end]
                    createBond(atoms[bonding_atom_serials[1]], atoms[serial],
                                order=ORDER__SINGLE, type=TYPE__COVALENT)
                end
            end
        end
    end

    #for each ssbond pair, make a bond betwen the two corresponding atoms using the dict
    for (ssbond1, ssbond2) in ssbond_pairs
        deleteBond(atoms[ssbonds_to_atoms[ssbond1]], atoms[ssbonds_to_atoms[ssbond2]])
        createBond(atoms[ssbonds_to_atoms[ssbond1]], atoms[ssbonds_to_atoms[ssbond2]],
                                order=ORDER__SINGLE, type=TYPE__DISULPHIDE_BRIDGE)
    end

    add_amino_acid_properties_to_residues(internal_representation)
    #Assign Element to each Atom

    return internal_representation
end

adjust_ter_indices(indices::Vector{Int64}, ter_pos::Vector{Int64}) = begin
    for i in 1:length(indices)
         c = 0
         for ter in ter_pos
            if indices[i] > ter
                c += 1
            end
         end
         indices[i] -= c
    end
    return indices
end

adjust_ter_indices(x::Int64, ter_pos::Vector{Int64}) = adjust_ter_indices([x],ter_pos)

parsePDB(path::String) = begin
     # `ssbonds` holds all the ssbonds in order of appearance in the file
    ssbonds = Vector{SSBond}()

    # When reading the atoms from the file, relate the atom to an SSBond endpoint
    ssbonds_to_atoms = Dict{SSBond, Int64}() #mapping ssbonds to atom serial number

    #List of pairs of atoms bonded by a SSBond
    ssbond_pairs = Vector{Tuple{SSBond,SSBond}}()

    current_ssbond_index = 1

    root = System()
    atoms::Vector{Atom} = Atom[]
    ter_positions = Int64[]

    latest_chain::Chain = Chain()  #assume chains are named in alphabetical order with capitalized letters
    latest_residue::Residue = Residue()
    latest_residue.res_number_ = 0
    atom_counter::Int = 0

    latest_chain.id_ = 'A'
    appendChild(root, latest_chain)

    seen_header = false
    ready_to_sort_ssbonds = false
    seen_ssbonds = false
    seen_atoms = false

    open(path) do file
        for line in eachline(file)
            #header
            if !seen_header && startswith(line,"HEADER")
                root.name_ = strip(line[63:66])
                seen_header = true
            end


            if startswith(line,"TER")
                push!(ter_positions, parse(Int64,strip(line[7:11])))
            end


            #save infos about the atoms which participate in ssbonds
            if !seen_ssbonds && startswith(line, "SSBOND")
                pair = parseSSBondLine(line)
                push!(ssbond_pairs, pair)
                push!(ssbonds, pair...)
                ready_to_sort_ssbonds = true
            end

            #after having seen all of the ssbonds sort them to later find the correct atoms easier
            if ready_to_sort_ssbonds && !startswith(line,"SSBOND")
                seen_ssbonds = true
                ready_to_sort_ssbonds = false
                sort!(ssbonds, alg=InsertionSort, lt = compare_ssbonds)
                #println("quick test:", issorted([x.res_number_ for x in residues]))
            end

            #atoms of name "SG" belong to ssbonds. associate atom to ssbond entry
            if (current_ssbond_index <= length(ssbonds)) && startswith(line,"ATOM") &&
                                                           (strip(line[13:16]) == "SG")
                #find items from SSBOND
                current_ssbond = ssbonds[current_ssbond_index]
                #replace "SG" with a list of possible names of atoms which engage in ssbonds
                if ( (line[22], parse(Int,strip(line[23:26]))) == current_ssbond )
                    ssbonds_to_atoms[current_ssbond] = adjust_ter_indices(parse(Int64,strip(line[7:11])), ter_positions)[1]
                    current_ssbond_index += 1
                end
            end



            if (!seen_atoms && startswith(line,"ATOM") ||
                                !seen_atoms && startswith(line,"HETATM"))  &&
                                line[17] in (' ','A')
                atom_counter += 1
                record_chain_id = line[22]
                record_residue_name = strip(line[18:20])
                record_residue_number = parse(Int64,strip(line[23:26]))

                #create chain if new chain
                if record_chain_id != latest_chain.id_
                    #is the next residues belong to another chain, create the chain
                    latest_chain = Chain()
                    latest_chain.id_ = record_chain_id
                    appendChild(root, latest_chain)
                end

               if record_residue_number != latest_residue.res_number_
                    latest_residue = Residue()
                    latest_residue.res_number_ = record_residue_number
                    latest_residue.name_ = record_residue_name
                    latest_residue.is_hetero_ = false
                    if latest_residue.name_ in Amino_Acids
                        setProperty(latest_residue, ("amino_acid",true))
                    end
                    appendChild(latest_chain, latest_residue)

                end
               #create atoms

                parsed_atom = parseAtomLine(line, atom_counter)
                appendChild(latest_residue, parsed_atom)
            end


            if startswith(line, "CONECT")

                if seen_atoms == false
                    #atoms = collectAtoms(root)      #fu
                    seen_atoms = true
                    atoms = collectAtoms(root)
                end

                bonding_atom_serials = parseConectLine(line)
                bonding_atom_serials = adjust_ter_indices(bonding_atom_serials, ter_positions)
                for serial in bonding_atom_serials[2:end]
                    createBond(atoms[bonding_atom_serials[1]], atoms[serial],
                                order=ORDER__SINGLE, type=TYPE__COVALENT)
                end
            end
        end
    end

    #for each ssbond pair, make a bond betwen the two corresponding atoms using the dict
    for (ssbond1, ssbond2) in ssbond_pairs
        deleteBond(atoms[ssbonds_to_atoms[ssbond1]], atoms[ssbonds_to_atoms[ssbond2]])
        a = createBond(atoms[ssbonds_to_atoms[ssbond1]], atoms[ssbonds_to_atoms[ssbond2]],
                                order=ORDER__SINGLE, type=TYPE__DISULPHIDE_BRIDGE)
    end

    return root
end


# BioStructures reads structure and internal parser only the bonds
System(path::String) = begin
#old version suing BioStructures

    #struc = read(path, BioStructures.PDB)
    #internal_representation = convert(System, struc)
    #internal_representation = fill_in_missing_atoms(internal_representation, path)
    #internal_representation = PDBparseBonds(internal_representation, path)
    #return internal_representation

#own parser
    if endswith(path, ".pdb")
       return parsePDB(path)
    end

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
        chains = getChildren(model)
        temp_chains = BioStructures.Chain[]

        for chain in chains
            temp_chain = BioStructures.Chain(chain.id,temp_model)
            residues = getChildren(chain)
            push!(temp_chain.res_list,[item.name_ for item in residues]...)
            residues = getChildren(chain)
            temp_residues = BioStructures.Residue[]

            for residue in residues
                temp_residue = BioStructures.Residue(residue.name_, residue.res_number_,
                    residue.insertion_code_,residue.is_hetero_,temp_chain)
                atoms = getChildren(residue)
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

#constructor for copying a KERNEL-atom
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