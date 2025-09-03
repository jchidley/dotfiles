require('lazy').setup({
  { 'ellisonleao/gruvbox.nvim', priority = 1000, config = function() require('config.colors') end },
  { 'neovim/nvim-lspconfig' },
  { 'williamboman/mason.nvim', config = true },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'L3MON4D3/LuaSnip' },
  { 'stevearc/conform.nvim', config = function() require('config.format') end },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
  { 'stevearc/oil.nvim',
    opts = {},
    cmd = 'Oil',
    keys = {
      { '<leader>e', function() require('oil').open() end, desc = 'Open file manager (Oil)' },
    },
  },
  { 'folke/which-key.nvim', event = 'VeryLazy', opts = { delay = 300 } },
}, { change_detection = { notify = false } })

require('config.lsp')
