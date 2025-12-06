-- 从 ayamir/nvimdots 抄来的
-- 键位设置在 /lua/custom/which-key.lua
local _lazygit = nil
function Toggle_lazygit()
  if vim.fn.executable 'lazygit' == 1 then
    if not _lazygit then
      _lazygit = require('toggleterm.terminal').Terminal:new {
        cmd = 'lazygit',
        direction = 'float',
        close_on_exit = true,
        hidden = true,
      }
    end
    _lazygit:toggle()
  else
    vim.notify('Command [lazygit] not found!', vim.log.levels.ERROR, { title = 'toggleterm.nvim' })
  end
end

function ViewCorrespondingPDF()
  local file = string.gsub(vim.fn.expand '%:p', '.tex$', '.pdf')
  vim.notify('Open PDF: ' .. file, vim.log.levels.INFO, { title = 'PDF view' })
  local cmd = {}
  if vim.g.current_device == 1 then
    cmd = { 'evince', file }
  else
    cmd = { 'okular', file }
  end

  -- 使用 vim.loop.spawn 异步执行
  local handle = vim.loop.spawn(cmd[1], {
    args = vim.list_slice(cmd, 2),
    detached = true, -- 让子进程独立于 Neovim 进程
    stdio = { nil, nil, nil }, -- 忽略标准输入、输出和错误
  }, function(exit_code)
    -- 这个回调函数在命令结束后被调用，这里可以做一些清理工作
    if exit_code ~= 0 then
      vim.notify('Failed to open PDF, exit code: ' .. exit_code, vim.log.levels.ERROR)
    end
  end)
end
