#=
file1:
- Julia version: 
- Author: Dan
- Date: 2021-07-28
=#
include("safe_includer.jl")
@safe_include("file2.jl")
println("included 1")



ghey()