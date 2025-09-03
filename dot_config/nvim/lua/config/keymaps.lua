local map = vim.keymap.set

map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Write buffer' })
map('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit window' })
-- Oil keymap is defined in the plugin spec (lazy.lua) so it lazy-loads correctly.

map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Prev diagnostic' })
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
map('n', '<leader>ld', vim.diagnostic.open_float, { desc = 'Line diagnostics' })

local function lsp_maps(buf)
  local b = { buffer = buf, silent = true, noremap = true }
  map('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', b, { desc = 'Goto definition' }))
  map('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', b, { desc = 'References' }))
  map('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', b, { desc = 'Hover' }))
  map('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', b, { desc = 'Rename' }))
  map('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', b, { desc = 'Code action' }))
  map('n', '<leader>f', function() require('conform').format() end, vim.tbl_extend('force', b, { desc = 'Format buffer' }))
end

vim.g._llm_lsp_set_keymaps = lsp_maps
