return {
  'goolord/alpha-nvim',
  config = function()
    require('alpha').setup(require('alpha.themes.dashboard').config)

    local dashboard = require 'alpha.themes.dashboard'
    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button('n', ' New', ':ene <BAR> startinsert <CR>'),
      dashboard.button('.', '󰋚 Oldfiles', ':Telescope oldfiles theme=dropdown layout_config={width=0.8}<CR>'),
      dashboard.button('t', ' Terminal', ':terminal<CR>'),
      -- dashboard.button('p', '󱉟 Projects', ':Telescope projects theme=dropdown layout_config={width=0.8}<CR>'),
      -- dashboard.button('o', '󰩍 Open', ':Open<CR>'), -- 定义在misc.lua中的Open函数
      -- dashboard.button('s', ' Settings', ':e $MYVIMRC | :cd %:p:h | split . | wincmd k | pwd<CR>'),
      dashboard.button('q', ' Quit', ':qa<CR>'),
    }
    for _, a in ipairs(dashboard.section.buttons.val) do
      -- a.opts.width = 36
      a.opts.cursor = -2
    end
    --dashboard.section.header = require("cy.alphaimg")
    local img_header = require 'alpha-img'
    dashboard.section.header.type = 'text'
    dashboard.section.header.val = img_header.val
    dashboard.section.header.opts = {
      position = 'center',
      hl = img_header.opts.hl,
    }
  end,
}
