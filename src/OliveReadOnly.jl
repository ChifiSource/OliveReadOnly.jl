"""
Created in August, 2025 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
- This software is MIT-licensed.
### OliveReadOnly
`OliveReadOnly` provides `Olive` with read only cells, projects, a read-only file type (.post), directories, and an export format (.post). 
This has limited use-cases; this is likely only useful for certain extensions, or for **hosting Olive**.
##### bindings
```julia
# internal:
convert_readonly
build_readonly_filecell


# olive extensions:

#   cells:
build(c::Connection, cm::ComponentModifier, cell::Cell{:readonly}, proj::Project{<:Any})
build(c::Connection, cm::ComponentModifier, cell::Cell{:tomlro}, proj::Project{<:Any})
build(c::Connection, cm::ComponentModifier, cell::Cell{:codero}, proj::Project{<:Any})
build(c::Connection, cm::ComponentModifier, cell::Cell{:markdownro}, proj::Project{<:Any})

build(c::Connection, cell::Cell{:post}, d::Directory{<:Any})
olive_save(p::Project{<:Any}, pe::ProjectExport{:post})
# other:
build(c::AbstractConnection, dir::Directory{:readonly})
build_tab(c::Connection, p::Project{:readonly}; hidden::Bool = false)
```
"""
module OliveReadOnly
using Olive
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession
using Olive: Directory, Cell, Project, getname, ProjectExport
import Olive: build, olive_read, build_tab, olive_save, is_jlcell

#==
Cells
==#

convert_readonly(cell::Cell{<:Any}) = begin
    ct = typeof(cell).parameters[1]
    Cell{:readonly}(cell.source, string(ct) => cell.outputs)
end

function olive_save(p::Project{<:Any}, pe::ProjectExport{:post})
    path = p[:path]
    if ~(contains(path), ".post")
        path = path * ".post"
    end
    joined::String = join(string(cell) for cell in convert_readonly(proj[:cells]))
    open(path, "w") do io
        write(io, joined)
    end
    joined = nothing
    nothing::Nothing
end

function build(c::Connection, cell::Cell{:post}, d::Directory{<:Any})
    hiddencell = build_base_cell(c, cell, d)
    style!(hiddencell, "background-color" => "#AA104F")
    style!(hiddencell, "cursor" => "pointer")
    hiddencell
end

convert_readonly(cell::Cell{:readonly}) = cell
convert_readonly(cell::Cell{:tomlro}) = cell
convert_readonly(cell::Cell{:markdownro}) = cell
convert_readonly(cell::Cell{:codero}) = cell

convert_readonly(cells::Vector{Cell}) = Vector{Cell}([convert_readonly(cell) for cell in cells])::Vector{Cell}

convert_readonly(cell::Cell{:tomlvalues}) = begin
    Cell{:tomlro}(cell.source)
end

convert_readonly(cell::Cell{:image}) = begin
    # TODO The READ needs to be handled differently, the data is different when read from a file.
    convimg = if typeof(cell.outputs) <: AbstractString
        cell.source = replace(lowercase(cell.source), "# " => "", " " => "", "\n" => "")
        outp_splits = split(cell.outputs, "!|")
        img(src = "'data:image/$(cell.source);base64," * outp_splits[2] * "'")
    else
        base64img("", cell.outputs[2], lowercase(cell.source))
    end
    Cell{:imagero}(convimg[:src], "$(cell.outputs[3])!|$(cell.outputs[4])")
end

convert_readonly(cell::Cell{:vimage}) = begin
    Cell{:vimagero}(cell.source)
end

convert_readonly(cell::Cell{:code}) = begin
    Cell{:codero}(cell.source, cell.outputs)
end

convert_readonly(cell::Cell{:markdown}) = begin
    Cell{:markdownro}(cell.source)
end

is_jlcell(T::Type{Cell{:readonly}}) = false
is_jlcell(T::Type{Cell{:tomlro}}) = false
is_jlcell(T::Type{Cell{:codero}}) = false

