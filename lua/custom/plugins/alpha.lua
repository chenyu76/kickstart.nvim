return {
  'goolord/alpha-nvim',
  config = function()
    require('alpha').setup(require('alpha.themes.dashboard').config)

    local dashboard = require 'alpha.themes.dashboard'
    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button('n', ' New', ':ene <BAR> startinsert <CR>'),
      -- dashboard.button('.', '󰋚 Oldfiles', ':Telescope oldfiles theme=dropdown layout_config={width=0.8}<CR>'),
      dashboard.button('.', '󰋚 Oldfiles', '<cmd>Telescope oldfiles<CR>'),
      -- dashboard.button('t', ' Terminal', ':terminal<CR>'),
      -- dashboard.button('p', '󱉟 Projects', ':Telescope projects theme=dropdown layout_config={width=0.8}<CR>'),
      -- dashboard.button('o', '󰩍 Open', ':Open<CR>'), -- 定义在misc.lua中的Open函数
      -- dashboard.button('s', ' Settings', ':e $MYVIMRC | :cd %:p:h | split . | wincmd k | pwd<CR>'),
      dashboard.button('q', ' Quit', ':qa<CR>'),
    }
    for _, a in ipairs(dashboard.section.buttons.val) do
      -- a.opts.width = 36
      a.opts.cursor = -2
    end
    dashboard.section.header.val = {
      [[                              _uw-u_                        ]],
      [[                             r` >^W@gj                      ]],
      [[                         _,,D[ {,ua@@$                      ]],
      [[                     _w<"`    '      `"wL_                  ]],
      [[                  _>^`  __,  /,  ~x_      NL                ]],
      [[                g4'   ,<"   J 1     N(      %q              ]],
      [[              g4'   ,r   _7  L X,     X,  x   %L            ]],
      [[             Z'    Z'  _>V'   V,AL     A(   v   X,          ]],
      [[           _/   , .   y* ]    @$<L%v_   G\   $,  &(         ]],
      [[          y"   7    _r  U[     jk  "(`   D\   1,  A(        ]],
      [[         y'   7    V"   HNt    ]%L  Aj   A,    $   A(       ]],
      [[        y'   V'  'V'*~-,_B1    1 _js@$, , ]    %]   &j      ]],
      [[       V' `  )  JV'      YjUk  H[` Ox3X,) 4   ] &,   1      ]],
      [[      Uf )   ]  $j  _gg_  * **>'^  __^l wjd'  1  ]  \ k     ]],
      [[      y }'   ]d [@WP^@@@$         W@@@@g,Ag'  1  1    Aj    ]],
      [[     V'g'   @&,U@g' @@@]g         @@$__ @]Tj  f   j  [ $    ]],
      [[     7mT )   @$A[1 W$"WFY'        FWRWBl $ ' J    [  &,&j   ]],
      [[    U])] )   @@Mg    <--^          -..^, `J wj    ]  %)Q]   ]],
      [[    HHM[ )   WNj3`                        HfJ    @]_;)q%]   ]],
      [[     M!1 1    @LA,        -_  _ x         dg*   1@W$l]RM]   ]],
      [[      OWjAj    @@g,                       V'   //@@gV'UNf   ]],
      [[        ?Ox     @@@gg_               __@M#'   @l@E"MO/WJ    ]],
      [[         7@gg_    @@@@@@@gg      @@@@@@P"    @$'@@X"`_v     ]],
      [[         "HWWP<,_  X"W@MP"%k, ,.WW@@@Bf    _WF'@@W]         ]],
      [[          `  ,  Sj  $  8 _#"^ N(   @$'  ____@@@@@Mt         ]],
      [[           \   'Hl  g  PH%Dy ,_@k_XVl  UPW@@@@B[@@@g_J      ]],
      [[           )'  YPq _F J   >*`"`   ]4)  T    W@@@gJT"`       ]],
      [[             '  )**"` 1 ,g<"?k,  V' &(_H><    &,"`          ]],
      [[                                                            ]],
      [[                       N E O V I M                          ]],
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
