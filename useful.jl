#=
useful:
- Julia version: 
- Author: Dan
- Date: 2021-06-03
=#
using Pipe
println("----------")

function g(x,y)::Int8
    return x*y #can return nothing
    end;
#indizierung ist Array[x-index][y-index]
a = [[[1,5],[2,6]],[[3,7],[4,8]]]
println(a[2][1][1])
a = [(2*y+x) for x in 1:2, y in 0:1]

my_dictionary = Dict(1 => 2,2 => 4)
map(k -> my_dictionary[k] = k * 2,[i for i in 3:6])
for (k,v) in my_dictionary
    println("$k is $v")
end

if true && true
    println("ok")
end

A = [1,2]
B = [3,4]
println(A .+ B .^A)
println([1,2,3].^2)
x = 5
println(1. + x," ",1 .+ x)
println(isequal(5+1,6),isfinite(Inf), isinf(6), isnan(0/0))
println(NaN == NaN, isequal(NaN,NaN))
println(zero(Float64), " ", one(Float64), typeof(zero(Float64)))
x = 266
y = x % UInt8
try
    z = UInt8(x)
    catch e
end
z = "no workey"

println(y,z)
println(1//3,typeof(1//3))
x = 1
y = 2
f = begin  global x = x+y  end
x = f
x = f
println(f," ", x)

if x>0
    "pos"
else
    "neg"
end

i = 1

while i <= 4f
    global i += 1f
    end
println(i)
for (j,k) in zip([1,2,3],[1,2,3,4])
    println(j,k)
end

struct MyCustomException <: Exception end #inherit
println(isvalid(Char, 0x110000))
my_str = "hi bob";
println(typeof(SubString(my_str,2,4)))
println(my_str[begin])
#what does collect.() do?
str1 = "hi"
str2 = "john"
println((str1*", "*str2) == ("$str1, $str2"))

println(occursin("hi", my_str))
println(findnext(isequal('o'),"xylophone",1+findfirst(isequal('o'),"xylophone")))
println(firstindex(my_str))
println(my_str,1,3)
println(occursin(r"^\s*(?:#|$)", "# a comment"))
println(match(r"^\s*(?:#|$)", "# a comment"))
m = match(r"^\s","helly")
if m === nothing
    println("check nothing out")
end

m = match(r"(a|b)(c)?(d)", "acd")
println(typeof(m))
println(m.match," ", m.captures, " ", m.offsets)


add = +
println(add(1,2,3))
a = [1,2]; b = [3,4]; c = hcat(a,b); d = vcat(a,b)
println(c,d,typeof(c),c[2][1])

#anon function in map: Map applis func to every thing in array. map takes any function
println(map(x->x^2+2x-1,[1,2,3]))
j = (1,2*2); k = (a = 2,b=3)
println(k[1],k.a)

gap((min,max)) = max-min #valid, takes atuple (one argument) but allows for the names in argument ot be called
varags_xample(a,b...) = (a,b)  #b is a tuple, holding as many values as passed (or 0 values)
x = (1,2,3)
println(varags_xample(x...))        #also works on non-varargs

function mh(x...;y=0,kwargs...) ###function with varargs mandatory input, keyword args with def valzue and keyword varargs. kwargs is a named tuple

 end
#can call this with mh(2;my_dict_or_my_tuple...)
 #keyword argument must be given, if no default value given

#map(x-> anon func, [input]) can be made map([input]) do x [anon func]

println(map(x->x*2,[1,2]))
println(map([1,2]) do x return x*2 end)

#open("outfile", "w") do io
#write(io, data)
#end
println((sqrt ∘ +)(3, 6)," ", sqrt(+(3,6)))
1:10 |> sum |> sqrt |> println
1:10 |> x -> 2 .* x |> f -> f .- 1 |> sum |> println
my_str = "I neeD tO bE chaNGED";
my_ar = map(x-> string(x), 1:10)
println(typeof(my_ar))
println(my_ar)

#my_str |>  lowercase |> f -> split(f," ") .|> f -> f*"a" .|> f-> replace(f, "a" => "!") |> f-> join(f," ") |> println
a = @pipe my_str |> lowercase |> split(_," ") |> filter!(e -> length(e) < 3, _) |> string(_) |> println #only can use _ with pipe


randombool = true
if randombool
    println("truth")
    println("partoo")
end
randombool && (println("truth"); println("partoo"))
#ToDo: Does throw(exception) crash application? Build a function with error branching?
#build an app with try/catch/finally branching

println(@isdefined(a), @isdefined(xyz))

s = 0
for i= 1:10
    global s+= i    #need globacl if i want to change the s defined a line above.
                    #else i will get warning and a new local var s is created
end

Fs = Vector{Any}(undef,2)

i = 0
Fs[1] = () -> i #function that returns i
Fs[2] = () -> i

global i+= 2
println(Fs[1](), Fs[1])

i = 0
for i = 1:3
# empty
end
println(i)

struct my_struct        #can put "mutable" before struct to make it mutable
    bar
    foo::Int
end
var = my_struct([1,2],55)
var.bar[1] = 22
#var.foo = 22 throws error
println(fieldnames(my_struct))
#structs are immutable. but the values (like arrays) inside structs are mutable => must point to same object
xd = Union{Int,String}
xd = 1
ge = Union{Int,Nothing} ##Union{T,Nothing} can indicate if a value is missing

abstract type Pointy{T}
    end  #abstract class as known

struct Pointeh{T<:Real} <: Pointy{T}    #implementation  of abstract but typ emust be subtype of real
x::T
y::T
end



struct Point{T}
    x::T
    y::T
end

Base.show(io::IO, x::Point) = print(io, "x is",x.x," y is ",x.y)

Base.show(io::IO, ::MIME"text/plain", z::Point{T}) where{T} =
print(io, "Polar{$T} complex number:\n ", z)

myp = Point(1,1)
println(myp)


function norm(p::Point{Real})   #works only on Point{Real}
sqrt(p.x^2 + p.y^2)
end

function norm(p::Point{<:Real}) #Works on Point{Type} where Type is a subtype of Real
sqrt(p.x^2 + p.y^2)
end

#mytupletype = Tuple{AbstractString,Vararg{Int,N}}  #Tuple of 1 string and exaxtly n type Int type values


@NamedTuple{a::Int, b::String}
@NamedTuple begin
a::Int
b::String
end

primitive type Ptr{T} 64 end

const my_uni = Union{Int,Float64}

println(supertype(Int))

function mf(x,y)
    return "Woah there, Nelly."
    end
mf(x::Number, y::Number) =
    "both numbers"
mf(X::Number, y::Float64) =
    "number float"
mf(X::T,y::T) where {T} =
    "same type"
println(methods(mf))
println(join([mf("string",2), mf(2,2.0), mf(2,2), mf(2,Float64(2)),mf("","")],", "))

#ToDo @eval?

abstract type AbstractArray{T, N} end
eltype(::Type{<:AbstractArray{T}}) where {T} = T #create my own arraytype. use this func to get the actual parameter type


#ToDo: make subclass with fields and subtypes that inherit

#iterated dispatch:
#+(a::Matrix, b::Matrix) = map(+,a,b)
#+(a,b) = +(promote(a,b)...) -> makes them the same type
#+a::Float64,b::Float64 = Core.add(a,b) cann add them here now
#container type -> eltype dispatch

# trait based dispatch

#map(f, a::AbstractArray, b::AbstractArray) = map(Base.IndexStyle(a, b), f, a, b)
# generic implementation:
#map(::Base.IndexCartesian, f, a::AbstractArray, b::AbstractArray) = ...
# linear-indexing implementation (faster)
#map(::Base.IndexLinear, f, a::AbstractArray, b::AbstractArray) = ...


struct Image{T,N,A<:AbstractArray} <: AbstractArray{T,N}
    data::A
    properties::Dict
end

#Image(T<:Number ,N::Int) = begin
#    Image.data = Array{T,N}
#    properties = Dict()
#end

#x = Image(Float64, 10)

op = (ai, bi) -> ai * bi + ai * bi
#R = promote_op(op, eltype(a), eltype(b)) #how to compute output type
#output = similar(b, R, (size(a, 1), size(b, 2))) #b,a arrays

# logic (here: ...) not in same func as type-computations. better performance and compiling
#complexfunction(arg::Int) = ...
#complexfunction(arg::Any) = complexfunction(convert(Int, arg))
#matmul(a::T, b::T) = ...
#matmul(a, b) = matmul(promote(a, b)...)

function getindex(A::AbstractArray{T,N}, indices::Vararg{Number,N}) where {T,N} end #with Vararg can constrain additional args Type and/or amount (amount must be exact though
    #where{T,N} ensures both bose letters must be same?

struct Polynomial{R}
coeffs::Vector{R}
end

function (p::Polynomial)(x)     #function that gets a polynomial
    v = p.coeffs[end]
    for i = (length(p.coeffs)-1):-1:1
        v = v*x + p.coeffs[i]
    end
    return v
end

(p::Polynomial)() = p(5)   #without making an object, can call the type
p = Polynomial([1,10,100])
p(3) |> println
p() |> println #p(5)
#instead of
#f(x::A, y::A) = ...
#f(x::A, y::B) = ...
#f(x::B, y::A) = ...
#f(x::B, y::B) = ..
#do
#f(x::A, y::A) = ...
#f(x, y) = f(g(x), g(y))
#wher g converts to types that work
#or
#f(x::T, y::T) where {T} = ...
#f(x, y) = f(promote(x, y)...)
#if same type is wanted, promote will (in most cases) find a suitable type for func


#a way to use multiple disptach to casxade with default args.
#use a Repliacte() that you want to apply, and when you want to apply nothing use NoPad own type
struct NoPad end # indicate that no padding is desired, or that it's already applied
#myfilter(A, kernel) = myfilter(A, kernel, Replicate()) # default boundary conditions
#function myfilter(A, kernel, ::Replicate)
#Apadded = replicate_edges(A, size(kernel))
#myfilter(Apadded, kernel, NoPad()) # indicate the new boundary conditions
#end
# other padding methods go here
function myfilter(A, kernel, ::NoPad)
# Here's the "real" implementation of the core computation
end

struct my_struct2
    foo
    bar
    my_struct2(x,y) = begin #innder constructor
    if x > y
        return new(x,y)
    else
        return new(y,x)
    end
    println("$x >= $y")
    end
end

my_struct2(x) = my_struct2(x,5)
my_struct2() = my_struct2(2)#outer constructor
aa = my_struct2(2,1)
println((aa.foo,aa.bar))

mutable struct SelfReferential
    obj::SelfReferential
    SelfReferential() = (x = new(); x.obj = x)
end

parse(Int, "100101", base = 2) |> println

"the argument name is omitted prior to the :: symbol, and only the type is given. This is the
syntax in Julia for a function argument whose type is specified but whose value does not need to be referenced
by name.
"
struct MyType
    a::Int8
    MyType(x) = new(x)
    end
testMyType = MyType(2)

convert(::Type{MyType}, x) = MyType(x)
tete = Float64(5)
println(convert(MyType, tete))

promote_rule(::Type{MyType},::Type{Number}) = Float64
test_funs(x::MyType, y::Number) = +(Float64.(promote(x.a, y))...)
x = convert(MyType, tete)
y = Int64(2)
println(test_funs(x,y), " ", typeof(test_funs(x,y)))

#interfaces
struct Squares
        count::Int
    end

Base.iterate(S::Squares, state = 1) = state > S.count ? nothing : (state*state, state+1)
Base.eltype(::Type{Squares}) = Int
Base.length(S::Squares) = S.count
Base.sum(S::Squares) = (n = S.count; return n*(n+1)*(2n+1)/6)
Base.iterate(rs::Iterators.Reverse{Squares}, state=rs.itr.count) = state>1 ? nothing : (state*state, state-1)

for item in Squares(3)
println("Squares[3] object contents ",item) end

using Statistics
println("collect Squares[5] iterator",collect(Squares(5)))
println(mean(Squares(3)))
println(sum(Squares(3)))
function Base.getindex(S::Squares, i::Int)
    1 <= i <= S.count || throw(BoundsError(S,i))
    return i*i
    end     #this doesnt allow me to index with slices or anything other than int

Base.getindex(S::Squares, i::Number) = Base.getindex(S,convert(Int,i))
println(Squares(4)[3])

#or, better

struct SquaresVector <: AbstractArray{Int,1}
    count::Int
    end

Base.size(S::SquaresVector) = (S.count,)
Base.IndexStyle(::Type{<:SquaresVector}) = IndexLinear()
Base.getindex(S::SquaresVector,i::Int) = i*i

struct SparseArray{T,N} <: AbstractArray{T,N}
        data::Dict{NTuple{N,Int}, T}
        dims::NTuple{N,Int}
    end

Base.length(A::SparseArray) = *(A.dims...)
Base.IndexStyle(::Type{SparseArray}) = IndexCartesian()
SparseArray(::Type{T}, dims::Int...) where {T} = SparseArray(T, dims);
SparseArray(::Type{T}, dims::NTuple{N,Int}) where {T,N} =
SparseArray{T,N}(Dict{NTuple{N,Int}, T}(), dims);
Base.size(A::SparseArray) = A.dims
Base.similar(A::SparseArray, ::Type{T}, dims::Dims) where {T} = SparseArray(T, dims)
Base.getindex(A::SparseArray{T,N}, I::Vararg{Int,N}) where {T,N} = get(A.data, I, zero(T))
Base.setindex!(A::SparseArray{T,N}, v, I::Vararg{Int,N}) where {T,N} = (A.data[I] = v)
Base.setindex!(A::SparseArray{T,N}, B::Vector{M}, ::Colon) where {T,N,M} = ((length(B) < length(A)) && (A.data = B))



test = SparseArray(Float64,3,3)
println(test)
test[1,2] = 3
println(test.data)

struct MyNumber
    x::Float64
end

for op = (:sin, :tan, :cos, :log, :exp)     #define al those functions programatically for MyNumber
    eval(quote
        Base.$op(A::MyNumber) = MyNumber($op(a.x))
    end)
end

for op = (:+, :-, :/, :*)
    @eval Base.$op(a::MyNumber, b::MyNumber) = MyNumber($op(a.x,b.x))
end

a = MyNumber(2)
b = MyNumber(3)
println("$(a+b), $(a/b), $(sin(a))")