#=
atomBijection:
- Julia version: 
- Author: Dan
- Date: 2021-06-28
=#
using Bijections
include("atom.jl")
const AtomBijection = Bijection{Atom,Atom}

function calculateRMSD(bijec::AtomBijection)
    sum_of_squares::Float64 = 0
    for (left_at, right_at) in bijec
        sum_of_squares += sqeuclidean(left_at.position_,right_at.position_)
    end
    sum_of_squares = sqrt(sum_of_squares / length(bijec))
    return sum_of_squares
    #= julia alternative
    return sqrt(sum(map(sqeuclidean, keys(bijec), values(bijec)))) / length(bijec))
    =#
end

#get 2 atom containers. insert into bijection when atom is sleceted and has identical name in other list
function assignByName(A::Composite,  B::Composite, limit_to_selection::Bool)
    result = AtomBijection()
    A_names = Dict{String, Atom}([(atom.name_, atom) for atom in AtomIterator(A) ])
    for atom in AtomIterator(B)
        if haskey(A_names,atom.name_) &&
                    ( !limit_to_selection || isSelected(atom) || isSelected(A_names[atom.name_]))
             result[A_names[atom.name_]] = atom
        end
        delete!(A_names, atom.name_)
    end
    return result
end

function assignCAlphaAtoms(A::Composite,  B::Composite, limit_to_selection::Bool)
    result = AtomBijection()
    res_list_A= collectResidues(A)
    res_list_B= collectResidues(B)
    for (res_A,res_B) in zip(res_list_A,res_list_B)
        at_A = getAtom(res_A,"CA")
        at_B = getAtom(res_B,"CA")
        if !isnothing(at_A) && !isnothing(at_B) &&
                                    (!limit_to_selection || isSelected(at_a) || isSelected(at_B))
            result[at_A] = at_B
        end
    end
    return result
end

assignBackboneAtoms(A::Composite, B::Composite, limit_to_selection::Bool) = begin
    result = AtomBijection()
    res_list_A= collectResidues(A)
    res_list_B= collectResidues(B)
    for (res_A,res_B) in zip(res_list_A,res_list_B)
        backbone_atoms = String["CA", "C", "H", "O", "N"]
        for at_name in backbone_atoms
            at_A = getAtom(res_A,at_name)
            at_B = getAtom(res_B,at_name)

            if !isnothing(at_A) && !isnothing(at_B) &&
                                    (!limit_to_selection || isSelected(at_a) || isSelected(at_B))
                result[at_A] = at_B
            end
        end
    end
    return result
end

#=
a = AtomBijection()
at1 = Atom()
at1.position_ = SA[1,2,3]
at2 = Atom()
at2.position_ = SA[2,3,4]

a[at1] = at2
println("euc ", euclidean(at1.position_ ,a[at1].position_ ))
println("sqrt ", sqrt(euclidean(at1.position_ ,a[at1].position_)))
=#