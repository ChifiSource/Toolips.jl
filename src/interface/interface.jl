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
### html_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
html_file(URI::String) = c::Connection -> HTTP.Response(200, read(URI))::Function

"""
### file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
file(URI::String) = c::Connection -> HTTP.Response(200, read(URI))::Function

"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be CSS.
#### example
"""
css(css::String) = http::Connection -> "<style>" * css * "</style>"::Function

"""
### css_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
css_file(URI::String) = begin
    http::Connection -> """<link rel="stylesheet" href="$URI">"""::Function
end

"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be JavaScript.
#### example
"""
js(js::String) = http::Connection -> "<script>" * js * "</script>"::Function

"""
### js_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
js_file(URI::String) = begin
    http::Connection -> """<script src="$URI"></script>"""::Function
end
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
        http::Connection -> f(http::HTTP.Stream)::Function
    else
        http::Connection -> f()::Function
    end
end

function modify!(s::Servable, )

end

function serve!(s::Servable, )

end

function reserve!(p::Servable, index::Integer)

end

function anim!(s::Servable, anim::Animation)

end

function get_text(s::Servable)

end

function route!(c::Connection, route::Route)

end

function route!(f::Function, c::Connection, route::Route)

end

function navigate!()

end

route(f::Function, route::String) = Route(route, f)::Route

route(route::String, s::Page) = Route(route, s)::Route
