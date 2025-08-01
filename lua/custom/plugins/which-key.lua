return { -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',
  event = 'VimEnter', -- Sets the loading event to 'VimEnter'
  opts = {
    -- delay between pressing a key and opening which-key (milliseconds)
    -- this setting is independent of vim.o.timeoutlen
    delay = 0,
    icons = {
      -- set icon mappings to true if you have a Nerd Font
      mappings = vim.g.have_nerd_font,
      -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
      -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
      keys = vim.g.have_nerd_font and {} or {
        Up = '<Up> ',
        Down = '<Down> ',
        Left = '<Left> ',
        Right = '<Right> ',
        C = '<C-…> ',
        M = '<M-…> ',
        D = '<D-…> ',
        S = '<S-…> ',
        CR = '<CR> ',
        Esc = '<Esc> ',
        ScrollWheelDown = '<ScrollWheelDown> ',
        ScrollWheelUp = '<ScrollWheelUp> ',
        NL = '<NL> ',
        BS = '<BS> ',
        Space = '<Space> ',
        Tab = '<Tab> ',
        F1 = '<F1>',
        F2 = '<F2>',
        F3 = '<F3>',
        F4 = '<F4>',
        F5 = '<F5>',
        F6 = '<F6>',
        F7 = '<F7>',
        F8 = '<F8>',
        F9 = '<F9>',
        F10 = '<F10>',
        F11 = '<F11>',
        F12 = '<F12>',
      },
    },

    -- Document existing key chains
    -- Key mapping
    spec = {
      { '<leader>s', group = '[S]earch' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>r', '<cmd>lua Compile_current_file()<CR>', desc = '[R]un code by file', mode = 'n', icon = '' },
      { '<leader>tc', '<cmd>lua require("copilot.suggestion").toggle_auto_trigger()<CR>', desc = '[T]oggle [C]opilt', mode = 'n', icon = '' },
      { '<leader>tg', '<cmd>lua Toggle_lazygit()<CR>', desc = '[T]oggle Lazygit', mode = 'n', icon = '' },
      { '<leader>w', ':HopWord<CR>', desc = 'Jump by [W]ord', mode = { 'n', 'v' }, icon = '󰈭' },
      { '<leader>c', ':HopChar1<CR>', desc = 'Jump by [C]har', mode = { 'n', 'v' }, icon = '󰀬' },
      { '<leader>n', '<cmd>Neotree reveal toggle dir=./<CR>', desc = '[N]eotree', mode = 'n', icon = '' },
      { '<leader>e', '<cmd>ToggleTerm<CR>', desc = 'Terminal [e]mulator', mode = 'n', icon = '' },
      { '<C-n>', '<cmd>Neotree reveal toggle dir=./<CR>', desc = '[N]eotree', mode = { 'n', 'i' }, icon = '' },
      { '<C-\\>', '<cmd>ToggleTerm<CR>', desc = 'Terminal', mode = { 'n', 'i', 't' }, icon = '' },
      { '<F4>', '<cmd>ToggleTerm<CR>', desc = 'Terminal', mode = { 'n', 'i', 't' }, icon = '' },
    },
  },
}
