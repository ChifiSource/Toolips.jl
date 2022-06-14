var documenterSearchIndex = {"docs":
[{"location":"overview/#toolips","page":"Overview","title":"toolips","text":"","category":"section"},{"location":"overview/#a-manic-web-development-framework","page":"Overview","title":"a manic web-development framework","text":"","category":"section"},{"location":"overview/","page":"Overview","title":"Overview","text":"","category":"page"},{"location":"overview/","page":"Overview","title":"Overview","text":"Modules = [Toolips]","category":"page"},{"location":"overview/#Toolips.Toolips","page":"Overview","title":"Toolips.Toolips","text":"Created in June, 2022 by chifi - an open source software dynasty. by team toolips This software is MIT-licensed.\n\nToolips\n\nToolips.jl is a fast, asynchronous, low-memory, full-stack, and reactive web-development framework always written in pure Julia.\n\nModule Composition\n\nToolips\n\n\n\n\n\n","category":"module"},{"location":"overview/#Toolips.Component","page":"Overview","title":"Toolips.Component","text":"Component <: Servable\n\nname::String f::Function properties::Dict –––––––––\n\nname::String - The name field is the way that a component is denoted in code.\nf::Function - The function that gets called with the Connection as an\n\nargument.\n\nproperties::Dict - A dictionary of symbols and values.\n\n\n\nconstructors\n\nComponent(name::String, tag::String, properties::Dict)\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.Connection","page":"Overview","title":"Toolips.Connection","text":"Connection\n\nroutes::Dict\nhttp::HTTP.Stream\nextensions::Dict\n\nThe connection type is passed into route functions and pages as an argument. This is both for functions, as well as Servable.f() methods. This constructor     should not be called directly. Instead, it is called by the server and     passed through the function pipeline. Indexing a Connection will return         the extension named with that symbol.\n\nexample\n\n                  #  v The Connection\nhome = route(\"/\") do c::Connection\n    c[Logger].log(\"We can index extensions.\")\n    c.routes[\"/\"] = c::Connection -> write!(c, \"rerouting!\")\n    httpstream = c.http\n    write!(c, \"Hello world!\")\n    myheading::Component = h(\"myheading\", 1, text = \"Whoa!\")\n    write!(c, myheading)\nend\n\n\n\nField Info\n\nroutes::Dict - A dictionary of routes where the keys\n\nare the routed URL and the values are the functions to those keys.\n\nhttp::HTTP.Stream - The stream for this current peer's connection.\nextensions::Dict - A dictionary of extensions to load with the\n\nname to reference as keys and the extension as the pair.\n\nConstructors\n\nConnection\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.File","page":"Overview","title":"Toolips.File","text":"File\n\ndir::String f::Function –––––––––\n\ndir::String - The directory of a file to serve.\nf::Function - Function whose output to be written to http().\n\n\n\nconstructors\n\nFile(dir::String)\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.Files","page":"Overview","title":"Toolips.Files","text":"Files\n\ntype::Symbol directory::String f::Function –––––––––\n\ntype::Symbol - The type of extension. There are three different selections\n\nyou can choose from. :connection :routing :func. A :connection extension will be provided in Connection.extensions. A :routing function is passed a Dict of routes as an argument. The last is a function argument, which is just a specific function to run from the top-end to the server.\n\ndirectory::String - The directory to route the files from.\nf::Function - The function f() called with a Connection.\n\n\n\nconstructors\n\nFiles(dir::String)\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.Logger","page":"Overview","title":"Toolips.Logger","text":"Logger\n\nout::String levels::Dict log::Function –––––––––\n\nField Info\n\nout::String\n\nRgw output file for the logger to write to.\n\nlog::Function\n\nA Logger logs information with different levels. Holds the function log(), connected to the function _log(). Methods:\n\nlog(::Int64, ::String)\nlog(::String)\nlog(::HTTP.Stream, ::String)\n\nWrites to HTML console, and also logs at level 1 with logger.\n\nlevels::Dict\n\n\n\nConstructors\n\nLogger(levels::Dict{level_count::Int64 => crayon::Crayons.Crayon};                     out::String = pwd() * \"logs/log.txt\") Logger(; out::String = pwd() * \"/logs/log.txt\")\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.Route","page":"Overview","title":"Toolips.Route","text":"Route{T}\n\npath::String\npage::T\n\nA route is added to a ServerTemplate using either its constructor, or the ServerTemplate.add(::Route) method. Each route calls either a particular servable or function; the type of which denoted by T. The Route type is     commonly constructed using the do syntax with the route(::Function, String)     method.\n\nexample\n\n# Constructors\nroute = Route(\"/\", p(text = \"hello\"))\n\nfunction example(c::Connection)\n    write!(c, \"hello\")\nend\n\nroute = Route(\"/\", example)\n\n# method\nroute = route(\"/\") do c\n    write!(c, \"Hello world!\")\n    write!(c, p(text = \"hello\"))\n    # we can also use extensions!\n    c[:logger].log(\"hello world!\")\nend\n\n\n\nfields\n\npath::String\n\nThe path, e.g. \"/\" at which to direct to the given component.\n\npage::T (::Function || T <: Component)\n\nThe servable to serve at this given route.\n\nconstructors\n\nRoute(path::String, f::Function) where\nRoute(path::String, s::Servable)\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.Servable","page":"Overview","title":"Toolips.Servable","text":"abstract type Servable\n\nServables can be written to a Connection via thier f() function and the interface. They can also be indexed with strings or symbols to change properties\n\nConsistencies\n\nf::Function - Function whose output to be written to http().\nproperties::Dict - The properties of a given Servable. These are written\n\ninto the servable on the calling of f().\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.ServerExtension","page":"Overview","title":"Toolips.ServerExtension","text":"abstract type ServerExtension\n\nServer extensions are loaded into the server on startup, and can have a few different abilities according to their type field's value. There are three types to be aware of.\n\n\n\nConsistencies\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.ServerTemplate","page":"Overview","title":"Toolips.ServerTemplate","text":"ServerTemplate\n\nip::String\nport::Integer\nroutes::Vector{Route}\nextensions::Dict\nremove::Function\nadd::Function\nstart::Function\n\nThe ServerTemplate is used to configure a server before running. These are usually made and started inside of a main server file. –––––––––\n\nField Info\n\nip::String\nport::Integer\nroutes::Vector{Route}\nextensions::Dict\nremove::Function\nadd::Function\nstart::Function\n\n\n\nConstructors\n\nServerTemplate(ip::String, port::Int64, routes::Dict; extensions::Dict)\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.StyleComponent","page":"Overview","title":"Toolips.StyleComponent","text":"abstract type StyleComponent <: Servable\n\nNo different from a normal Servable, simply an abstract type step for the interface to separate working with Animations and Styles.\n\nServable Consistencies\n\nServables can be written to a Connection via thier f() function and the\ninterface. They can also be indexed with strings or symbols to change properties\n##### Consistencies\n- f::Function - Function whose output to be written to http().\n- properties::Dict - The properties of a given Servable. These are written\ninto the servable on the calling of f().\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.ToolipsServer","page":"Overview","title":"Toolips.ToolipsServer","text":"abstract type ToolipsServer\n\nToolipsServers are returned whenever the ServerTemplate.start() field is called. If you are running your server as a module, it should be noted that commonly a global start() method is used and returns this server, and dev is where this module is loaded, served, and revised.\n\nConsistencies\n\nroutes::Dict - The server's route => function dictionary.\nextensions::Dict - The server's currently loaded extensions.\nserver::Any - The server, whatever type it may be...\n\n\n\n\n\n","category":"type"},{"location":"overview/#Toolips.WebServer","page":"Overview","title":"Toolips.WebServer","text":"\n\n\n\n","category":"type"},{"location":"overview/#Base.get-Tuple{String}","page":"Overview","title":"Base.get","text":"Interface\n\nget() -> ::Dict\n\n\n\nQuick binding for an HTTP GET request.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.getindex-Tuple{Connection, String}","page":"Overview","title":"Base.getindex","text":"\n\n\n\n","category":"method"},{"location":"overview/#Base.getindex-Tuple{Connection, Symbol}","page":"Overview","title":"Base.getindex","text":"\n\n\n\n","category":"method"},{"location":"overview/#Base.getindex-Tuple{Toolips.Servable, String}","page":"Overview","title":"Base.getindex","text":"Interface\n\ngetindex(::Servable, ::String) -> ::Any\n\n\n\nReturns a property value by string or name.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.getindex-Tuple{Toolips.Servable, Symbol}","page":"Overview","title":"Base.getindex","text":"Interface\n\ngetindex(::Servable, ::Symbol) -> ::Any\n\n\n\nReturns a property value by symbol or name.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.getindex-Tuple{WebServer, Symbol}","page":"Overview","title":"Base.getindex","text":"\n\n\n\n","category":"method"},{"location":"overview/#Base.push!-Tuple{Animation, Pair}","page":"Overview","title":"Base.push!","text":"Interface\n\npush!(::Animation, p::Pair) -> _\n\n\n\nPushes a keyframe pair into an animation.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.push!-Tuple{Component, Toolips.Servable}","page":"Overview","title":"Base.push!","text":"Interface\n\npush!(::Component, ::Component) ->\n\n\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.push!-Tuple{Component, Vararg{Toolips.Servable}}","page":"Overview","title":"Base.push!","text":"Interface\n\npush!(::Component, ::Component ...) -> ::Component\n\n\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.push!-Tuple{Connection, Any}","page":"Overview","title":"Base.push!","text":"\n\n\n\n","category":"method"},{"location":"overview/#Base.setindex!-Tuple{Animation, Pair, Int64}","page":"Overview","title":"Base.setindex!","text":"Interface\n\nsetindex!(::Animation, ::Pair, ::Int64) -> _\n\n\n\nSets the animation at the percentage of the Int64 to modify the properties of pair.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.setindex!-Tuple{Animation, Pair, Symbol}","page":"Overview","title":"Base.setindex!","text":"Interface\n\nsetindex!(::Animation, ::Pair, ::Int64) -> _\n\n\n\nSets the animation at the corresponding key-word's position.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.setindex!-Tuple{Connection, Function, String}","page":"Overview","title":"Base.setindex!","text":"\n\n\n\n","category":"method"},{"location":"overview/#Base.setindex!-Tuple{Toolips.Servable, Any, String}","page":"Overview","title":"Base.setindex!","text":"Interface\n\nsetindex!(::Servable, ::String, ::Any) -> ::Any\n\n\n\nSets the property represented by the string to the provided value.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Base.setindex!-Tuple{Toolips.Servable, Any, Symbol}","page":"Overview","title":"Base.setindex!","text":"Interface\n\nsetindex!(::Servable, ::Symbol, ::Any) -> ::Any\n\n\n\nSets the property represented by the symbol to the provided value.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips._log-Tuple{HTTP.Streams.Stream, String}","page":"Overview","title":"Toolips._log","text":"_log(http::HTTP.Stream, message::String) -> _\n\n\n\nBinded call for the field log() inside of Logger(). This will log both to the     JavaScript/HTML console –––––––––\n\nexample (Closure from Logger)\n\nlog(http::HTTP.Stream, message::String) = _log(http, message)\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips._log-Tuple{Int64, String, Dict, String}","page":"Overview","title":"Toolips._log","text":"_log(level::Int64, message::String, levels::Dict, out::String) -> _\n\n\n\nBinded call for the field log() inside of Logger(). See ?(Logger) for more     details on the field log. All arguments are fields of that type. Return is a     printout into the REPL as well as an append to the log file, provided by the     out URI. –––––––––\n\nexample (Closure from Logger)\n\nlog(level::Int64, message::String) = _log(level, message, levels, out) log(message::String) = _log(1, message, levels, out)\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips._start-Tuple{AbstractVector, String, Integer, Dict}","page":"Overview","title":"Toolips._start","text":"Core\n\n_start(routes::AbstractVector, ip::String, port::Integer,\n\nextensions::Dict) -> (::Sockets.HTTPServer)\n\nThis is an internal function for the ServerTemplate. This function is binded to     the ServerTemplate.start field.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.animate!-Tuple{Toolips.StyleComponent, Animation}","page":"Overview","title":"Toolips.animate!","text":"Interface\n\nanimate!(::StyleComponent, ::Animation) -> _\n\n\n\nSets the Animation as a rule for the StyleComponent. Note that the     Animation still needs to be written to the same Connection, preferably in     a StyleSheet.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.argsplit-Tuple{Any}","page":"Overview","title":"Toolips.argsplit","text":"\n\n\n\n","category":"method"},{"location":"overview/#Toolips.components-Tuple{Vararg{Toolips.Servable}}","page":"Overview","title":"Toolips.components","text":"\n\n\n\n","category":"method"},{"location":"overview/#Toolips.create_serverdeps-Tuple{String}","page":"Overview","title":"Toolips.create_serverdeps","text":"create_serverdeps(::String) -> _\n\n\n\nCreates the essential portions of the webapp file structure.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.delete_keyframe!-Tuple{Animation, String}","page":"Overview","title":"Toolips.delete_keyframe!","text":"Interface\n\ndelete_keyframe!(::Animation, ::String) -> _\n\n\n\nDeletes a given keyframe from an animation by keyframe name.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.download!-Tuple{Connection, String}","page":"Overview","title":"Toolips.download!","text":"Interface\n\ndownload!() ->\n\n\n\nDownloads a file to a given user's computer.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.generate_router-Tuple{AbstractVector, Any, Dict}","page":"Overview","title":"Toolips.generate_router","text":"Core\n\ngenerate_router(routes::AbstractVector, server::Any, extensions::Dict)\n\n\n\nThis method is used internally by the _start method. It returns a closure function that both routes and calls functions.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.getarg-Tuple{Connection, Symbol, Type}","page":"Overview","title":"Toolips.getarg","text":"Interface\n\ngetarg(::Connection, ::Symbol, ::Type) -> ::Vector\n\n\n\nThis method is the same as getargs(::HTTP.Stream, ::Symbol), however types are parsed as type T(). Note that \"Cannot convert...\" errors are possible with this method.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.getarg-Tuple{Connection, Symbol}","page":"Overview","title":"Toolips.getarg","text":"Interface\n\ngetargs(::Connection, ::Symbol) -> ::Dict\n\n\n\nReturns the requested arguments from the target.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.getargs-Tuple{Connection}","page":"Overview","title":"Toolips.getargs","text":"Interface\n\ngetargs(::Connection) -> ::Dict\n\n\n\nThe getargs method returns arguments from the HTTP header (GET requests.) Returns a full dictionary of these values.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.getip-Tuple{Connection}","page":"Overview","title":"Toolips.getip","text":"\n\n\n\n","category":"method"},{"location":"overview/#Toolips.navigate!-Tuple{Connection, String}","page":"Overview","title":"Toolips.navigate!","text":"Interface\n\nnavigate!(::Connection, ::String) -> _\n\n\n\nRoutes a connected stream to a given URL.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.new_app","page":"Overview","title":"Toolips.new_app","text":"new_app(::String) -> _\n\n\n\nCreates a minimalistic app, usually used for creating endpoints – but can be used for anything. For an app with a real front-end, it might make sense to add some extensions.\n\nexample\n\n\n\n\n\n","category":"function"},{"location":"overview/#Toolips.new_webapp","page":"Overview","title":"Toolips.new_webapp","text":"new_webapp(::String) -> _\n\n\n\nCreates a fully-featured web-app. Adds CanonicalToolips.jl to provide more high-level interface origrannubg from Julia.\n\nexample\n\n\n\n\n\n","category":"function"},{"location":"overview/#Toolips.post-Tuple{String}","page":"Overview","title":"Toolips.post","text":"Interface\n\npost() ->\n\n\n\nQuick binding for an HTTP POST request.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.postarg-Tuple{Connection, String}","page":"Overview","title":"Toolips.postarg","text":"Interface\n\npostarg(::Connection, ::String) -> ::Any\n\n\n\nGet a body argument of a POST response by name.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.postargs-Tuple{Connection}","page":"Overview","title":"Toolips.postargs","text":"Interface\n\npostargs(::Connection, ::Symbol, ::Type) -> ::Dict\n\n\n\nGet arguments from the request body.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.properties!-Tuple{Toolips.Servable, Toolips.Servable}","page":"Overview","title":"Toolips.properties!","text":"Interface\n\nproperties!(::Servable, ::Servable) -> _\n\n\n\nCopies properties from s,properties into c.properties.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.route!-Tuple{Connection, Route}","page":"Overview","title":"Toolips.route!","text":"Interface\n\nroute!(::Connection, ::Route) -> _\n\n\n\nModifies the routes on the Connection.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.route!-Tuple{Function, Connection, String}","page":"Overview","title":"Toolips.route!","text":"Interface\n\nroute!(::Function, ::Connection, ::String) -> _\n\n\n\nRoutes a given String to the Function.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.route!-Tuple{Function, WebServer, String}","page":"Overview","title":"Toolips.route!","text":"\n\n\n\n","category":"method"},{"location":"overview/#Toolips.route!-Tuple{WebServer, String, Function}","page":"Overview","title":"Toolips.route!","text":"\n\n\n\n","category":"method"},{"location":"overview/#Toolips.route-Tuple{Function, String}","page":"Overview","title":"Toolips.route","text":"Interface\n\nroute(::Function, ::String) -> ::Route\n\n\n\nCreates a route from the Function.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.route-Tuple{String, Function}","page":"Overview","title":"Toolips.route","text":"\n\n\n\n","category":"method"},{"location":"overview/#Toolips.route-Tuple{String, Toolips.Servable}","page":"Overview","title":"Toolips.route","text":"Interface\n\nroute(::String, ::Servable) -> ::Route\n\n\n\nCreates a route from a Servable.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.route_from_dir-Tuple{String}","page":"Overview","title":"Toolips.route_from_dir","text":"routefromdir(dir::String) -> ::Vector{String}\n\n\n\nRecursively appends filenames for a directory AND all subsequent directories.\n\nexample\n\nx::Vector{String} = routefromdir(\"mypath\")\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.routes-Tuple{Vararg{Route}}","page":"Overview","title":"Toolips.routes","text":"Interface\n\nroutes(::Route ...) -> ::Vector{Route}\n\n\n\nTurns routes provided as arguments into a Vector{Route} with indexable routes. This is useful because this is the type that the ServerTemplate constructor likes.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.serverfuncdefs-Tuple{AbstractVector, String, Integer, Dict}","page":"Overview","title":"Toolips.serverfuncdefs","text":"Core\n\nserverfuncdefs(::AbstractVector, ::String, ::Integer,\n\n::Dict) -> (::Function, ::Function, ::Function)\n\nThis method is used internally by a constructor to generate the functions add, start, and remove for the ServerTemplate.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.startread!-Tuple{Connection}","page":"Overview","title":"Toolips.startread!","text":"Interface\n\nstartread!(::Connection) -> _\n\n\n\nResets the seek on the Connection.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.stop!-Tuple{WebServer}","page":"Overview","title":"Toolips.stop!","text":"Interface\n\nstop!(x::Any) -> _\n\n\n\nAn alternate binding for close(x). Stops a server from running.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.style!-Tuple{Style, Style}","page":"Overview","title":"Toolips.style!","text":"Interface\n\nstyle!(::Style, ::Style) -> _\n\n\n\nCopies the properties from the second style into the first style.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.style!-Tuple{Toolips.Servable, Style}","page":"Overview","title":"Toolips.style!","text":"Interface\n\nstyle!(::Servable, ::Style) -> _\n\n\n\nApplies the style to a servable.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.style!-Tuple{Toolips.Servable, Vararg{Pair}}","page":"Overview","title":"Toolips.style!","text":"\n\n\n\n","category":"method"},{"location":"overview/#Toolips.unroute!-Tuple{Connection, String}","page":"Overview","title":"Toolips.unroute!","text":"Interface\n\nunroute!(::Connection, ::String) -> _\n\n\n\nRemoves the route with the key equivalent to the String.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.write!-Tuple{Connection, Any}","page":"Overview","title":"Toolips.write!","text":"Interface\n\nwrite!(::Connection, ::Any) -> _\n\n\n\nAttempts to write any type to the Connection's stream.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.write!-Tuple{Connection, String}","page":"Overview","title":"Toolips.write!","text":"Interface\n\nwrite!(::Connection, ::String) -> _\n\n\n\nWrites the String into the Connection as HTML.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.write!-Tuple{Connection, Toolips.Servable}","page":"Overview","title":"Toolips.write!","text":"Interface\n\nwrite!(::Connection, ::Servable) -> _\n\n\n\nWrites a Servable's return to a Connection's stream.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.write!-Tuple{Connection, Vararg{Toolips.Servable}}","page":"Overview","title":"Toolips.write!","text":"\n\n\n\n","category":"method"},{"location":"overview/#Toolips.write!-Tuple{Connection, Vector{Toolips.Servable}}","page":"Overview","title":"Toolips.write!","text":"Interface\n\nwrite!(c::Connection, s::Vector{Servable}) -> _\n\n\n\nWrites, in order of element, each Servable inside of a Vector of Servables.\n\nexample\n\n\n\n\n\n","category":"method"},{"location":"overview/#Toolips.@L_str-Tuple{String}","page":"Overview","title":"Toolips.@L_str","text":"Interface\n\nL_str -> _\n\n\n\nCreates a literal string\n\nexample\n\n\n\n\n\n","category":"macro"}]
}
