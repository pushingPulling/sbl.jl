#=
file2:
- Julia version: 
- Author: Dan
- Date: 2021-07-28
=#
include("safe_includer.jl")
@safe_include("file1.jl")
println("included 2")

ghey() = println("22")