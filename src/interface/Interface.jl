#==
 text/html
    Components
==#
"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be HTML.
#### example
"""
html(hypertxt::String) = c::Connection -> write!(c, hypertxt)::Function
"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be CSS.
#### example
"""
css(css::String) = http::Connection -> "<style>" * css * "</style>"::Function

"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be JavaScript.
#### example
"""
js(js::String) = http::Connection -> "<script>" * js * "</script>"::Function
#==
Functions
==#
"""
### fn(::Function) -> ::Function
------------------
Turns any function into a servable. Functions can optionally take the single
    positional argument "http."
#### example

"""
function fn(f::Function)
    m::Method = first(methods(f))
    if m.nargs > 2 | m.nargs < 1
        throw(ArgumentError("Expected either 1 or 2 arguments."))
    elseif m.nargs == 2
        http::Connection -> f(http)::Function
    else
        http::Connection -> f()::Function
    end
end
#==
Indexing/iter
==#
properties(s::Servable) = s.properties
getindex(s::Servable, symb::Symbol) = s.properties[symb]
setindex!(s::Servable, symb::Symbol, a::Any) = s.properties[symb] = s
#==
Styles
==#
animate!(s::StyleComponent, a::Animation) = s.rules[:animation] = a.name

style!(c::Servable, s::Style) = c.properties[:class] = s.name

function copystyle!(c::Servable, c2::Servable)
    c.properties[:class] = c2.properties[:class]
end

macro keyframe!(anim::Symbol, keyframes::Any ...)
    anim::Animation = eval(anim)
    kf = [string(frame) for frame in keyframes]
    keyframe!(anim, kf)
end

function keyframe!(anim::Animation, frames::Vector{String})
    prop = string(frames[2]) * ": "
    value = string(frames[3]) * "; "
    if string(frames[1]) in keys(anim.keyframes)
        anim.keyframes[frames[1]] = anim.keyframes[frames[1]] * "$prop $value"
    else
        push!(anim.keyframes, frames[1] => "$prop $value")
    end
end

push!(anim::Animation, p::Pair) = push!(anim.keyframes, [p[1]] => p[2])

#==
Serving/Routing
==#
write!(c::Connection, s::Servable) = write(c.http, s.f(c))

write!(c::Connection, s::Vector{Servable}) = [write!(c, s) for c in s]
write!(c::Connection, s::String) = write(c.http, s)

route!(c::Connection, route::Route) = push!(c.routes, route.path => route.page)

startwrite!(c::Connection) = startwrite(c.http)

unroute!(c::Connection, r::String) = delete!(c.routes, r)

route!(f::Function, c::Connection, route::String) = push!(c.routes, route => f)

route(f::Function, route::String) = Route(route, f)::Route

route(route::String, s::Servable) = Route(route, s)::Route

routes(rs::Route ...) = Vector{Route}([r for r in rs])

function navigate!(c::Connection, url::String)
    HTTP.get(url, response_stream = c.http, status_exception = false)
end

function stop!(x::Any)
    close(x)
end

#==
Request/Args
==#
"""
### getargs(::HTTP.Stream) -> ::Dict
------------------
The getargs method returns arguments from the HTTP header (GET requests.)
Returns a full dictionary of these values.

"""
function getargs(c::Connection)
    target::String = split(c.http.message.target, '?')[2]
    target = replace(target, "+" => " ")
    args = split(target, '&')
    arg_dict = Dict()
    for arg in args
        keyarg = split(arg, '=')
        x = tryparse(keyarg[2])
        push!(arg_dict, Symbol(keyarg[1]) => x)
    end
    return(arg_dict)
end

"""
### getargs(::HTTP.Stream, ::Symbol) -> ::Vector
------------------
Returns the requested arguments from the target.

"""
function getarg(c::Connection, s::Symbol)
    getargs(c)[s]
end

"""
### getarg(::HTTP.Stream, ::Symbol, ::Type) -> ::Vector
------------------
This method is the same as getargs(::HTTP.Stream, ::Symbol), however types are
parsed as type T(). Note that "Cannot convert..." errors are possible with this
method.

"""
function getarg(c::Connection, s::Symbol, T::Type)
    parse(getargs(http)[s], T)
end

"""

"""
function postarg(c::Connection, s::Symbol)

end


"""

"""
function postargs(http::HTTP.Stream)
    http.message.body
end


function get()

end

function post()

end
