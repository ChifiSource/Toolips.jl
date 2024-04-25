using Pkg; Pkg.activate(".")
using Revise
using Toolips
using TestApp
toolips_process = start!(TestApp, "192.168.1.15":8000, threads = 2)
