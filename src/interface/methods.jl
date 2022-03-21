import Base: +

function getargs(http::Any)
    split(http.message.target, '?')[2]
end

+(f::Function, f::Function) = Page([f, f])
+(p::Page, f::Function) = p.add(f)
