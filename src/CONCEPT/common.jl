#=
common:
- Julia version: 
- Author: Dan
- Date: 2021-06-09
=#
module CONCEPT


export CompositeType, Composite, CompositeInterface, TimeStamp, PreciseTime


end
push!(LOAD_PATH,joinpath(pwd(),"src","CONCEPT","common.jl"))