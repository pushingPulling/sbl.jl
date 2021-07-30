
#module KERNEL
    include("atom.jl")
    include("atomContainer.jl")
    include("bond.jl")
    include("chain.jl")
    include("residue.jl")
    include("molecule.jl")
    include("PTE.jl")
    include("secondaryStructure.jl")
    include("system.jl")

    const CompositeType = Union{Atom,AtomContainer,Bond ,Nothing, Residue, Chain}

    #export AtomContainerMod.AtomContainer#, Atom, AtomContainer, Bond, Chain, Fragment, Molecule,
    #Element, SecondaryStructure, System

#export System, SecondaryStructure, Symbol, Element, Molecule,
#Fragment, Chain, Bond, AtomContainer, Atom

#end
#push!(LOAD_PATH,joinpath(pwd(),"src","KERNEL","common.jl"))
#=
common:
- Julia version: 
- Author: Dan
- Date: 2021-06-07
=#
