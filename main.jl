@require "github.com/jkroso/Prospects.jl" need assoc

struct DynamicVar
  name::Symbol
end

# Creates a new DynamicVar
dynamic_eq(def) = begin
  name, val = map(esc, def.args)
  quote
    const $name = DynamicVar($(QuoteNode(def.args[1])))
    bind($name, $val, current_task())
  end
end

# Alters the value of a dynamic variables within the scope of an expression
dynamic_let(ex) =
  quote
    t = @task $(esc(ex.args[1]))
    $([:(bind($(esc(b.args[1])), $(esc(b.args[2])), t)) for b in ex.args[2:end]]...)
    schedule(t)
    wait(t)
  end

dynamic_let!(ex) =
  quote
    t = current_task()
    old = getscope(t)
    $([:(bind($(esc(b.args[1])), $(esc(b.args[2])), t)) for b in ex.args[2:end]]...)
    $(esc(ex.args[1]))
    setscope(t, old)
  end

setscope(t::Task, scope) = storage(t)[getscope] = scope

"""
Create new or alter existing dynamic variables within a limited scope

To create a new dynamic variables write `@dynamic a = 1`
To alter it within a limited scope write:

```
show_a() = @show need(a)
@dynamic let a = 2
  show_a()
end
show_a()
```
"""
macro dynamic(def)
  Meta.isexpr(def, :(=)) && return dynamic_eq(def)
  Meta.isexpr(def, :let) && return dynamic_let(def)
  error("Unsupported @dynamic expression")
end

"""
Like dynamic but unsafe when the body of the let contains async code
"""
macro dynamic!(def)
  Meta.isexpr(def, :(=)) && return dynamic_eq(def)
  Meta.isexpr(def, :let) && return dynamic_let!(def)
  error("Unsupported @dynamic! expression")
end

storage(t::Task) =
  if t.storage === nothing
    t.storage = ObjectIdDict()
  else
    t.storage
  end

@gensym secret_value

need(var::DynamicVar) = begin
  value = getvalue(var, secret_value, current_task())
  @assert value !== secret_value "No value defined for $var"
  value
end

parent(task::Task) = task.parent
isroot(task::Task) = task.parent == task
const empty_scope = Base.ImmutableDict{DynamicVar,Any}()
getscope(task::Task) = begin
  s = storage(task)
  b = get(s, getscope, s)
  if b === s
    s[getscope] = empty_scope
  else
    b
  end
end

bind(var::DynamicVar, val, t::Task) = setscope(t, assoc(getscope(t), var, val))
bind(f::Function, var::DynamicVar, val) = begin
  t = Task(f)
  bind(var, val, t)
  schedule(t)
  wait(t)
end

getvalue(var::DynamicVar, default, t::Task) =
  if haskey(getscope(t), var)
    getscope(t)[var]
  elseif isroot(t)
    default
  else
    getvalue(var, default, parent(t))
  end
