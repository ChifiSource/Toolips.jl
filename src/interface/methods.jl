import Base: +
#==
File/system stuff
==#
"""
### write_file(URI::String, http::HTTP.Stream) -> _
------------------
Writes a file to an HTTP.Stream.

"""
function write_file(URI::String, http::HTTP.Stream)
    open(URI, "r") do i
        write(http, i)
    end
end

function route_from_dir(dir::String)
    dirs = readdir(dir)
    routes::Vector{String} = []
    for directory in dirs
        if isfile("$dir/" * directory)
            push!(routes, "$dir/$directory")
        else
            if ~(directory in routes)
                newread = dir * "/$directory"
                newrs = route_from_dir(newread)
                [push!(routes, r) for r in newrs]
            end
        end
    end
    rts::Vector{Route} = []
    for directory in routes
        if isfile("$dir/" * directory)
            push!(rts, Route("/$directory", file("$dir/" * directory)))
        end
    end
    rts
end
#==
Data formatting stuff
==#
function _percentage_text(percentage::Float64)

end
"""
### parsetypes(data::AbstractString) -> T(data)
------------------
This method will turn strings of data read to their approapriate types. Notably
used by functions like getargs() in order to parse argument data into types.
Returns the data parsed into its implicit type. For reading in arguments as
specific types, see getargs(::HTTP.Stream, ::Symbol, ::Type)

"""
function parsetypes(data::AbstractString)
    x = nothing
    try
        x = parse(Int64, data)
    catch
        try
        x = parse(Bool, data)
        catch
            try
            x = parse(Float64, data)
            catch
            try
                x = parse(Array, data)
            catch
                try
                    x = parse(Dict, data)
                catch
                    x = data
                end
            end
        end
    end
end
    return(x)
end
#==
HTTP Arguments/Requests
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
function active_target(http::HTTP.Stream)

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
### getargs(::HTTP.Stream, ::Symbol, ::Type) -> ::Vector
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
function getpost(http::HTTP.Stream)
    http.message.body
end
#==
Servable Generators
==#
"""
### lists(::Pair{String, String} ...) -> ::Vector{List}
------------------
Creates multiple Lists much more quickly. Takes pairs. keys should be
labels for the list elements, values should be the href of that button. For
    more information on List, see List.

"""
function lists(dct::Pair{String, String} ...)
    lists::Vector{List} = []
    for (key, value) in dct
        push!(lists, List(label = key, href = value))
    end
    lists
end

"""
### +(::Function, ::Function) -> ::Page
------------------
Creates a page from two function servables.

"""
+(f::Function, f2::Function) = Page([f, f2])

"""
### +(::Page, ::Function) -> ::Page
------------------
An operator binding for p.add()

"""
+(p::Page, f::Function) = p.add(f)

"""
### +(::FormComponent, ::FormComponent) -> ::Page
------------------
Easy compound forms with the + operator. See Form for more information.

"""
+(fc::FormComponent, fc2::FormComponent) = Form(fc, fc2)

#==
Document Functions
WIP
==#
macro action(d::Symbol, expr::Expr)
    action_evaluator(expr.head, expr.args)
end
function action_evaluator(d::DocumentFunction, head, args)
    println(typeof(head)); println(typeof(args))

    known_symbols = Dict(:open => """var xmlHttp = new XMLHttpRequest();
                xmlHttp.open( "$", , true );""", :get)
end
