-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Julia LSP (LanguageServer.jl)
require("lspconfig").julials.setup({
    on_new_config = function(new_config, _)
        local julia = vim.fn.expand("~/.julia/environments/nvim-lspconfig/bin/julia")
        if require("lspconfig").util.path.is_file(julia) then
            new_config.cmd[1] = julia
        end
    end,

    -- This just adds dirname(fname) as a fallback (see nvim-lspconfig#1768).
    root_dir = function(fname)
        local util = require("lspconfig.util")
        return util.root_pattern("Project.toml")(fname) or util.find_git_ancestor(fname) or util.path.dirname(fname)
    end,
})
