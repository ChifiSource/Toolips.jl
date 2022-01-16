using Base: run
npm_dir_lin = `/usr/bin/npm`
npm_dir_win = ``
function NPMInstall(name::String)
    com = string(npm_cmd(), " install ", name)
    Run(Cmd(com))
end

function NPMStart()
    com = [string(npm_dir_lin), `install copy-node-modules --save-dev`]
    run(Cmd(com))
end
