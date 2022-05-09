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
Styles
==#
animate!(s::StyleComponent, a::Animation) = s.rules[:animation] = a.name

style!(c::Servable, s::Style) = c.properties[:class] = s.name

function copystyle!(c::Servable, c2::Servable)
    c.properties[:class] = c2.properties[:class]
end

macro keyframes!(anim::Animation, percentage::Float64, expr::Expression)
    percent = _percentage_text(percentage)
    try
        anim.keyframes[string(percentage)] = vcat(anim.keyframes[string(method)]
        eval(expr))
    catch
        anim.keyframes[Symbol("$percent")] = eval(expr)
    end
end

macro keyframes!(anim::Animation, percentage::Int64, expr::Expression)
    keyframes!(anim, float(percentage), expr)
end

macro keyframes!(anim::Animation, method::Symbol, expr::Expression)
    try
        anim.keyframes[string(method)] = vcat(anim.keyframes[string(method)],
        eval(expr))
    catch
        anim.keyframes[string(method)] = eval(expr)
    end
end

#==
Serving/Routing
==#
function write!(c::Connection, s::Servable)

end

function write!(c::Connection, s::String)

end

function route!(c::Connection, route::Route)

end

function route!(f::Function, c::Connection, route::Route)

end

route(f::Function, route::String) = Route(route, f)::Route

route(route::String, s::Servable) = Route(route, s)::Route

routes(rs::Route ...) = Vector{Route}([r for r in rs])

function navigate!()

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
function getargs(http::HTTP.Stream)
    target = split(http.message.target, '?')[2]
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
function getarg(http::Any, s::Symbol)
    getargs(http)[s]
end

"""
### getarg(::HTTP.Stream, ::Symbol, ::Type) -> ::Vector
------------------
This method is the same as getargs(::HTTP.Stream, ::Symbol), however types are
parsed as type T(). Note that "Cannot convert..." errors are possible with this
method.

"""
function getarg(http::HTTP.Stream, s::Symbol, T::Type)
    parse(getargs(http)[s], T)
end

"""
### getpost(http::HTTP.Stream) -> _
------------------
Returns the post argument data of an HTTP stream.

"""
function postarg(http::HTTP.Stream, s::Symbol)
    http.message.body
end


"""
### getpost(http::HTTP.Stream) -> _
------------------
Returns the post argument data of an HTTP stream.

"""
function postargs(http::HTTP.Stream)
    http.message.body
end


function get()

end

function post()

end
