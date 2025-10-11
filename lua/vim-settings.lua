vim.o.autoread = true

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
--
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- 调整窗口大小的快捷键（Alt + hjkl）
-- vim.api.nvim_set_keymap('n', '<A-h>', '<Cmd>vertical resize -2<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<A-j>', '<Cmd>resize -2<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<A-k>', '<Cmd>resize +2<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<A-l>', '<Cmd>vertical resize +2<CR>', { noremap = true, silent = true })

vim.cmd [[
" 使用fish作为终端
set shell=/usr/bin/fish

" 打开文件时自动切换到文件所在目录
autocmd BufEnter * silent! lcd %:p:h

" 使用 VSCode 打开当前文件 的命令
command! OpenInVSCode :silent !code %:p

" 使用 VSCode 打开当前文件所在目录 的命令
command! OpenFolderInVSCode :silent !code %:p:h


" 使用图形对话框打开文件或文件夹
function! OpenFileWithDialog()
    " 调用 zenity 文件选择器
    let l:cmd = 'zenity --file-selection --title="Select a file"'
    let l:filename = system(l:cmd)

    " 移除末尾的换行符
    let l:filename = substitute(l:filename, '\n$', '', '')
    
    " 取最后一行
    let l:filename = split(l:filename, "\n")[-1]

    " 检查文件名是否非空
    if len(l:filename) > 0
        " 打开选择的文件
        exe 'edit ' . fnameescape(l:filename)
    endif
endfunction

" 将函数映射到 NeoVim 命令
command! Open call OpenFileWithDialog()

" 自动换行
"set wrap
"set linebreak!
" 按字母换行
" set linebreak  " 只在特定字符处换行
" set breakat=   " 清空 breakat 选项，这样就不会在特定字符处换行

" 设置一个 `<tab>` 宽度为4个空格
" set tabstop=4
" set softtabstop=4

" 设置手动使用 `>>` 或 `<<` 时缩进4个空格
" set shiftwidth=4

" 设置自动切换目录
" set autochdir


" 使用可视行而不是物理行的j k 移动
" nnoremap <expr> j v:count ? 'j' : 'gj'
" nnoremap <expr> k v:count ? 'k' : 'gk'
]]

vim.opt.tabstop = 4 -- 设置 Tab 显示为 4 个空格宽
vim.opt.shiftwidth = 4 -- 设置自动缩进为 4 个空格
-- vim.opt.expandtab = true -- 将 Tab 转换为空格（可选）

-- vim.opt.relativenumber = false -- 关闭相对行号
-- vim.opt.cursorcolumn = false -- 关闭光标高亮列

vim.diagnostic.config {
  -- Use the default configuration
  -- virtual_lines = true

  -- Alternatively, customize specific options
  virtual_lines = {
    -- Only show virtual line diagnostics for the current cursor line
    current_line = true,
  },
}
