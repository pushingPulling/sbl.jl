#=
BALL:
- Julia version: 
- Author: Dan
- Date: 2021-08-19
=#
module BALL
            using Bijections
        using StaticArrays
        #require bijections, DataFrames
    module COMMON
        include("./COMMON/global.jl")
        include("./COMMON/common.jl")
    end

    module CONCEPT
        using ..COMMON
        include("./CONCEPT/selectable.jl")
        include("./CONCEPT/composite_interface.jl")
        include("./CONCEPT/timeStamp.jl")
        include("./CONCEPT/composite.jl")
        include("./CONCEPT/atom_interface.jl")
    end

    module KERNEL
        using ..COMMON
        using ..CONCEPT
        using Bijections
        using StaticArrays
        using DataFrames
        include("./KERNEL/bond.jl")
        include("./KERNEL/PTE.jl")
        include("./KERNEL/atom.jl")
        include("./KERNEL/atom_bijection.jl")
        include("./KERNEL/chain.jl")
        include("./KERNEL/residue.jl")
        include("./KERNEL/system.jl")
        include("./KERNEL/composite_iterator.jl")
        include("./KERNEL/aux_functions.jl") #split dataformats up
    end

    module MOLMEC
        using ..COMMON
        using ..CONCEPT
        using ..KERNEL
        include("./MOLMEC/MMFF94Parameters.jl")
    end

    module FILEFORMATS
        using ..COMMON
        using ..CONCEPT
        using ..KERNEL
        #include("./BioStructures_interface")#slipt dataformat up
        include("./FILEFORMATS/PDBParser.jl")#split dataformat up
    end

    module STRUCTURE
        using ..COMMON
        using ..CONCEPT
        using ..KERNEL
        include("./STRUCTURE/simple_molecular_graph.jl")
        include("./STRUCTURE/minimum_cycle_basis.jl")
        include("./STRUCTURE/ring_perception.jl")
    end

    module QSAR
        using ..COMMON
        using ..CONCEPT
        using ..KERNEL
        using ..STRUCTURE
        include("./QSAR/add_hydrogen_processor.jl")
    end

    using .COMMON
    using .CONCEPT
    using .KERNEL
    using .MOLMEC
    using .FILEFORMATS
    using .STRUCTURE
    using .QSAR
    export COMMON, CONCEPT, KERNEL, MOLMEC, FILEFORMATS, STRUCTURE, QSAR

end