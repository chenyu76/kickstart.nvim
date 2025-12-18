return {
  'goolord/alpha-nvim',
  config = function()
    require('alpha').setup(require('alpha.themes.dashboard').config)

    local dashboard = require 'alpha.themes.dashboard'
    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button('.', '󰋚 .oldfiles', '<cmd>Telescope oldfiles<CR>'),
      dashboard.button('c', ' Create a new file', ':ene <BAR> startinsert <CR>'),
      -- dashboard.button('.', '󰋚 Oldfiles', ':Telescope oldfiles theme=dropdown layout_config={width=0.8}<CR>'),
      dashboard.button('e', '󱇧 Edit some file', ':e'),
      -- dashboard.button('p', '󱉟 Projects', ':Telescope projects theme=dropdown layout_config={width=0.8}<CR>'),
      dashboard.button('o', '󰩍 Open a file', ':Open<CR>'), -- 定义在vim-setting.lua中的Open函数
      dashboard.button('n', '󰙅 Neotree', '<cmd>Neotree filesystem<CR>'),
      -- dashboard.button('s', ' Settings', ':e $MYVIMRC | :cd %:p:h | split . | wincmd k | pwd<CR>'),
      -- dashboard.button('s', ' Settings', ':e $MYVIMRC | :cd %:p:h | pwd<CR>'),
      dashboard.button('t', ' terminal Emulator', '<cmd>terminal<CR>'),
      dashboard.button('q', ' Quit', '<cmd>qa<CR>'),
    }
    for _, a in ipairs(dashboard.section.buttons.val) do
      -- a.opts.width = 36
      a.opts.cursor = -2
    end
    dashboard.section.header.val = {
      -- [[NEOVIM                                            ]],
      [[                                         __            ]],
      [[      1`T`**** ~~~-.._        __,.-~~^*"```/`)         ]],
      [[       , ^            `<. _,-*`           1  ]         ]],
      [[       )  ,             _____             I  j         ]],
      [[        ,<,        _.~*"`    `*~._        l  '         ]],
      [[        ) ^-      r`              >.     [  1          ]],
      [[         , ^    .'                  `,   /  /-.        ]],
      [[      _.^) 1,~~/                     ^-._` J   ',      ]],
      [[   _,<`  +<`  {     _         -       \  `~/     ~.    ]],
      [[  -'         wj    ,T        / `\                  '.  ]],
      [[ 1,          F'   7`*",     J *"`'     j            -` ]],
      [[  `-         | ,  L..WQ>.   J%9~~~}  , [~.        r`   ]],
      [[    `-       M|^, g*   )  *~Q[^   / 7%u'  ',    r      ]],
      [[      `,   ,"J**%MP<..-'      --~C___]{    `-_r`       ]],
      [[        \,r  4   ^,              7   j)      `         ]],
      [[            , ,   ) .     ^    _X'   -.j               ]],
      [[            *'^,  j  `*~-...-~*` )  /          HAKUREI ]],
      [[ NEOVIM         ~.j              L-"             REIMU ]],
    }
    -- local img_header = require 'alpha-img'
    -- dashboard.section.header.type = 'text'
    -- dashboard.section.header.val = img_header.val
    -- dashboard.section.header.opts = {
    --   position = 'center',
    --   hl = img_header.opts.hl,
    -- }
  end,
}
