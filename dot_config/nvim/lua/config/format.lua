local conform = require('conform')
conform.setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    rust = { 'rustfmt' },
    bash = { 'shfmt' },
    json = { 'prettier' },
    yaml = { 'yamlfmt' },
    markdown = { 'mdformat', 'prettier' },
    toml = { 'taplo' },
  },
  format_on_save = function()
    return { timeout_ms = 1000, lsp_fallback = true }
  end,
})
