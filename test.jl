include("main.jl")

@dynamic a = 1

@test need(a) == 1
@dynamic let a = 2
  @test need(a) == 2
end
@test need(a) == 1

@dynamic! b = 1
@test need(a) == 1
@dynamic! let a = 2
  @test need(a) == 2
end
@test need(a) == 1
