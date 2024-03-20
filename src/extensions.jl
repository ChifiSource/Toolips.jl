#==
map
- additional connections
- logger
- files
- component interpolation
- Modifier/ClientModifier
- TransitionStack
==#

mutable struct MobileConnection <: AbstractConnection
    stream::HTTP.Stream
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
end

function convert(c::Connection, routes::Routes, into::Type{MobileConnection})
    get_client_system(c)[2]
end

function convert!(c::Connection, routes::Routes, into::Type{MobileConnection})
    MobileConnection(c.stream, c.data, routes)::MobileConnection
end

mutable struct WorkerConnection <: AbstractConnection
    stream::Any
    data::Dict{Symbol, Any}
    routes::Vector{AbstractRoute}
    pm::ProcessManager
end

function distribute!()

end

function assign!()

end

function convert(c::Connection, routes::Routes, into::Type{WorkerConnection})
    false
end

function convert!(c::Connection, routes::Routes, into::Type{WorkerConnection})
    if length(into.parameters) < 1
        throw("a WorkerConnection requires a type parameter.")
    end
    r = c.routes[get_target(c)]
 #   assigned_workers = 
    WorkerConnection(c.stream, c.data, c.routes, assigned)
end

mutable struct Logger <: AbstractExtension
    crayons::Vector{Crayon}
    prefix::String
    write::Bool
    writeat::Int64
    prefix_crayon::Crayon
    function Logger(prefix::String = "🌷 toolips> ", crayons::Crayon ...; dir::String = "logs.txt",
        write::Bool = false, writeat::Int64 = 3, prefix_crayon = Crayon(foreground  = :blue, bold = true))
        if write && ~(isfile(dir))
            try
                touch(dir)
            catch
                throw("Logger tried to make log file \"$dir\", but could not.")
            end
        end
        if length(crayons) < 1
            crayons = [Crayon(foreground  = :light_blue, bold = true)]
        end
        new([crayon for crayon in crayons], prefix, write, writeat, prefix_crayon)
    end
end

function log(l::Logger, message::String, at::Int64 = 1)
    
end

mutable struct AbstractFileRoute <: AbstractRoute end

function show!(c::Connection, plot::Any, mime::MIME{<:Any} = MIME"text/html"())
    plot_div::Component{<:Any}
    data::String = String(io.data)
    data = replace(data,
     """<?xml version=\"1.0\" encoding=\"utf-8\"?>\n""" => "")
    plot_div[:text] = data
end

function mount(fpair::Pair{String, String})
    fpath = fpair[2]
    target = fpair[1]
    if ~(isdir(fpath))
        return(route(c::Connection -> begin
            @info "hello?"
            write!(c, File(fpath))
        end, target))::Route{Connection}
    end
    [route(c::Connection -> write!(c, File(path)), target * "/" * fpath) for path in route_from_dir(fpath)]
end

function route_from_dir(path::String)
    dirs::Vector{String} = readdir(dir)
    routes::Vector{String} = []
    [begin
        if isfile("$dir/" * directory)
            push!(routes, "$dir/$directory")
        else
            if ~(directory in routes)
                newread::String = dir * "/$directory"
                newrs::Vector{String} = route_from_dir(newread)
                [push!(routes, r) for r in newrs]
            end
        end
    end for directory in dirs]
    routes::Vector{String}
end

function tmd(name::String = "markdown", s::String = "", p::Pair{String, <:Any} ...;
    args ...)
     mddiv::Component{:div} = div(name, p ..., args ...)
    md = Markdown.parse(replace(s, "<" => "", ">" => "", "\"" => ""))
    htm::String = html(md)
    mddiv[:text] = htm
    mddiv::Component{:div}
end

"""

"""
abstract type Modifier <: Servable end
abstract type AbstractComponentModifier <: Modifier end

setindex!(cm::AbstractComponentModifier, p::Pair, s::Any) = begin
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    key, val = p[1], p[2]
    push!(cm.changes,
    "document.getElementById('$s').setAttribute('$key','$val');")
end

function set_textdiv_caret!(cm::AbstractComponentModifier,
    txtd::Component{:div},
    char::Int64)
    push!(cm.changes, "setCurrentCursorPosition$(txtd.name)($char);")
end

