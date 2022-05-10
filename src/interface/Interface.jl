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


getindex(s::Servable, symb::Symbol) = s.properties[symb]


setindex!(s::Servable, symb::Symbol, a::Any) = s.properties[symb] = s
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
animate!(s::StyleComponent, a::Animation) = s.rules[:animation] = a.name

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
Copies the rules from the second style into the first style.
#### example

"""
style!(s::Style, s2::Style) = merge!(s.rules, s2.rules)

"""
### @keyframe!(::Symbol, ::Style) -> _
------------------
Adds a new keyframe to the animation servable. Note that the animation is
the symbol in this dispatch. Puts the frame arguments into a vector.
Use percentages, from/to, or pixels abbreviated in a string in order to
input values (). There should be three elements to every call, and it will not
follow Julian syntax. The first element will be the position, a percentage OR
from/to. The second is the style rule to modify, the third is the value to
change it to.
You can apply animations to Styles using the animate! method. This macro calls
keyframe!(anim::Symbol, frames::Vector{String}).
#### example
animation = Animation("hello")
@keyframe! animation "%50" opacity "5o%"
"""
macro keyframe!(anim::Symbol, keyframes::Any ...)
    kf = [string(frame) for frame in keyframes]
    keyframe!(s, kf)
end

"""
### delete_keyframe!(::Animation, ::String) -> _
------------------
Deletes a given keyframe from an animation by keyframe name.
#### example

"""
function delete_keyframe!(s::Animation, key::String)
    delete!(s.keyframes, key)
end

"""
### keyframe!(::Symbol, ::Style) -> _
------------------
Adds a new keyframe to the animation servable. Note that the animation is
the symbol in this dispatch. Puts the frame arguments into a vector.
Use percentages, from/to, or pixels abbreviated in a string in order to
input values (). There should be three elements to every call, and it will not
follow Julian syntax. The first element will be the position, a percentage OR
from/to. The second is the style rule to modify, the third is the value to
change it to.
You can apply animations to Styles using the animate! method.
#### example
animation = Animation("hello")
@keyframe! animation "%50" opacity "5o%"
"""
function keyframe!(anim::Symbol, frames::Vector{String})
    anim::Animation = eval(anim)
    prop = string(frames[2]) * ": "
    value = string(frames[3]) * "; "
    if string(frames[1]) in keys(anim.keyframes)
        anim.keyframes[frames[1]] = anim.keyframes[frames[1]] * "$prop $value"
    else
        push!(anim.keyframes, frames[1] => "$prop $value")
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
write!(c::Connection, s::Servable) = write(c.http, s.f(c))

properties!(c::Servable, s::Servable) = merge!(c.properties, s.properties)

write!(c::Connection, s::Vector{Servable}) = [write!(c, s) for c in s]

write!(c::Connection, s::String) = write(c.http, s)

write!(c::Connection, s::Any) = write(http, s)
startread!(c::Connection) = startread(http)
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
