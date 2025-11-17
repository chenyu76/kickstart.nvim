local tokyonight = { -- You can easily change to a different colorscheme.
  -- Change the name of the colorscheme plugin below, and then
  -- change the command in the config to whatever the name of that colorscheme is.
  --
  -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
  'folke/tokyonight.nvim',
  name = 'tokyonight',
  priority = 1000, -- Make sure to load this before all the other start plugins.
  config = function()
    require('tokyonight').setup {
      styles = {
        -- comments = { italic = false }, -- Disable italics in comments
      },
    }

    -- Load the colorscheme here.
    -- Like many other themes, this one has different styles, and you could load
    -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
    -- vim.cmd.colorscheme 'tokyonight-night'
    -- vim.cmd.colorscheme 'tokyonight-storm'
    vim.cmd.colorscheme 'tokyonight-moon'
  end,
}

local catppuccin = {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('catppuccin').setup {
      term_colors = true,
      --transparent_background = true,
    }
    vim.cmd.colorscheme 'catppuccin'
  end,
}

-- Change the index to switch colorschemes.
return ({ tokyonight, catppuccin })[1]
