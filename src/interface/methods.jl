import Base: +

function getargs(http::Any)
    split(http.message.target, '?')[2]
end

+(f::Function, f2::Function) = Page([f, f2])
+(p::Page, f::Function) = p.add(f)
