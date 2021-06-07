#=
composite_test:
- Julia version: 
- Author: Dan
- Date: 2021-06-04
=#
#---------------TEST----------------------
include("../src/CONCEPT/composite.jl")
using Test
@testset "myset" begin
    @testset "under1" begin
        a = [1,2,3]
        b = [1,2,5]
        @test a!=b
    end
    #will open up a new scope and fail.
    #@testset "under2" begin
    #    @test a == [1,2,3]
    #end
end

a_element = Atom()
a_element.name_ = "a"
b_element = Atom()
b_element.name_ = "b"
c_element = Atom()
c_element.name_ = "c"
d_element = Atom()
d_element.name_ = "d"
e_element = Atom()
e_element.name_ = "e"
x_element = Atom()
x_element.name_ = "x"

a = Composite()
b = Composite()
c = Composite()
d = Composite()
e = Composite()
x = Composite()

a.trait_ = a_element
b.trait_ = b_element
c.trait_ = c_element
d.trait_ = d_element
e.trait_ = e_element
x.trait_ = x_element

a.first_child_ = x
a.last_child_ = b

x.first_child_ = missing
x.next_ = b

b.first_child_ = c
b.last_child_ = d


c.first_child_ = e
c.last_child_ = e
c.next_ = d

e.first_child_ = missing
d.first_child_ = missing

for item in a
    #println(item)
end