function build(c::Connection, cm::ComponentModifier, cell::Cell{:readonly}, proj::Project{<:Any})
    cellid = cell.id
    cell_label = cell.outputs[1]
#== TODO Perhaps we have a new extensible function from `Olive` called `get_highlighted` or something, 
    with parametric dispatch for cells. Otherwise, there's no way to know which marking function to call.==#
    tm = try
        get_highlighter(c, cell)
    catch
        nothing
    end
    text = cell.source
    inner_label = h4(text = cell_label)
    inner_code = div("cell$cellid", text = text)
    inner = div("cell$cellid", children = [inner_label, inner_code])
    style!(inner_label, "color" => "white")
    style!(inner, "background-color" => "#171717", "border-radius" => 4px, "padding" => 3percent)
    output = div("outputcell$cellid", text = string(cell.outputs[2]))
    div("cellcontainter$cellid", children = [inner, output])
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:tomlro}, proj::Project{<:Any})
    cellid = cell.id
    tm = c[:OliveCore].users[getname(c)].data["highlighters"]["toml"]
    set_text!(tm, cell.source)
    Olive.OliveHighlighters.mark_toml!(tm)
    result = string(tm)
    inner_label = h4(text = "toml")
    inner_code = div("cell$cellid", text = result)
    inner = div("cell$cellid", children = [inner_label, inner_code])
    style!(inner_label, "color" => "lightblue")
    style!(inner, "background-color" => "#171717", "border-radius" => 4px, "padding" => 3percent)
    output = div("outputcell$cellid", text = cell.outputs)
    div("cellcontainter$cellid", children = [inner, output])
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:codero}, proj::Project{<:Any})
    cellid = cell.id
    tm = Olive.JULIA_HIGHLIGHTER
    set_text!(tm, cell.source)
    Olive.OliveHighlighters.mark_julia!(tm)
    result = string(tm)
    inner = div("cell$cellid", text = result)
    style!(inner, "background-color" => "#171717", "border-radius" => 4px, "padding" => 3percent)
    output = div("outputcell$cellid", text = cell.outputs)
    div("cellcontainter$cellid", children = [inner, output])
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:markdownro}, proj::Project{<:Any})
    cellid = cell.id
    inner = tmd("cell$cellid", cell.source)
    div("cellcontainter$cellid", children = [inner])::Component{:div}
end

#==
Directories
==#

function build(c::AbstractConnection, dir::Directory{:readonly})
    dirid, diruri = if ~(contains(dir.uri, "!;"))
        dirid = Toolips.gen_ref(5)
        diruri = dir.uri
        dir.uri = dirid * "!;" * dir.uri
        (dirid, diruri)
    else
        splts = split(dir.uri, "!;")
        (splts[1], splts[2])
    end
    newcells = Olive.directory_cells(diruri, wdtype = :roselector)
    childs = Vector{Servable}([begin
        build_readonly_filecell(c, mcell, dir)
    end for mcell in newcells])
    selectionbox = div("selbox$dirid", children = childs, ex = "0")
    style!(selectionbox, "height" => 0percent, "overflow" => "hidden", "opacity" => 0percent)
    lblbox = div("main$dirid", children = [a(text = diruri, style = "color:#ffc494;")])
    style!(lblbox, "cursor" => "pointer")
    dirbox = div("seldir$dirid", children = [lblbox, selectionbox])
    on(c, lblbox, "click") do cm::ComponentModifier
        selboxn = "selbox$dirid"
        if cm[selboxn]["ex"] == "0"
            style!(cm, selboxn, "height" => "auto", "opacity" => 100percent)
            cm[selboxn] = "ex" => "1"
            return
        end
        style!(cm, selboxn, "height" => 0percent, "opacity" => 0percent)
        cm[selboxn] = "ex" => "0"
    end
    style!(dirbox, "background-color" => "#752835", "overflow" => "hidden", "border-radius" => 0px)
    dirbox::Component{:div}
end

function build_readonly_filecell(c::AbstractConnection, cell::Cell{:roselector}, dir::Directory{<:Any})
    build(c, cell, dir)
end

