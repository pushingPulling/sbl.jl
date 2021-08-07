current dependency chain:
//multiple files in one line means the next line includes all of the files from that line//
//in Julia, if 2 files include the same file, the included files will be evaluated twice; thus redefining all its contents and processing them multiple times//
//to avoid this, make a chain of includes, were every file is included only once in a chain (it saves a lot of compilation time and compiler warnings)//

COMMON/gobal.jl
COMMON/common.jl selectable.jl
composite_interface timeStamp
composite
atom_interface
bond PTE
atom
atom_bijection
chain
residue
system MMFF94parameters
comp_iter
datformats
kernel_func
simple_molecular_graph
ring_percetion_procesor