-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
opt.wrap = true
-- enable soft wrapping at the edge of the screen
opt.linebreak = true
-- make it not wrap in the middle of a "word"
opt.colorcolumn = "80"
-- highlight when you go over a desired width
opt.tabstop = 4
opt.shiftwidth = 4
-- tabs set to 4
opt.expandtab = true
-- convert tabs to spaces
vim.g.netrw_winsize = 25
-- usable netrw window size
