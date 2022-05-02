function set!(s::Servable, property::Pair)

end

end

function anim!(s::Servable, anim::Animation)

end

function set!()

end
function no_anim!(s::Servable)

end

function push!(http::HTTP.Stream, session_data::OddFrame)

end

function add_route!(path::String, route::Route, )

end

function open(f::Function, session_data::OddFrame, servable_id::Integer)

end

function route(f::Function, route::String, s::Page)
    s.f = f
    Route(route, s)::Route
end
