# DynamicVar.jl

Dynamic variables are a bit like globals and a bit like parameters. You use them when a lot of functions would take the same parameter and you can't be bothered passing it to all of them manually. While still retaining the ability the limit the scope were the value you assign to that variable applies.

Dynamic variables are a useful middle ground between globals and parameters.

## Credit to @MikeInnes

The original idea and code came from his implementation inside [JunoLab/Media.jl](https://github.com/JunoLab/Media.jl/blob/261c57e526a68dca2b92fc5c52dacffd4ae6a956/src/dynamic.jl)
