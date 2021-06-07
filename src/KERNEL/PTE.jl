#=
PTE:
- Julia version: 
- Author: Dan
- Date: 2021-06-03
=#

@enum Symbol begin
				Ac = 0
				Al
				Am
				Sb
				Ar
				As
				At
				Ba
				Bk
				Be
				Bi
				Bh
				B
				Br
				Cd
				Cs
				Ca
				Cf
				C
				Ce
				Cl
				Cr
				Co
				Cu
				Cm
				Db
				Dy
				Es
				Er
				Eu
				Fm
				F
				Fr
				Gd
				Ga
				Ge
				Au
				Hf
				Hn
				He
				Ho
				H
				In
				I
				Ir
				Fe
				Jl
				Kr
				La
				Lr
				Pb
				Li
				Lu
				Mg
				Mn
				Mt
				Md
				Hg
				Mo
				Nd
				Ne
				Np
				Ni
				Nb
				N
				No
				Os
				O
				Pd
				P
				Pt
				Pu
				Po
				K
				Pr
				Pm
				Pa
				Ra
				Rn
				Re
				Rh
				Rb
				Ru
				Rf
				Sm
				Sc
				Se
				Si
				Ag
				Na
				Sr
				S
				Ta
				Tc
				Te
				Tb
				Tl
				Th
				Tm
				Sn
				Ti
				W
				Uub
				Uun
				Uuu
				U
				V
				Xe
				Yb
				Y
				Zn
				Zr
			end

mutable struct Element
    name_                   ::String
    symbol_                 ::Symbol
    group_                  ::String
    period_                 ::String
    atomic_number_          ::String
    atomic_weight_          ::Float64
    atomic_radius           ::Float64
    covalent_radius         ::Float64
    van_der_waals_radius    ::Float64
    is_metal_               ::Bool
    electronegativity_      ::Float64
    Element() = new()
end

