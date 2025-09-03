local aug = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

au('TextYankPost', { group = aug('YankHighlight', {}), callback = function() vim.highlight.on_yank() end })

au('BufReadPost', {
  group = aug('LastPos', {}),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})
