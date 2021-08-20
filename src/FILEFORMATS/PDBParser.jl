#=
PDBParser:
- Julia version: 
- Author: Dan
- Date: 2021-08-20
=#
import ..KERNEL.System
#export System

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
    latest_residue.res_number_ = -127   #init value, which hopefully is NOT the same as the first residue-number in the file
    atom_counter::Int = 0

    latest_chain.id_ = '-'  #init value, which hopefully is NOT the same as the first chain id in the file
    appendChild(root, latest_chain)

    seen_header = false
    ready_to_sort_ssbonds = false
    seen_ssbonds = false
    seen_atoms = false

    open(path) do file
        for line in eachline(file)
            #header
            if !seen_header && startswith(line,"HEADER")
                if length(line) >= 66
                    root.name_ = strip(line[63:66])
                else
                    temp = findlast("/",path)
                    if isnothing(temp)
                       root_name_ = path[1:end-4]
                    else
                        root.name_ = path[temp[1]+1:end-4]
                    end
                end
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
                latest_chain.id_ == '-' && (latest_chain.id_ = record_chain_id)
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
function System(path::String)
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
