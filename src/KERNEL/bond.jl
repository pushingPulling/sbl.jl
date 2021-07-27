#=
bond:
- Julia version: 
- Author: Dan
- Date: 2021-06-01
=#
include("atom_interface.jl")
import Base.show

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
        #the atom with the lower serial number is always the first one
        first_                       ::AtomInterface
        second_                      ::AtomInterface
        name_                        ::String
        bond_order_                  ::Order
        bond_type_                   ::BondType

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
            new(x,y,name,bond_order,bond_type)
        end
end

Bond(at1::AtomInterface, at2::AtomInterface; name::String ="",
        order::Order = ORDER__ANY, type::BondType = TYPE__UNKNOWN) =
    Bond(at1,at2,name,order,type)

createBond(at_owner::AtomInterface, at_guest::AtomInterface; name::String ="",
        order::Order = ORDER__ANY, type::BondType = TYPE__UNKNOWN) = begin
    temp = Bond(at_owner, at_guest, name = name, order = order, type = type)
    at_owner.bonds_[at_guest] = temp
    at_guest.bonds_[at_owner] = temp
    return temp
end

printBonds(at::AtomInterface, io::IO = Base.stdout) = begin
    print(io,"$at has bonds to ",
     join(keys(at.bonds_),", "),".")
end



Base.show(io::IO, bond::Bond) = begin
    bond_order= "Unknown-order"
    bond_type = "unknown-type"
    if bond.bond_order_ == 1
        bond_order= "Single"
    elseif bond.bond_order_ == 2
        bond_order= "Double"
    elseif bond.bond_order_ == 3
        bond_order= "Triple"
    elseif bond.bond_order_ == 4
        bond_order= "Quadruple"
    elseif bond.bond_order_ == 5
        bond_order= "Aromatic"
    end

    if bond.bond_type_ == 1
        bond_type= "covalent"
    elseif bond.bond_type_ == 2
        bond_type= "hydrogen"
    elseif bond.bond_type_ == 3
        bond_type= "disulphite-bridge"
    elseif bond.bond_type_ == 4
        bond_type= "salt-bridge"
    elseif bond.bond_type_ == 5
        bond_type= "peptide"
    end

    print(io,
        "$bond_order $bond_type bond: [$(bond.first_)] -> [$(bond.second_)]")

end
