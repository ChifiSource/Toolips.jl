#==
 text/html
    Functions
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
    positional argument of type Connection.
#### example
function example()

end

page = fn(example)

function example(c::Connection)
    c[:logger].log(c, "hello world!")
end
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
"""
### properties(::Servable) -> ::Dict
------------------
Method binding for Servable.properties.
#### example

"""
properties(s::Servable) = s.properties

"""
### properties!(::Servable, ::Servable) -> _
------------------
Copies properties from s,properties into c.properties.
#### example

"""
properties!(c::Servable, s::Servable) = merge!(c.properties, s.properties)

"""
### push!(::Container, ::Component) -> _
------------------
Moves Component into Container.components.
#### example

"""
push!(s::Container, c::Component) = push!(s.components, c)

"""
### push!(::Container, ::Component ...) -> _
------------------
Moves Components into Container component.
#### example

"""
function push!(s::Container, c::Component ...)
    cs::Vector{Component} = push!(s.components, c)
end

"""
### push!(::Component, ::Component ...) -> ::Container
------------------
Combines two or more servables into a container and clones fields from the first
component.
#### example

"""
function push!(s::Component, d::Component ...)
    v::Vector{Component} = Vector{Component}(d)
    Container(s.name, s.tag. v, properties = s.properties)::Container
end

"""
### push!(::Component, ::Component) -> ::Container
------------------
Adds a component into a container and clones fields from the first
component.
#### example

"""
function push!(s::Component, d::Component)
    Container(s.name, s.tag. Vector{Component}([d]),
    properties = s.properties)::Container
end

"""
### getindex(::Servable, ::Symbol) -> ::Any
------------------
Returns a property value by symbol or name.
#### example

"""
getindex(s::Servable, symb::Symbol) = s.properties[symb]

"""
### getindex(::Servable, ::String) -> ::Any
------------------
Returns a property value by string or name.
#### example

"""
getindex(s::Servable, symb::String) = s.properties[symb]

"""
### setindex!(::Servable, ::Symbol, ::Any) -> ::Any
------------------
Sets the property represented by the symbol to the provided value.
#### example

"""
setindex!(s::Servable, symb::Symbol, a::Any) = s.properties[symb] = s

"""
### setindex!(::Servable, ::String, ::Any) -> ::Any
------------------
Sets the property represented by the string to the provided value.
#### example

"""
setindex!(s::Servable, symb::String, a::Any) = s.properties[symb] = s

#==
Styles
==#
"""
### animate!(::StyleComponent, ::Animation) -> _
------------------
Sets the Animation as a rule for the StyleComponent. Note that the
    Animation still needs to be written to the same Connection, preferably in
    a StyleSheet.
#### example

"""
animate!(s::StyleComponent, a::Animation) = s.properties[:animation] = a.name

"""
### style!(::Servable, ::Style) -> _
------------------
Applies the style to a servable.
#### example

"""
style!(c::Servable, s::Style) = c.properties[:class] = s.name

"""
### style!(::Style, ::Style) -> _
------------------
Copies the properties from the second style into the first style.
#### example

"""
style!(s::Style, s2::Style) = merge!(s.properties, s2.properties)

"""
### delete_keyframe!(::Animation, ::String) -> _
------------------
Deletes a given keyframe from an animation by keyframe name.
#### example

"""
function delete_keyframe!(s::Animation, key::String)
    delete!(s.keyframes, key)
end

function setindex!(anim::Animation, set::Pair, n::Int64)
    prop = string(set[1]) * ": "
    value = string(set[2]) * "; "
    if n in keys(anim.keyframes)
        anim.keyframes[frames[1]] = anim.keyframes[frames[1]] * "$prop $value"
    else
        push!(anim.keyframes, "%$n" => "$prop $value")
    end
end

function setindex!(anim::Animation, set::Pair, n::Symbol)
    prop = string(set[1]) * ": "
    value = string(set[2]) * "; "
    n = string(n)
    if n in keys(anim.keyframes)
        anim.keyframes[frames[1]] = anim.keyframes[frames[1]] * "$prop $value"
    else
        push!(anim.keyframes, "$n" => "$prop $value")
    end
end

"""
### push!(::Animation, p::Pair) -> _
------------------
Pushes a keyframe pair into an animation.
#### example

"""
push!(anim::Animation, p::Pair) = push!(anim.keyframes, [p[1]] => p[2])

