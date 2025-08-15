module OliveReadOnly
using Olive
using Olive.Toolips
using Olive.Toolips.Components

convert_readonly(cell::Cell{:image}) = begin
    convimg = base64img("", cell.outputs[2], lowercase(cell.source))
    Cell{:imagero}(convimg[:src], "$(cell.outputs[3])!|$(cell.outputs[4])")
end

convert_readonly(cell::Cell{:vimage}) = begin
    Cell{:vimagero}("", cell.source)
end

convert_readonly(cell::Cell{:code}) = begin

end

convert_readonly(cell::Cell{:markdown}) = begin

end

function build(c::AbstractConnection, dir::Directory{:readonly})
    path_notifier = h3("selectnotify", text = dir.uri)
    newcells = directory_cells(dir.uri, wdtype = :switchselector)
    childs = Vector{Servable}([begin
        build_selector_cell(c, mcell, dir)
    end for mcell in newcells])
    selectionbox = div("selectionbox", children = childs)
    dirbox = div("selectdir", children = [path_notifier, selectionbox])
    dirbox::Component{:div}
end

function build_readonly_filecell(c::AbstractConnection, cell::Cell{<:Any}, dir::Directory{<:Any})

end

function build_tab(c::Connection, p::Project{:readonly}; hidden::Bool = false)
    fname::String = p.id
    tabbody::Component{:div} = div("tab$(fname)", class = "tabopen")
    if(hidden)
        tabbody[:class]::String = "tabclosed"
    end
    tablabel::Component{:a} = a("tablabel$(fname)", text = p.name, class = "tablabel")
    push!(tabbody, tablabel)
    on(c, tabbody, "click") do cm::ComponentModifier
        if p.id in cm
            return
        end
        projects::Vector{Project{<:Any}} = CORE.users[getname(c)].environment.projects
        inpane = findall(proj::Project{<:Any} -> proj[:pane] == p[:pane], projects)
        [begin
            if projects[e].id != p.id 
                style_tab_closed!(cm, projects[e])
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
        controls::Vector{<:AbstractComponent} = tab_controls(c, p)
        insert!(controls, 1, decollapse_button)
        [begin append!(cm, tabbody, serv); nothing end for serv in controls]
    end
    tabbody::Component{:div}
end


end # module OliveReadOnly
