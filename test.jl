@require "." @dynamic!

@dynamic! a = 2
@test a[] == 2
@dynamic! let a = 1
  @test a[] == 1
end
@test a[] == 2
