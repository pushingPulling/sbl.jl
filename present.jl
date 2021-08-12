#=
present:
- Julia version: 
- Author: Dan
- Date: 2021-08-12
=#

include("G:/Python Programme/sbl.jl/testfile.jl")
internal
getchildren(internal)
methodswith(typeof(internal))
methodswith(supertype(typeof(internal)))
getChildren(internal)
chain = getChildren(internal)[1]
getChildren(chain)
residue = getChildren(chain)[1]
getChildren(residue)

bonds = collectBonds(internal)
Base.show(io::IO, at::Atom) = print(io, at.serial_)
sort!(bonds, lt = (x,y) -> x.source_.serial_ < y.source_.serial_)
