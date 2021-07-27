#=
PTE:
- Julia version: 
- Author: Dan
- Date: 2021-06-03
=#

include("../COMMON/common.jl")

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
translate_symbol = Dict{String,Symbol}(
				"Ac" => Ac,
				"Al" => Al,
				"Am" => Am,
				"Sb" => Sb,
				"Ar" => Ar,
				"As" => As,
				"At" => At,
				"Ba" => Ba,
				"Bk" => Bk,
				"Be" => Be,
				"Bi" => Bi,
				"Bh" => Bh,
				"B" => B,
				"Br" => Br,
				"Cd" => Cd,
				"Cs" => Cs,
				"Ca" => Ca,
				"Cf" => Cf,
				"C" => C,
				"Ce" => Ce,
				"Cl" => Cl,
				"Cr" => Cr,
				"Co" => Co,
				"Cu" => Cu,
				"Cm" => Cm,
				"Db" => Db,
				"Dy" => Dy,
				"Es" => Es,
				"Er" => Er,
				"Eu" => Eu,
				"Fm" => Fm,
				"F" => F,
				"Fr" => Fr,
				"Gd" => Gd,
				"Ga" => Ga,
				"Ge" => Ge,
				"Au" => Au,
				"Hf" => Hf,
				"Hn" => Hn,
				"He" => He,
				"Ho" => Ho,
				"H" => H,
				"In" => In,
				"I" => I,
				"Ir" => Ir,
				"Fe" => Fe,
				"Jl" => Jl,
				"Kr" => Kr,
				"La" => La,
				"Lr" => Lr,
				"Pb" => Pb,
				"Li" => Li,
				"Lu" => Lu,
				"Mg" => Mg,
				"Mn" => Mn,
				"Mt" => Mt,
				"Md" => Md,
				"Hg" => Hg,
				"Mo" => Mo,
				"Nd" => Nd,
				"Ne" => Ne,
				"Np" => Np,
				"Ni" => Ni,
				"Nb" => Nb,
				"N" => N,
				"No" => No,
				"Os" => Os,
				"O" => O,
				"Pd" => Pd,
				"P" => P,
				"Pt" => Pt,
				"Pu" => Pu,
				"Po" => Po,
				"K" => K,
				"Pr" => Pr,
				"Pm" => Pm,
				"Pa" => Pa,
				"Ra" => Ra,
				"Rn" => Rn,
				"Re" => Re,
				"Rh" => Rh,
				"Rb" => Rb,
				"Ru" => Ru,
				"Rf" => Rf,
				"Sm" => Sm,
				"Sc" => Sc,
				"Se" => Se,
				"Si" => Si,
				"Ag" => Ag,
				"Na" => Na,
				"Sr" => Sr,
				"S" => S,
				"Ta" => Ta,
				"Tc" => Tc,
				"Te" => Te,
				"Tb" => Tb,
				"Tl" => Tl,
				"Th" => Th,
				"Tm" => Tm,
				"Sn" => Sn,
				"Ti" => Ti,
				"W" => W,
				"Uub" => Uub,
				"Uun" => Uun,
				"Uuu" => Uuu,
				"U" => U,
				"V" => V,
				"Xe" => Xe,
				"Yb" => Yb,
				"Y" => Y,
				"Zn" => Zn,
				"Zr" => Zr

)
mutable struct Element
    name_                   ::Union{String,Nothing}
    symbol_                 ::Union{Symbol,Nothing}
    group_                  ::Union{String,Nothing}
    period_                 ::Union{String,Nothing}
    atomic_number_          ::Union{String,Nothing}
    atomic_weight_          ::Union{Float64,Nothing}
    atomic_radius           ::Union{Float64,Nothing}
    covalent_radius         ::Union{Float64,Nothing}
    van_der_waals_radius    ::Union{Float64,Nothing}
    is_metal_               ::Union{Bool,Nothing}
    electronegativity_      ::Union{Float64,Nothing}
    Element() = new()

	Element(name_                   ::Union{String,Nothing},
			symbol_                 ::Union{Symbol,Nothing},
			group_                  ::Union{String,Nothing},
			period_                 ::Union{String,Nothing},
			atomic_number_          ::Union{String,Nothing},
			atomic_weight_          ::Union{Float64,Nothing},
			atomic_radius           ::Union{Float64,Nothing},
			covalent_radius         ::Union{Float64,Nothing},
			van_der_waals_radius    ::Union{Float64,Nothing},
			is_metal_               ::Union{Bool,Nothing},
			electronegativity_      ::Union{Float64,Nothing}) = begin

				 new(	name_,
						symbol_,
						group_,
						period_,
						atomic_number_,
						atomic_weight_,
						atomic_radius,
						covalent_radius,
						van_der_waals_radius,
						is_metal_,
						electronegativity_
				)
			end
end

Element(element::String) = Element(nothing,translate_symbol[element],nothing,
	nothing,nothing,nothing,nothing,nothing,nothing,nothing,nothing)