#==
Serving/Routing
==#
"""
### write!(::Connection, ::Servable) -> _
------------------
Writes a Servable's return to a Connection's stream.
#### example

"""
write!(c::Connection, s::Servable) = write(c.http, s.f(c))


"""
### write!(c::Connection, s::Vector{Servable}) -> _
------------------
Writes, in order of element, each Servable inside of a Vector of Servables.
#### example

"""
write!(c::Connection, s::Vector{Servable}) = [write!(c, s) for c in s]

"""
### write!(::Connection, ::String) -> _
------------------
Writes the String into the Connection as HTML.
#### example

"""
write!(c::Connection, s::String) = write(c.http, s)

"""
### write!(::Connection, ::Any) -> _
------------------
Attempts to write any type to the Connection's stream.
#### example

"""
write!(c::Connection, s::Any) = write(c.http, s)

"""
### startread!(::Connection) -> _
------------------
Resets the seek on the Connection.
#### example

"""
startread!(c::Connection) = startread(c.http)

"""
### route!(::Connection, ::Route) -> _
------------------
Modifies the routes on the Connection.
#### example

"""
route!(c::Connection, route::Route) = push!(c.routes, route.path => route.page)

"""
### unroute!(::Connection, ::String) -> _
------------------
Removes the route with the key equivalent to the String.
#### example

"""
unroute!(c::Connection, r::String) = delete!(c.routes, r)

"""
### route!(::Function, ::Connection, ::String) -> _
------------------
Routes a given String to the Function.
#### example

"""
route!(f::Function, c::Connection, route::String) = push!(c.routes, route => f)

"""
### route(::Function, ::String) -> ::Route
------------------
Creates a route from the Function.
#### example

"""
route(f::Function, route::String) = Route(route, f)::Route

"""
### route(::String, ::Servable) -> ::Route
------------------
Creates a route from a Servable.
#### example

"""
route(route::String, s::Servable) = Route(route, s)::Route

"""
### routes(::Route ...) -> ::Vector{Route}
------------------
Turns routes provided as arguments into a Vector{Route} with indexable routes.
This is useful because this is the type that the ServerTemplate constructor
likes.
#### example

"""
routes(rs::Route ...) = Vector{Route}([r for r in rs])

"""
### navigate!(::Connection, ::String) -> _
------------------
Routes a connected stream to a given URL.
#### example

"""
function navigate!(c::Connection, url::String)
    HTTP.get(url, response_stream = c.http, status_exception = false)
end

"""
### stop!(x::Any) -> _
------------------
An alternate binding for close(x). Stops a server from running.
#### example

"""
function stop!(x::Any)
    close(x)
end

#==
Request/Args
==#
"""
### getargs(::Connection) -> ::Dict
------------------
The getargs method returns arguments from the HTTP header (GET requests.)
Returns a full dictionary of these values.
#### example

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
### getargs(::Connection, ::Symbol) -> ::Dict
------------------
Returns the requested arguments from the target.
#### example
"""
function getarg(c::Connection, s::Symbol)
    getargs(c)[s]
end

"""
### getarg(::Connection, ::Symbol, ::Type) -> ::Vector
------------------
This method is the same as getargs(::HTTP.Stream, ::Symbol), however types are
parsed as type T(). Note that "Cannot convert..." errors are possible with this
method.
#### example
"""
function getarg(c::Connection, s::Symbol, T::Type)
    parse(getargs(http)[s], T)
end

"""
### postarg(::Connection, ::Symbol) -> ::Any
------------------
Get a body argument of a POST response by name.
#### example

"""
function postarg(c::Connection, s::Symbol)

end

"""
### postarg(::Connection, ::Symbol, ::Type) -> ::Any
------------------
Get a body argument of a POST response by name. Will be parsed into the
provided type.
#### example

"""
function postarg(c::Connection, s::Symbol, T::Type)

end

"""
### postargs(::Connection, ::Symbol, ::Type) -> ::Dict
------------------
Get arguments from the request body.
#### example

"""
function postargs(c::Connection)
    http.message.body
end

"""
### get() -> ::Dict
------------------
Quick binding for an HTTP GET request.
#### example

"""
function get(url::String)

end

"""
### post() ->
------------------
Quick binding for an HTTP POST request.
#### example

"""
function post(url::String)

end
