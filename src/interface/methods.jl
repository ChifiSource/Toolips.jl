import Base: +

function getargs(http::Any)
    split(http.message.target, '?')[2]
end

function write_file(URI::String, http::HTTP.Stream)
    open(URI, "r") do i
        write(http, i)
    end
end
+(f::Function, f2::Function) = Page([f, f2])
+(p::Page, f::Function) = p.add(f)
+(fc::FormComponent, fc2::FormComponent) = Form(fc, fc2)
