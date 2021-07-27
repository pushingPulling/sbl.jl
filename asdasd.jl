#=
asdasd:
- Julia version: 
- Author: Dan
- Date: 2021-06-10
=#

using DataFrames
using BioStructures
println(Residue)
include("src/CONCEPT/composite.jl")
println(Residue)
include("src/KERNEL/atom.jl")
println(Residue)
include("src/KERNEL/residue.jl")