function build_readonly_filecell(c::AbstractConnection, cell::Cell{<:Any}, dir::Directory{<:Any})
    maincell = Olive.build_selector_cell(c, cell, dir, false)
    on(c, maincell, "dblclick") do cm::ComponentModifier
        cells = olive_read(cell)
        cells = convert_readonly(cells)
        projdata::Dict{Symbol, Any} = Dict{Symbol, Any}(:cells => cells,
            :path => cell.outputs, :pane => "one")
        newproj = Project{:readonly}(cell.source, projdata)
        env = c[:OliveCore].users[getname(c)].environment
        push!(env.projects, newproj)
        tab::Component{:div} = build_tab(c, newproj)
        Olive.open_project(c, cm, newproj, tab)
    end
    maincell
end

function build(c::Connection, cell::Cell{:roselector}, d::Directory{<:Any}, bind::Bool = true)
    filecell::Component{<:Any} = Olive.build_base_cell(c, cell, d, binding = false)
    filecell[:children] = filecell[:children]["cell$(cell.id)label"]
    style!(filecell, "background-color" => "#221440")
    on(c, filecell, "click") do cm::ComponentModifier
        path = cell.outputs * "/" * cell.source
        newcells = Olive.directory_cells(path, wdtype = :roselector)
        dir = Directory(path)
        childs = Vector{Servable}([begin
            build_readonly_filecell(c, mcell, dir)
        end for mcell in newcells])
        dirid = split(d.uri, "!;")[1]
        returner = Olive.build_any_returner(build_readonly_filecell, c, path, "selbox$dirid", d.uri, :roselector)
        set_children!(cm, "selbox$dirid", [returner, childs ...])
    end
    filecell::Component{<:Any}
end

#==
projects
==#

function build_tab(c::Connection, p::Project{:readonly}; hidden::Bool = false)
    fname::String = p.id
    tabbody::Component{:div} = div("tab$(fname)", class = "tabopen")
    style!(tabbody, "background-color" => "#ad4463")
    if(hidden)
        tabbody[:class]::String = "tabclosed"
    end
    tablabel::Component{:a} = a("tablabel$(fname)", text = p.name, class = "tablabel")
    style!(tablabel, "color" => "#fff8d4")
    push!(tabbody, tablabel)
    on(c, tabbody, "click") do cm::ComponentModifier
        if p.id in cm
            return
        end
        projects::Vector{Project{<:Any}} = CORE.users[getname(c)].environment.projects
        inpane = findall(proj::Project{<:Any} -> proj[:pane] == p[:pane], projects)
        [begin
            if projects[e].id != p.id 
                Olive.style_tab_closed!(cm, projects[e])
            end
            nothing
        end  for e in inpane]
        projbuild::Component{:div} = build(c, cm, p)
        set_children!(cm, "pane_$(p[:pane])", [projbuild])
        cm["tab$(fname)"] = :class => "tabopen"
        if length(p.data[:cells]) > 0
            focus!(cm, "cell$(p[:cells][1].id)")
        end
    end
    on(c, tabbody, "dblclick") do cm::ComponentModifier
        if "$(fname)dec" in cm
            return
        end
        decollapse_button::Component{:span} = span("$(fname)dec", text = "arrow_left", class = "tablabel")
        on(c, decollapse_button, "click") do cm2::ComponentModifier
            remove!(cm2, "$(fname)close")
            remove!(cm2, "$(fname)add")
            remove!(cm2, "$(fname)restart")
            remove!(cm2, "$(fname)run")
            remove!(cm2, "$(fname)switch")
            remove!(cm2, "$(fname)dec")
        end
        style!(decollapse_button, "color" => "blue")
        controls::Vector{<:AbstractComponent} = Olive.tab_controls(c, p)
        controls = [controls["$(fname)switch"], controls["$(fname)close"]]
        style!(controls[1], "color" => "white")
        insert!(controls, 1, decollapse_button)
        [begin append!(cm, tabbody, serv); nothing end for serv in controls]
    end
    tabbody::Component{:div}
end

end # module OliveReadOnly
