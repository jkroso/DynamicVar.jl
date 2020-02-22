dynamic_eq(def) = begin
  name, val = map(esc, def.args)
  :(const $name = Ref{Any}($val))
end

dynamic_let!(ex) = begin
  vars = Meta.isexpr(ex.args[1], :block) ? ex.args[1].args : [ex.args[1]]
  quote
    old = [$([:($(esc(x.args[1]))[]) for x in vars]...)]
    $([:($(esc(b.args[1]))[] = $(esc(b.args[2]))) for b in vars]...)
    try
      $(esc(ex.args[2]))
    finally
      $([:($(esc(b.args[1]))[] = old[$i]) for (i,b) in enumerate(vars)]...)
    end
  end
end

"""
Create new or alter existing Refs within a limited scope

To create a new Ref write `@dynamic! a = 1` or `const a = Ref(1)`
To alter it within a limited scope write:

```
@show a[]
@dynamic! let a = 2
  @show a[]
end
@show a[]
```
"""
macro dynamic!(def)
  Meta.isexpr(def, :(=)) && return dynamic_eq(def)
  Meta.isexpr(def, :let) && return dynamic_let!(def)
  error("Unsupported @dynamic! expression")
end
