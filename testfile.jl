#=
using DataFrames
include("src/CONCEPT/composite.jl")
include("src/KERNEL/dataformats.jl")



import Base.convert
using BioStructures

struc = read("1EN2.pdb", PDB)


myatom = struc.models[1].chains["A"].residues["32"].atoms[" CA "]

root = Composite()
root2 = System()
a = System()
b  = System()
c = Chain()
d = Chain()
x = Chain()
e = Atom()
f = Atom()
g = Atom()
h = Atom()

root2.parent_ = nothing
root2.last_child_ = nothing
root2.next_ = nothing
root2.name_ = "r"

root.parent_ = nothing
root.last_child_ = nothing
root.next_ = nothing
root.properties_ = UInt64(122)

a.parent_ = nothing
a.last_child_ = nothing
a.next_ = nothing
a.name_ = "a"

b.parent_ = nothing
b.last_child_ = nothing
b.next_ = nothing
b.name_ = "b"

c.parent_ = nothing
c.last_child_ = nothing
c.next_ = nothing
c.id = "c"

x.parent_ = nothing
x.first_child_ = nothing
x.last_child_ = nothing
x.next_ = nothing
x.id = "x"


d.parent_ = nothing
d.last_child_ = nothing
d.next_ = nothing
d.id = "d"

e.parent_ = nothing
e.first_child_ = nothing
e.last_child_ = nothing
e.next_ = nothing
e.temp_factor_ = 1.0

f.parent_ = nothing
f.first_child_ = nothing
f.last_child_ = nothing
f.next_ = nothing
f.temp_factor_ = 2.0

g.parent_ = nothing
g.first_child_ = nothing
g.last_child_ = nothing
g.next_ = nothing
g.temp_factor_ = 3.0

h.parent_ = nothing
h.first_child_ = nothing
h.last_child_ = nothing
h.next_ = nothing
h.temp_factor_ = 4.0

appendchild(root,a)
appendchild(root,b)
appendchild(b,c)
appendchild(a,d)
appendchild(c,e)
appendchild(c,f)
appendchild(d,h)
appendchild(d,g)

appendchild(b,x)


mycomp = convert(Composite, struc)





struc2 = BioStructures.ProteinStructure(mycomp)
println(struc2)

writepdb("testthingy2", struc2)
=#

#ToDo : countx methods

#=
import Base.push!
using StaticArrays

abstract type Ato end
struct Bond
    first::Ato
    second::Ato
end

const bondVec = SVector{12,Union{Bond,Nothing}}
const bondDic = Dict{Ato,Bond}


mutable struct aVec<:Ato
    name::String
    bonds::bondVec
    last_index::Int8
end

mutable struct aDic<:Ato
    name::String
    bonds::bondDic
end

push!(cont::aVec, bond::Bond) = begin
    (cont.last_index == 12) && return
    cont.bonds = bondVec(cont.bonds[1:cont.last_index]..., bond, repeat([nothing],11-cont.last_index)...)
    cont.last_index += 1
end

atomVec = aVec[]
atomDic = aDic[]
for i in 1:Int(1e6)
    push!(atomVec, aVec(string(1), bondVec(repeat([nothing],12)...), 0))
    push!(atomDic, aDic(string(1), bondDic()))

    #connect to those who came before
    lower = max(1,i-12)
    for j in lower:(i-1)
        temp = Bond(atomVec[i],atomVec[j])
        push!(atomVec[i], temp)
        push!(atomVec[j], temp)

        atomDic[i].bonds[atomDic[j]] = temp
        atomDic[j].bonds[atomDic[i]] = temp
    end
end

using BenchmarkTools

function benchmarkBondsVector(x::aVec, lis::Vector{aVec})
    counter = 0
    for item in lis
        bond = Bond(x,item)
        if bond in item.bonds
            counter += 1
        end
    end
    return counter

end

function benchmarkBondsVector2(x::aVec, lis::Vector{aVec})
    counter = 0
    for item in lis
        if any([(x == xs.first || x== xs.second) for xs in item.bonds])
            counter += 1
        end

    end
    return counter
end

function benchmarkBondsVector3(x::aVec, lis::Vector{aVec})
    counter = 0
    for item in lis
        for bond in item.bonds
            if bond.first == x || bond.second == x
                counter +=1
                break
            end
        end
    end
    return counter
end

function benchmarkBondsDict(x::aDic, lis::Vector{aDic})
    counter = 0
    for item in lis
        if haskey(item.bonds, x)
            counter += 1
        end
    end
    return counter
end

xVec = atomVec[99]
xDic = atomDic[99]

println( benchmarkBondsVector(xVec,atomVec))
println( benchmarkBondsVector2(xVec,atomVec))
println( benchmarkBondsVector3(xVec,atomVec))
println( benchmarkBondsDict(xDic,atomDic))

BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000
t = @benchmark benchmarkBondsVector(xVec,atomVec)
print("v1 ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")

BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000
t = @benchmark benchmarkBondsVector2(xVec,atomVec)
print("v2 ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")

BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000
t = @benchmark benchmarkBondsVector3(xVec,atomVec)
print("v3 ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")

BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000
t = @benchmark benchmarkBondsDict(xDic,atomDic)
print("v1 ")
t2 = mean(t.times)/1e6
println(t," ", t2,"ms")
=#

#using DataFrames
#include("src/CONCEPT/composite.jl")
#include("src/KERNEL/dataformats.jl")

#struc = read("2lzx.pdb", PDB)

#println(struc)
#println(fieldnames(typeof(struc.models[1].chains["A"].residues.vals[1])))
#println(struc.models[1].chains["A"])
#biojl = [x.name for x in values(struc.models[1].chains["A"].residues) if typeof(x) != BioStructures.DisorderedResidue]
#pdbfile = "PCA ARG CYS GLY SER GLN GLY GLY GLY SER THR CYS PRO GLY LEU ARG CYS CYS SER ILE TRP GLY TRP CYS GLY ASP SER GLU PRO TYR CYS GLY ARG THR CYS GLU ASN LYS CYS TRP SER GLY GLU ARG SER ASP HIS ARG CYS GLY ALA ALA VAL GLY ASN PRO PRO CYS GLY GLN ASP ARG CYS CYS SER VAL HIS GLY TRP CYS GLY GLY GLY ASN ASP TYR CYS SER GLY GLY ASN CYS GLN TYR ARG CYS SER SER SER"
#biojl_dict = Dict{String, Int64}()
#println(biojl)

#for x in biojl
#    if !haskey(biojl_dict,x)
#        biojl_dict[x] = 1
#    else
#        biojl_dict[x] += 1
#    end
#end

#for y in sort(collect(biojl_dict), by = tuple -> last(tuple), rev=true)
#    println(y)
#end
#
#
#pdbsplit = split(pdbfile, " ")
#
#pdbdict = Dict()
#for x in pdbsplit
#    if !haskey(pdbdict,x)
#        pdbdict[x] = 1
#    else
#        pdbdict[x] += 1
#    end
#end
#println("--------------------------------")
#for y in sort(collect(pdbdict), by = tuple -> last(tuple), rev=true)
#    println(y)
#end
#
#gluc = convert(System, struc)
#println(gluc)

#check how the atoms are connected, to see if a "CONNECT x a b" line in PDB creates bond(x,a) and bond(x,b)
#result: it does

#struc = read("glucose.pdb", BioStructures.PDB)
#internal = convert(System, struc)
#internal = System("glucose.pdb", PDB)
#
#for atom in AtomIterator(internal)
#    println(atom.serial_)
#end

##--readpdb--##
#include("src/CONCEPT/composite.jl")
#include("src/KERNEL/dataformats.jl")


#println(fieldnames(typeof(struc.models[1].chains["A"].residues.vals[1])))
#println(struc.models[1].chains["A"])
#internal_representation = System("1EN2.pdb", PDB)


#println([(getName(x),x.insertion_code_) for x in collectResidues(internal_representation)] )
#println( [(getName(x), x.res_number_) for x in collectResidues(internal_representation) if isAminoAcid(x)] )
#for x in collectResidues(internal_representation)
#    if isAminoAcid(x)
#        println(getName(x), x.res_number_)
#    end
#end
#println( "count of all AS ",length([getName(x) for x in collectResidues(internal_representation) if isAminoAcid(x)]) )
#println( "count of all res ",length(collectResidues(internal_representation)))
#tmp = [x.serial_ for x in collectAtoms(internal_representation)]
#println(length(collectAtoms(internal_representation)))

#t = [collectResidues(internal_representation)[y] for y in [15,16,28,45,74,79]]
#for (x,ln) in zip(t,[15,16,28,45,74,79])
#    println(ln," ",[getChildren(x)])
#end

#xd = collectChains(internal_representation)[1]
#res = [10,14,80,81]
#for id in res
#    println([getName(x) for x in collectAtoms(collectResidues(xd)[id])])
#end

#println( [x.serial_ for x in filter( (x) -> x.serial_ in [10,14,28,74,79] ,collectAtoms(internal_representation) )] )
using StatProfilerHTML
#struc = read("5ire.pdb", BioStructures.PDB)
push!(LOAD_PATH, "G:\\Python Programme\\sbl.jl\\src\\" )

using BALL



#include("src/QSAR/ring_perception_processor.jl")
#include("src/QSAR/minimum_cycle_basis.jl")

#internal = System("G:/Python Programme/sbl.jl/1,2-Benzodiazepine.pdb")
internal = BALL.System("G:/Python Programme/sbl.jl/benzene.pdb")
#println("nodes: $(length(collectAtoms(internal)))")
#println("bonds: $(length(collectBonds(internal)))")

println(internal)


edges, atoms = BALL.SSSR(internal)
foreach(println, edges)
println(atoms)

import Pkg
Pkg.generate("BALL")

