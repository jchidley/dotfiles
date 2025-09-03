local lspconfig = require('lspconfig')
local mason_lsp = require('mason-lspconfig')
-- Disable mason-lspconfig's automatic enable feature (requires newer Neovim APIs)
pcall(function()
  require('mason-lspconfig.settings').set({ automatic_enable = false, automatic_installation = false })
end)
local cmp = require('cmp')
local cmp_lsp = require('cmp_nvim_lsp')

cmp.setup({
  snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-e>'] = cmp.mapping.abort(),
  }),
  sources = { { name = 'nvim_lsp' } },
})

local capabilities = cmp_lsp.default_capabilities(vim.lsp.protocol.make_client_capabilities())

require('mason').setup()
mason_lsp.setup({ ensure_installed = { 'rust_analyzer','lua_ls','bashls','jsonls','yamlls','taplo','marksman' } })

local on_attach = function(client, bufnr)
  if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
    local ih = vim.lsp.inlay_hint
    if type(ih) == 'table' and ih.enable then
      ih.enable(true, { bufnr = bufnr })
    elseif type(ih) == 'function' then
      ih(bufnr, true)
    end
  end
  local set_maps = vim.g._llm_lsp_set_keymaps
  if type(set_maps) == 'function' then set_maps(bufnr) end
end

local servers = {
  rust_analyzer = {},
  lua_ls = { settings = { Lua = { diagnostics = { globals = { 'vim' } }, workspace = { checkThirdParty = false } } } },
  bashls = {},
  jsonls = {},
  yamlls = {},
  taplo = {},
  marksman = {},
}

for name, cfg in pairs(servers) do
  cfg.capabilities = capabilities
  cfg.on_attach = on_attach
  lspconfig[name].setup(cfg)
end

require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = { 'lua', 'rust', 'bash', 'json', 'yaml', 'toml', 'markdown', 'markdown_inline' },
})
