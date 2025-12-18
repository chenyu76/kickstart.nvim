return {
  'hedyhli/outline.nvim',
  lazy = true,
  cmd = { 'Outline', 'OutlineOpen' },
  keys = { -- Example mapping to toggle outline
    { '<leader>o', '<cmd>Outline<CR>', desc = '[O]utline toggle' },
  },
  opts = {
    -- Your setup opts here
    -- Percentage or integer of columns
    width = 18,
  },
}
