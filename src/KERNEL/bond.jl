#=
bond:
- Julia version: 
- Author: Dan
- Date: 2021-06-01
=#
import ..CONCEPT: getProperties, hasProperty, getProperty
export
    Order, BondType, Bond, createBond, bondExists, printBonds, ORDER__SINGLE, TYPE__COVALENT,
    TYPE__HYDROGEN, TYPE__DISULPHIDE_BRIDGE, TYPE__SALT_BRIDGE

import Base.show
import BALL.CONCEPT.setProperty

@enum Order begin
        ORDER__UNKNOWN          = 0
        ORDER__SINGLE           = 1
        ORDER__DOUBLE           = 2
        ORDER__TRIPLE           = 3
        ORDER__QUADRUPLE        = 4
        ORDER__AROMATIC         = 5
        ORDER__ANY              = 6
end

@enum BondType begin
        TYPE__UNKNOWN           = 0
        TYPE__COVALENT          = 1
        TYPE__HYDROGEN          = 2
        TYPE__DISULPHIDE_BRIDGE = 3
        TYPE__SALT_BRIDGE       = 4
        TYPE__PEPTIDE           = 5
end

mutable struct Bond
    #CompositeInterface is used as type since we can't use class `Atom`
    #because we can't forward reference it or have circular dependencies.
    #this class is only to be used with Atoms
        #the atom with the lower serial number is always the source one
        source_                      ::AtomInterface
        target_                      ::AtomInterface
        name_                        ::String
        bond_order_                  ::Order
        bond_type_                   ::BondType
        properties_                  ::Vector{Tuple{String,UInt8}}


        Bond(x::CompositeInterface, y::CompositeInterface, name::String, bond_order::Order, bond_type::BondType) = begin
            throw(ErrorException("Bonds are only allowed between Atoms. Input: $x , $y."))
        end

        Bond(x::AtomInterface, y::AtomInterface, name::String, bond_order::Order, bond_type::BondType) = begin
            if x == y
                throw(ErrorException("Bonds between the same Atom are disallowed. Input: $x , $y."))
            end
            if x.serial_ > y.serial_
                temp = x
                x = y
                y = temp
            end
            new(x,y,name,bond_order,bond_type,Vector{Tuple{String,Int8}}())
        end
end


Bond(at1::AtomInterface, at2::AtomInterface; name::String ="",
        order::Order = ORDER__ANY, type::BondType = TYPE__UNKNOWN) =
    Bond(at1,at2,name,order,type)


#creates a Bond if none already exists between two atoms
createBond(at_owner::AtomInterface, at_guest::AtomInterface; name::String ="",
        order::Order = ORDER__ANY, type::BondType = TYPE__UNKNOWN) = begin
    bondExists(at_owner,at_guest) && return nothing
    temp = Bond(at_owner, at_guest, name = name, order = order, type = type)
    at_owner.bonds_[at_guest] = temp
    at_guest.bonds_[at_owner] = temp
    return temp
end

bondExists(at1::AtomInterface, at2::AtomInterface) = begin
    return haskey(at1.bonds_,at2)
end

#deletes a bond. has no effect if a bond between the atoms was not present
deleteBond(at1::AtomInterface, at2::AtomInterface) = begin
    delete!(at1.bonds_, at2)
    delete!(at2.bonds_, at1)
    return nothing
end

printBonds(at::AtomInterface, io::IO = Base.stdout) = begin
    println(io,"$at has bonds to ",
     join(keys(at.bonds_),", "),". ")
end

getProperties(comp::Bond) = begin
    return comp.properties_
end

hasProperty(comp::Bond, property::String) = begin
    if any([property == x[1] for x in getProperties(comp) ])
       return true
    end
    return false
end


getProperty(comp::Bond, property::Tuple{String,UInt8}) = begin
    if hasProperty(comp,property)
        index = findfirst((x::Tuple{String,UInt8})-> property[1] == x[1], getProperties(comp))
        return getProperties(comp)[index][2]
    end
    return nothing
end

setProperty(comp::Bond, property::Tuple{String,UInt8}) = begin
    if hasProperty(comp,property[1])
        index = findfirst((x::Tuple{String,UInt8})-> property[1] == x[1], getProperties(comp))
        deleteat!(getProperties(comp), index)
    end
    push!(comp.properties_, property)

end
setProperty(comp::Bond, property::Tuple{String,Bool}) = setProperty(comp,(property[1],UInt8(property[2])))




Base.show(io::IO, bond::Bond) = begin
    bond_order= "Unknown-order"
    bond_type = "unknown-type"
    if bond.bond_order_ == Order(1)
        bond_order= "Single"
    elseif bond.bond_order_ == Order(2)
        bond_order= "Double"
    elseif bond.bond_order_ == Order(3)
        bond_order= "Triple"
    elseif bond.bond_order_ == Order(4)
        bond_order= "Quadruple"
    elseif bond.bond_order_ == Order(5)
        bond_order= "Aromatic"
    end

    if bond.bond_type_ == BondType(1)
        bond_type= "covalent"
    elseif bond.bond_type_ == BondType(2)
        bond_type= "hydrogen"
    elseif bond.bond_type_ == BondType(3)
        bond_type= "disulphite-bridge"
    elseif bond.bond_type_ == BondType(4)
        bond_type= "salt-bridge"
    elseif bond.bond_type_ == BondType(5)
        bond_type= "peptide"
    end

    print(io,
        "$bond_order $bond_type bond: [$(bond.source_)] -> [$(bond.target_)]")

end
