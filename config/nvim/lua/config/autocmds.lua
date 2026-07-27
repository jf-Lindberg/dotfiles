local augroup = function(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Briefly highlight text after yanking, so you can see what was captured.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Strip trailing whitespace on save, except where it is meaningful.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("trim_whitespace"),
  callback = function(event)
    if vim.bo[event.buf].filetype == "markdown" then
      return -- two trailing spaces are a hard line break in markdown
    end
    if not vim.bo[event.buf].modifiable then
      return -- e.g. checkhealth or help buffers written out with :w
    end
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Language-specific indentation. Go uses real tabs; Python and Java use four spaces.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_go"),
  pattern = "go",
  callback = function()
    vim.bo.expandtab = false
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_four"),
  pattern = { "python", "java" },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
  end,
})

-- Prose settings for markdown: wrap visually and spell-check.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("prose"),
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.wo.wrap = true
    vim.wo.spell = true
    vim.bo.textwidth = 0
  end,
})

-- Close throwaway windows with plain `q`.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "notify" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

-- Reopen a file at the position you left it.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_location"),
  callback = function(event)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[event.buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Create missing parent directories when writing a new file.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_mkdir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return -- skip URLs and other non-file paths
    end
    vim.fn.mkdir(vim.fn.fnamemodify(vim.uv.fs_realpath(event.match) or event.match, ":p:h"), "p")
  end,
})
