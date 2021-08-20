#=
safe_includer:
- Julia version: 
- Author: Dan
- Date: 2021-07-28
=#

if !@isdefined already_included
    const already_included = Dict{String,Vector{Module}}()
end

isincluded(mod::Module, file_path::String) = begin
    if !haskey(already_included, abspath(file_path))
        already_included[abspath(file_path)] = Module[mod]
        return false
    end

    if haskey(already_included, abspath(file_path))  && !(mod in already_included[abspath(file_path)])
         push!(already_included[abspath(file_path)], mod)
         return false
    end
    return true
end

macro safe_include(file_path::String)
    if !isincluded(__module__,file_path)
        println(already_included)
        return :( include($file_path) )
    end
end
