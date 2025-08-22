<div align="center">
<img src="https://github.com/ChifiSource/image_dump/raw/main/olive/0.1/extensions/olivero.png" width="250" /img>
</div>

`OliveReadOnly` provides `Olive` with read only session cells, file cells, directories, projects, and exports. This is *primarily* intended for use with further extensions or customized `Olive` servers. This extension doesn't serve much purpose to a regular user unless they are sharing files, some of which they want to be read only, over a network with `Olive`. 
###### adding
Add `OliveReadOnly` to your `olive` environment by adding `OliveReadOnly` to your `olive` environment. `using OliveReadonly` to your `olive.jl` file. Learn more at [installing extensions](https://github.com/ChifiSource/Olive.jl#installing-extensions)
- Alternatively, you may load `OliveReadOnly` by `using OliveReadOnly` before starting `Olive`.

The intended use-case involves assembling your own read-only directories *manually*. If you'd like to give `OliveReadyOnly` a try on your own, try adding a `readonly` directory to your `Environment` from the REPL:
```julia
newdirec = Olive.Directory(pwd(), dirtype = "readonly"); env = Olive.CORE.users[1].environment; push!(env.directories, newdirec)
```
Consider the different steps, as this is the same technique we would use to preload a read only directory into an `Olive` session. First we get the environment, then we push a new directory to it.
```julia
newdirec = Olive.Directory(pwd(), dirtype = "readonly")
env = Olive.CORE.users[1].environment
push!(env.directories, newdirec)
```
