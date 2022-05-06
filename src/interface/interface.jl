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
html(hypertxt::String) = http::HTTP.Stream -> hypertxt::Function

"""
### html_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
html_file(URI::String) = http -> HTTP.Response(200, read(URI))::Function

"""
### file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
file(URI::String) = http::HTTP.Stream -> HTTP.Response(200, read(URI))::Function

"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be CSS.
#### example
"""
css(css::String) = http::HTTP.Stream -> "<style>" * css * "</style>"::Function

"""
### css_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
css_file(URI::String) = begin
    http::HTTP.Stream -> """<link rel="stylesheet" href="$URI">"""::Function
end

"""
### html(::String) -> ::Function
------------------
Creates a servable from the provided string, which should be JavaScript.
#### example
"""
js(js::String) = http::HTTP.Stream -> "<script>" * js * "</script>"::Function

"""
### js_file(URI::String) -> ::Function
------------------
Creates a servable which will read and return the file denoted by its path in
URI.
#### example
"""
js_file(URI::String) = begin
    http::HTTP.Stream -> """<script src="$URI"></script>"""::Function
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
        http::HTTP.Stream -> f(http::HTTP.Stream)::Function
    else
        http::HTTP.Stream -> f()::Function
    end
end

function edit!(s::Servable, property::Pair)

end

end

function anim!(s::Servable, anim::Animation)

end

function get_text(s::Servable)

end

function add_route!(path::String, route::Route, )

end

function route(f::Function, route::String)
    Route(route, f)::Route
end

function route(route::String, s::Page)
    Route(route, s)::Route
end