function move!(cm::AbstractComponentModifier, p::Pair{<:Any, <:Any})
    firstname = p[1]
    secondname = p[2]
    if firstname <: AbstractComponent
        firstname = firstname.name
    end
    if secondname <: AbstractComponent
        secondname = secondname.name
    end
    push!(cm.changes, "
    document.getElementById('$firstname').appendChild(document.getElementById('$secondname'));
  ")
end

function remove!(cm::AbstractComponentModifier, s::Any)
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    push!(cm.changes, "document.getElementById('$s').remove();")
end

function set_text!(c::Modifier, s::Any, txt::Any)
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    if typeof(txt) <: AbstractComponent
        push!(c.changes, "document.getElementById('$s').innerHTML = $(txt.name);")
       return 
    end
    txt = replace(txt, "`" => "\\`")
    txt = replace(txt, "\"" => "\\\"")
    txt = replace(txt, "''" => "\\'")
    push!(c.changes, "document.getElementById('$s').innerHTML = `$txt`;")
end

function set_children!(cm::AbstractComponentModifier, s::Any, v::Vector{Servable})
    if typeof(s) <: AbstractComponent
        s = s.name
    end
    set_text!(cm, s, join([string(serv) for serv in v]))
end

function append!(cm::AbstractComponentModifier, name::Any, child::Servable)
    if typeof(name) <: AbstractComponent
       name = name.name
    end
    txt = replace(string(child), "`" => "\\`", "\"" => "\\\"", "'" => "\\'")
    push!(cm.changes, "document.getElementById('$name').appendChild(document.createRange().createContextualFragment(`$txt`));")
end

function insert!(cm::AbstractComponentModifier, name::String, i::Int64, child::Servable)
    spoofconn = Toolips.SpoofConnection()
    write!(spoofconn, child)
    txt = replace(spoofconn.http.text, "`" => "\\`", "\"" => "\\\"", "'" => "\\'")
    push!(cm.changes, "document.getElementById('$name').insertBefore(document.createRange().createContextualFragment(`$txt`), document.getElementById('$name').children[$(i - 1)]);")
end

function sleep!(cm::AbstractComponentModifier, time::Int64)
    push!(cm.changes, "await new Promise(r => setTimeout(r, $time));")
end

function style!(cc::Modifier, name::Any,  sname::Style)
    sname = sname.name
    if typeof(name) <: AbstractComponent
        name = name.name
    end
    push!(cc.changes, "document.getElementById('$name').className = '$sname';")
end

function style!(cm::AbstractComponentModifier, name::Any, sty::Pair{String, String} ...)
    if typeof(name) <: AbstractComponent
        name = name.name
    end
    push!(cm.changes,
        join(("document.getElementById('$name').style['$(p[1])'] = '$(p[2])';" for p in sty)))
end

function set_style!(cm::AbstractComponentModifier, name::Any, sty::Pair{String, String} ...)
    sstring = join(["$(p[1]):$(p[2])" for p in sty], ";")
    if typeof(name) <: AbstractComponent
        name = name.name
    end
    push!(cm.changes, "document.getElementById('$name').style = '$sstring'")
end

write!(c::Connection, ac::AbstractComponentModifier) = write!(c, join(ac.changes))

abstract type AbstractClientModifier <: AbstractComponentModifier end

function gen_ref(n::Int64 = 16)
    sampler = "iokrtshgjiosjbisjgiretwshgjbrthrthjtyjtykjkbnvjasdpxijvjr"
    samps = (rand(1:length(sampler)) for i in 1:n)
    join(sampler[samp] for samp in samps)
end


mutable struct ClientModifier <: AbstractClientModifier
    name::String
    changes::Vector{String}
    ClientModifier(name::String = gen_ref()) = begin
        new(name, Vector{String}())::ClientModifier
    end
end

function get_text(cl::AbstractClientModifier, name::String)
    Component{:property}("document.getElementById('$name').textContent;")
end

setindex!(cm::AbstractClientModifier, name::String, property::String, comp::Component{:property}) = begin
    push!(cm.changes, "document.getElementById('$name').setAttribute('$property',$comp);")
end

write!(c::AbstractConnection, cm::ClientModifier) = write!(c, funccl(cm))

function funccl(cm::ClientModifier = ClientModifier(), name::String = cm.name)
    """function $(name)(event){$(join(cm.changes))}"""
end

alert!(cm::AbstractComponentModifier, s::AbstractString) = push!(cm.changes,
        "alert('$s');")

function focus!(cm::AbstractComponentModifier, name::String)
    push!(cm.changes, "document.getElementById('$name').focus();")
end

function blur!(cm::AbstractComponentModifier, name::String)
    push!(cm.changes, "document.getElementById('$name').blur();")
end

function redirect!(cm::AbstractComponentModifier, url::AbstractString, delay::Int64 = 0)
    push!(cm.changes, """setTimeout(
    function () {window.location.href = "$url";}, $delay);""")
end

function next!(f::Function, cl::AbstractComponentModifier, comp::Any)
    if typeof(comp) <: AbstractComponent
        comp = comp.name
    end
    newcl = ClientModifier()
    f(newcl)
    fcl = funccl(newcl)
    push!(cl.changes,
    "document.getElementById('$comp').addEventListener('transitionend', $fcl);")
end

function update!(cm::AbstractComponentModifier, ppane::AbstractComponent, plot::Any)
    io::IOBuffer = IOBuffer();
    show(io, "text/html", plot)
    data::String = String(io.data)
    data = replace(data,
     """<?xml version=\"1.0\" encoding=\"utf-8\"?>\n""" => "")
    set_text!(cm, ppane.name, data)
end

function update_base64!(cm::AbstractComponentModifier, name::String, raw::Any,
    filetype::String = "png")
    io = IOBuffer();
    b64 = ToolipsServables.Base64.Base64EncodePipe(io)
    show(b64, "image/$filetype", raw)
    close(b64)
    mysrc = String(io.data)
    cm[name] = "src" => "data:image/$filetype;base64," * mysrc
end

function on(f::Function, component::Component{<:Any}, event::String)
    cl = ClientModifier("$(component.name)$(event)")
    f(cl)
    component["on$event"] = "$(cl.name)(event);"
    push!(component[:extras], script(cl.name, text = funccl(cl)))
end

function on(f::Function, event::String)
    cl = ClientModifier(); f(cl)
    scrpt = """addEventListener("$event", $(funccl(cl)));"""
    script("doc$event", text = scrpt)
end

function bind(f::Function, key::String, eventkeys::Symbol ...; on::Symbol = :down)
    eventstr::String = join(" event.$(event)Key && " for event in eventkeys)
    cl = ClientModifier()
    f(cl)
    script(cl.name, text = """addEventListener('key$on', function(event) {
            if ($eventstr event.key == "$(key)") {
            $(join(cl.changes))
            }
            });""")
end
