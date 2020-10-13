using sbl
using Documenter

makedocs(;
    modules=[sbl],
    authors="Andreas Hildebrandt <andreas.hildebrandt@uni-mainz.de> and contributors",
    repo="https://github.com/hildebrandtlab/sbl.jl/blob/{commit}{path}#L{line}",
    sitename="sbl.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://hildebrandtlab.github.io/sbl.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/hildebrandtlab/sbl.jl",
)
