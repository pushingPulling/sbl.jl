#=
BALL:
- Julia version: 
- Author: Dan
- Date: 2021-08-19
=#
module BALL
    module COMMON
        include("./COMMON/global.jl")
        include("./COMMON/common.jl")
    end

    module CONECEPT
        using ..COMMON
        include("./CONCEPT/composite_interface.jl")
        include("./CONCEPT/timeStamp.jl")
        include("./CONCEPT/composite.jl")
        include("./CONCEPT/atom_interface.jl")
    end

    module KERNEL
        include("./KERNEL/bond.jl.jl")
        include("./KERNEL/PTE.jl")
        include("./KERNEL/atom.jl")
        include("./KERNEL/atom_bijection.jl")
        include("./KERNEL/chain.jl")
        include("./KERNEL/residue.jl")
        include("./KERNEL/system.jl")
        include("./KERNEL/.jl")
        include("./KERNEL/composite_iterator.jl")
    end

    module




end