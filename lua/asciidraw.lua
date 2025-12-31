local M = {}

-- Internal State
local state = {
  active = false,
  mode = nil,
  style_idx = 1,
  box_start = nil, -- {row, virt_col}
  last_dir = nil,
  original_ve = '',

  -- UI Handles
  canvas_win = nil,
  sidebar_buf = nil,
  sidebar_win = nil,
  ns_id = nil, -- Extmark Namespace
  show_help = false,

  mapped_keys = {},
  clipboard = nil,
}

-- Direction Bits:
-- U: Up, R: Right, D: Down, L: Left
local BIT = { U = 1, R = 2, D = 4, L = 8 }
local DIR_KEY_TO_BIT = { h = BIT.L, j = BIT.D, k = BIT.U, l = BIT.R }
local OPPOSITE_BIT = { [BIT.U] = BIT.D, [BIT.D] = BIT.U, [BIT.L] = BIT.R, [BIT.R] = BIT.L }

-- Styles Definition
local RAW_STYLES = {
  [1] = {
    [[┌┬┐▲]],
    [[├┼┤│]],
    [[└┴┘▼]],
    [[◄─► ]],
  },
  [2] = {
    [[╔╦╗▲]],
    [[╠╬╣║]],
    [[╚╩╝▼]],
    [[◄═► ]],
  },
  [3] = {
    [[+++^]],
    [[+++|]],
    [[+++v]],
    [[<-> ]],
  },
}

local STYLES = {}
local CHAR_TO_MASK = {}

-- Initialize styles and character to mask mapping
local function parse_style_grid(grid)
  local lines, arrows = {}, {}
  local function get(r, c)
    return vim.fn.strcharpart(grid[r], c, 1)
  end

  lines[BIT.D + BIT.R] = get(1, 0)
  lines[BIT.D + BIT.R + BIT.L] = get(1, 1)
  lines[BIT.D + BIT.L] = get(1, 2)
  arrows[BIT.U] = get(1, 3)

  lines[BIT.U + BIT.D + BIT.R] = get(2, 0)
  lines[15] = get(2, 1)
  lines[BIT.U + BIT.D + BIT.L] = get(2, 2)
  local v = get(2, 3)
  lines[BIT.U], lines[BIT.D], lines[BIT.U + BIT.D] = v, v, v

  lines[BIT.U + BIT.R] = get(3, 0)
  lines[BIT.U + BIT.R + BIT.L] = get(3, 1)
  lines[BIT.U + BIT.L] = get(3, 2)
  arrows[BIT.D] = get(3, 3)

  arrows[BIT.L] = get(4, 0)
  arrows[BIT.R] = get(4, 2)
  lines[0] = get(4, 3)
  local h = get(4, 1)
  lines[BIT.L], lines[BIT.R], lines[BIT.L + BIT.R] = h, h, h

  return { lines = lines, arrows = arrows }
end

local function init_styles()
  CHAR_TO_MASK = {}
  for i, grid in ipairs(RAW_STYLES) do
    local parsed = parse_style_grid(grid)
    STYLES[i] = parsed
    for mask, char in pairs(parsed.lines) do
      if char ~= ' ' then
        CHAR_TO_MASK[char] = mask
      end
    end
    local a = parsed.arrows
    if a[BIT.U] and a[BIT.U] ~= ' ' then
      CHAR_TO_MASK[a[BIT.U]] = BIT.D
    end
    if a[BIT.D] and a[BIT.D] ~= ' ' then
      CHAR_TO_MASK[a[BIT.D]] = BIT.U
    end
    if a[BIT.L] and a[BIT.L] ~= ' ' then
      CHAR_TO_MASK[a[BIT.L]] = BIT.R
    end
    if a[BIT.R] and a[BIT.R] ~= ' ' then
      CHAR_TO_MASK[a[BIT.R]] = BIT.L
    end
  end
  CHAR_TO_MASK[' '] = 0
  CHAR_TO_MASK['+'] = 15
end

local function get_virt_col()
  return vim.fn.virtcol '.' - 1
end

local function goto_virt_pos(row, virt_col)
  local line_count = vim.api.nvim_buf_line_count(0)
  if row > line_count then
    return
  end
  local curr_r = vim.fn.line '.'
  local curr_c = get_virt_col()
  if curr_r == row and curr_c == virt_col then
    return
  end

  vim.api.nvim_win_set_cursor(0, { row, 0 })
  if virt_col > 0 then
    vim.cmd('normal! ' .. (virt_col + 1) .. '|')
  end
end

local function get_byte_range_from_virt_col(row, target_virt_col)
  local lines = vim.api.nvim_buf_get_lines(0, row - 1, row, false)
  local line = lines[1] or ''
  local current_virt = 0
  local found_start, found_end = nil, nil
  local len_chars = vim.fn.strchars(line)

  for i = 0, len_chars - 1 do
    local char = vim.fn.strcharpart(line, i, 1)
    local w = vim.fn.strwidth(char)
    if current_virt == target_virt_col then
      found_start = vim.fn.byteidx(line, i)
      found_end = vim.fn.byteidx(line, i + 1)
      break
    elseif current_virt > target_virt_col then
      found_start = vim.fn.byteidx(line, i - 1)
      found_end = vim.fn.byteidx(line, i)
      break
    end
    current_virt = current_virt + w
  end

  if not found_start then
    local pad_len = target_virt_col - vim.fn.strwidth(line)
    if pad_len < 0 then
      pad_len = 0
    end
    local padding = string.rep(' ', pad_len + 1)
    line = line .. padding
    local original_bytes = #lines[1] or 0
    found_start = original_bytes + pad_len
    found_end = found_start + 1
  end
  return found_start, found_end, line
end

local function set_char_at(row, virt_col, char)
  local cur_r = vim.fn.line '.'
  local cur_c = get_virt_col()

  local line_count = vim.api.nvim_buf_line_count(0)
  if row > line_count then
    local empty = {}
    for _ = 1, (row - line_count) do
      table.insert(empty, '')
    end
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, empty)
  end

  local start_b, end_b, padded_line = get_byte_range_from_virt_col(row, virt_col)
  local current_line_content = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''

  if #padded_line > #current_line_content then
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { padded_line })
  end

  vim.api.nvim_buf_set_text(0, row - 1, start_b, row - 1, end_b or 0, { char })
  goto_virt_pos(cur_r, cur_c)
end

local function get_char_at(row, virt_col)
  local start_b, end_b = get_byte_range_from_virt_col(row, virt_col)
  if start_b and end_b then
    local curr_line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
    if start_b >= #curr_line then
      return ' '
    end
    return string.sub(curr_line, start_b + 1, end_b)
  end
  return ' '
end

local function smart_merge(row, virt_col, new_mask_bits, mask_to_remove)
  local current_char = get_char_at(row, virt_col)
  local current_mask = CHAR_TO_MASK[current_char] or 0
  if mask_to_remove and mask_to_remove > 0 then
    current_mask = bit.band(current_mask, bit.bnot(mask_to_remove))
  end
  local final_mask = bit.bor(current_mask, new_mask_bits)
  local palette = STYLES[state.style_idx].lines
  local new_char = palette[final_mask] or current_char
  set_char_at(row, virt_col, new_char)
end

-- Virtual text marker for box/select start position
local function clear_start_marker()
  if state.ns_id then
    vim.api.nvim_buf_clear_namespace(0, state.ns_id, 0, -1)
  end
end

local function update_start_marker()
  clear_start_marker()

  if (state.mode == 'select' or state.mode == 'box') and state.box_start then
    local r, c = state.box_start[1], state.box_start[2]
    local line_count = vim.api.nvim_buf_line_count(0)

    if r <= line_count then
      local line = vim.api.nvim_buf_get_lines(0, r - 1, r, false)[1] or ''
      local len_chars = vim.fn.strchars(line)
      local current_virt = 0
      local col_byte = 0
      local needs_padding = false
      local found = false

      -- Calculate byte index corresponding to the virtual column
      for i = 0, len_chars - 1 do
        local char = vim.fn.strcharpart(line, i, 1)
        local w = vim.fn.strwidth(char)
        if current_virt == c then
          col_byte = vim.fn.byteidx(line, i)
          found = true
          break
        elseif current_virt > c then
          -- tab or wide char case, take the previous position
          col_byte = vim.fn.byteidx(line, i)
          found = true
          break
        end
        current_virt = current_virt + w
      end

      if not found then
        col_byte = #line
        needs_padding = true
      end

      local opts = {
        id = 1,
        priority = 200,
        virt_text_pos = 'overlay',
      }

      if needs_padding then
        -- how many spaces to pad
        local line_width = vim.fn.strwidth(line)
        local pad_len = c - line_width
        if pad_len < 0 then
          pad_len = 0
        end
        opts.virt_text = { { string.rep(' ', pad_len) .. '⊕', 'MatchParen' } }
      else
        opts.virt_text = { { '⊕', 'MatchParen' } }
      end

      vim.api.nvim_buf_set_extmark(0, state.ns_id, r - 1, col_byte, opts)
    end
  end
end

local function update_sidebar_status(msg)
  msg = msg or '(Empty)'

  if not state.sidebar_buf or not vim.api.nvim_buf_is_valid(state.sidebar_buf) then
    return
  end

  local info = 'Mode: ' .. (state.mode or 'Ready')
  if state.box_start then
    local r, c = unpack(state.box_start)
    info = info .. string.format(' (%d,%d)', r, c)
  end

  local style_lines = RAW_STYLES[state.style_idx]
  local display_lines = {
    'Current Style:',
    '  ' .. style_lines[1],
    '  ' .. style_lines[2],
    '  ' .. style_lines[3],
    '  ' .. style_lines[4],
    'Status:',
    '  ' .. info,
    'Info:',
    '  ' .. msg,
    'Clipboard:',
  }

  if state.clipboard then
    local w, h = state.clipboard.width, state.clipboard.height
    table.insert(display_lines, string.format('  Size: %dx%d', w, h))
    for i = 1, math.min(5, #state.clipboard.lines) do
      table.insert(display_lines, '  |' .. state.clipboard.lines[i])
    end
    if #state.clipboard.lines > 5 then
      table.insert(display_lines, '  ...')
    end
  else
    table.insert(display_lines, '  (Empty)')
  end

  local content = vim.api.nvim_buf_get_lines(state.sidebar_buf, 0, -1, false)
  local start_idx = 0
  for i, line in ipairs(content) do
    if line == '---- STATUS ----' then
      start_idx = i
      break
    end
  end
  if start_idx > 0 then
    vim.api.nvim_buf_set_lines(state.sidebar_buf, start_idx, -1, false, display_lines)
  end
end

local function update_sidebar_content()
  if not state.sidebar_buf or not vim.api.nvim_buf_is_valid(state.sidebar_buf) then
    return
  end

  local lines = { '- DIAGRAM MODE -' }

  if state.show_help then
    local help_items = {
      'Base Tools:',
      ' [a]   Arrow',
      ' [e]   Edge (Line)',
      ' [b]   Box (Rect)',
      ' [i]   Text Insert',
      ' [ ]   Commit',
      '',
      'Editing Tools:',
      ' [x]   Clear Char',
      ' [BS]  Backspace',
      ' [v]   Select Start',
      ' [d]   Delete',
      ' [y]   Yank',
      ' [p]   Paste',
      ' [o/O] New Line',
      '',
      'Other Controls:',
      ' [u]    Undo',
      ' [^r]   Redo',
      ' [hjkl] Move/Draw',
      ' [HJKL] Move/Draw Fast',
      ' [1-' .. #STYLES .. ']  Style',
      ' [Esc]  Exit',
    }
    for _, line in ipairs(help_items) do
      table.insert(lines, line)
    end
  else
    -- Folded
    table.insert(lines, ' [?]  Help')
  end

  table.insert(lines, '')
  table.insert(lines, '---- STATUS ----')

  -- Update buffer content
  vim.api.nvim_buf_set_lines(state.sidebar_buf, 0, -1, false, lines)

  if update_sidebar_status then
    update_sidebar_status()
  end
end

local function toggle_help()
  state.show_help = not state.show_help
  if state.sidebar_buf and vim.api.nvim_buf_is_valid(state.sidebar_buf) then
    update_sidebar_content()
  end
end

local function open_sidebar()
  state.canvas_win = vim.api.nvim_get_current_win()
  state.sidebar_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = state.sidebar_buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = state.sidebar_buf })
  vim.api.nvim_set_option_value('filetype', 'diagram_help', { buf = state.sidebar_buf })

  update_sidebar_content()

  vim.cmd 'botright vsplit'
  vim.cmd 'vertical resize 25'
  state.sidebar_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.sidebar_win, state.sidebar_buf)

  vim.api.nvim_win_call(state.sidebar_win, function()
    vim.fn.matchadd('Special', '\\[.\\{-}\\]')
    vim.fn.matchadd('Keyword', '- DIAGRAM MODE -')
    vim.fn.matchadd('Keyword', '---- STATUS ----')
    vim.fn.matchadd('Special', '^.*:$')
  end)

  vim.api.nvim_set_option_value('number', false, { win = state.sidebar_win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = state.sidebar_win })
  vim.api.nvim_set_option_value('winhl', 'Normal:Pmenu', { win = state.sidebar_win })

  if vim.api.nvim_win_is_valid(state.canvas_win) then
    vim.api.nvim_set_current_win(state.canvas_win)
  end
end

local function close_sidebar()
  if state.sidebar_win and vim.api.nvim_win_is_valid(state.sidebar_win) then
    vim.api.nvim_win_close(state.sidebar_win, true)
  end
  state.sidebar_win = nil
  state.sidebar_buf = nil
end

local function update_status(msg)
  local info = (msg or state.mode or '(Empty)')
  -- print('-- DIAGRAM [' .. state.style_idx .. ']: ' .. info .. ' --')
  update_sidebar_status(info)
end

-- Interaction Operations
local function move_cursor(direction)
  local r = vim.fn.line '.'
  local c = get_virt_col()
  local old_r, old_c = r, c

  if direction == 'h' then
    c = c - 1
  elseif direction == 'j' then
    r = r + 1
  elseif direction == 'k' then
    r = r - 1
  elseif direction == 'l' then
    c = c + 1
  end

  if r < 1 then
    r = 1
  end
  if c < 0 then
    c = 0
  end
  local line_count = vim.api.nvim_buf_line_count(0)
  if r > line_count then
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, { '' })
  end

  goto_virt_pos(r, c)
  -- Some Characters occupy 2 virtual columns, adjust back if needed
  if direction == 'h' and get_virt_col() == old_c and c > 0 then
    goto_virt_pos(r, old_c - 2)
  end
  r = vim.fn.line '.'
  c = get_virt_col()

  -- Draw edge or arrow
  if state.mode == 'edge' or state.mode == 'arrow' then
    if r ~= old_r or c ~= old_c then
      local d_mask = DIR_KEY_TO_BIT[direction]
      local rev_mask = OPPOSITE_BIT[d_mask]

      -- old position
      local mask_to_add = d_mask
      local mask_to_remove = 0
      if state.last_dir and state.last_dir ~= direction then
        local last_bit = DIR_KEY_TO_BIT[state.last_dir]
        if last_bit then
          mask_to_remove = last_bit
        end
      end
      smart_merge(old_r, old_c, mask_to_add, mask_to_remove)

      -- new position
      if state.mode == 'arrow' then
        local arrow_char = STYLES[state.style_idx].arrows[d_mask]
        if arrow_char and arrow_char ~= ' ' then
          set_char_at(r, c, arrow_char)
        end
      else
        smart_merge(r, c, rev_mask)
      end
    end
    state.last_dir = direction
  end

  if (state.mode == 'box' or state.mode == 'select') and state.box_start then
    local r1, c1 = state.box_start[1], state.box_start[2]
    local w = math.abs(c - c1) + 1
    local h = math.abs(r - r1) + 1
    local prefix = (state.mode == 'box') and 'Box' or 'Select'
    update_status(string.format('%s: %dx%d', prefix, w, h))
  end
end

local function draw_box_commit()
  if not state.box_start then
    return
  end

  local r1, c1 = state.box_start[1], state.box_start[2]
  local r2 = vim.fn.line '.'
  local c2 = get_virt_col()
  local start_r, end_r = math.min(r1, r2), math.max(r1, r2)
  local start_c, end_c = math.min(c1, c2), math.max(c1, c2)

  smart_merge(start_r, start_c, BIT.R + BIT.D)
  smart_merge(start_r, end_c, BIT.L + BIT.D)
  smart_merge(end_r, start_c, BIT.R + BIT.U)
  smart_merge(end_r, end_c, BIT.L + BIT.U)

  for c = start_c + 1, end_c - 1 do
    smart_merge(start_r, c, BIT.L + BIT.R)
    smart_merge(end_r, c, BIT.L + BIT.R)
  end
  for r = start_r + 1, end_r - 1 do
    smart_merge(r, start_c, BIT.U + BIT.D)
    smart_merge(r, end_c, BIT.U + BIT.D)
  end
  state.box_start = nil
  state.mode = nil
  clear_start_marker()
  update_status 'Box Drawn'
end

-- paste/select operations
local function get_selection_rect()
  if not state.box_start then
    return nil
  end
  local r1, c1 = state.box_start[1], state.box_start[2]
  local r2, c2 = vim.fn.line '.', get_virt_col()
  return {
    top = math.min(r1, r2),
    bottom = math.max(r1, r2),
    left = math.min(c1, c2),
    right = math.max(c1, c2),
  }
end

local function copy_selection()
  local rect = get_selection_rect()
  if not rect then
    update_status 'No selection to copy'
    return
  end

  local lines = {}
  for r = rect.top, rect.bottom do
    local line_str = ''
    for c = rect.left, rect.right do
      line_str = line_str .. get_char_at(r, c)
    end
    table.insert(lines, line_str)
  end

  state.clipboard = {
    lines = lines,
    width = rect.right - rect.left + 1,
    height = rect.bottom - rect.top + 1,
  }

  -- end selection
  state.box_start = nil
  state.mode = nil
  clear_start_marker()
  update_status 'Copied'
end

local function cut_selection()
  local rect = get_selection_rect()
  if not rect then
    update_status 'No selection to cut'
    return
  end

  copy_selection()
  -- NOTE: copy_selection clears box_start, so use rect here
  for r = rect.top, rect.bottom do
    for c = rect.left, rect.right do
      set_char_at(r, c, ' ')
    end
  end

  update_status 'Cut'
end

local function paste_clipboard()
  if not state.clipboard then
    update_status 'Clipboard empty'
    return
  end

  local r, c = vim.fn.line '.', get_virt_col()
  for i, line_content in ipairs(state.clipboard.lines) do
    local target_r = r + i - 1
    local len_chars = vim.fn.strchars(line_content)
    for j = 1, len_chars do
      local char = vim.fn.strcharpart(line_content, j - 1, 1)
      if char ~= ' ' then
        set_char_at(target_r, c + j - 1, char)
      end
    end
  end
  update_status 'Pasted'
end

local function handle_input_char(char)
  local r, c = vim.fn.line '.', get_virt_col()
  set_char_at(r, c, char)
  vim.cmd 'normal! l'
end

-- key mapping with nowait to prevent delays
local function safe_map(key, callback, opts)
  local final_opts = vim.tbl_extend('force', opts, { nowait = true })
  vim.keymap.set('n', key, callback, final_opts)
  table.insert(state.mapped_keys, key)
end

local function set_mappings()
  local opts = { noremap = true, silent = true, buffer = 0 }
  state.mapped_keys = {}
  local mapped_chars = {}

  local function map_hybrid(key, cmd_callback)
    safe_map(key, function()
      if state.mode == 'text' then
        handle_input_char(key)
      else
        cmd_callback()
      end
    end, opts)
    mapped_chars[key] = true
  end

  -- move
  for _, k in ipairs { 'h', 'j', 'k', 'l' } do
    map_hybrid(k, function()
      move_cursor(k)
    end)
  end
  for _, k in ipairs { 'H', 'J', 'K', 'L' } do
    map_hybrid(k, function()
      local k_lower = string.lower(k)
      for _ = 1, 5 do
        move_cursor(k_lower)
      end
    end)
  end

  -- toggle help
  map_hybrid('?', function()
    toggle_help()
  end)

  -- mode switch
  map_hybrid('e', function()
    state.mode = 'edge'
    state.last_dir = nil
    update_status 'Edge Mode'
  end)
  map_hybrid('a', function()
    state.mode = 'arrow'
    state.last_dir = nil
    update_status 'Arrow Mode'
  end)
  map_hybrid('i', function()
    state.mode = 'text'
    update_status 'Text Input'
  end)

  -- easer
  map_hybrid('x', function()
    local r, c = vim.fn.line '.', get_virt_col()
    set_char_at(r, c, ' ')
  end)

  -- box mode
  map_hybrid('b', function()
    if state.mode == 'box' then
      draw_box_commit()
    else
      state.mode = 'box'
      state.box_start = { vim.fn.line '.', get_virt_col() }
      update_start_marker() -- show marker immediately
      update_status 'Box Start (Move & Space)'
    end
  end)

  -- select mode
  map_hybrid('v', function()
    state.mode = 'select'
    state.box_start = { vim.fn.line '.', get_virt_col() }
    update_start_marker()
    update_status 'Select Start (Move then d/y)'
  end)

  -- clipboard operations
  map_hybrid('d', function()
    if state.mode == 'select' then
      cut_selection()
    else
      update_status "Use 'v' first"
    end
  end)
  map_hybrid('y', function()
    if state.mode == 'select' then
      copy_selection()
    else
      update_status "Use 'v' first"
    end
  end)
  map_hybrid('p', function()
    paste_clipboard()
  end)

  -- newline
  map_hybrid('o', function()
    vim.cmd "put =''"
  end)
  map_hybrid('O', function()
    vim.cmd "put! =''"
  end)

  -- undo/redo
  safe_map('u', function()
    if state.mode == 'text' then
      handle_input_char 'u'
    else
      vim.cmd 'undo'
    end
  end, opts)
  mapped_chars['u'] = true

  safe_map('<C-r>', function()
    vim.cmd 'redo'
  end, opts)

  -- style switch
  for i = 1, #STYLES do
    map_hybrid(tostring(i), function()
      state.style_idx = i
      update_status('Style ' .. i)
    end)
  end

  -- Space to commit box or cancel
  safe_map('<Space>', function()
    if state.mode == 'box' then
      draw_box_commit()
    elseif state.mode == 'select' then
      -- cancel selection
      state.mode = nil
      state.box_start = nil
      clear_start_marker()
      update_status 'Selection Cancelled'
    else
      state.mode = nil
      update_status 'Ready'
    end
  end, opts)

  safe_map('<BS>', function()
    local r, c = vim.fn.line '.', get_virt_col()
    if c > 0 then
      set_char_at(r, c - 1, ' ')
      goto_virt_pos(r, c - 1)
    end
  end, opts)

  safe_map('<Esc>', function()
    M.stop()
  end, opts)

  local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;!?-+*/=()[]{}_"\'<>`~@#$%^&'
  for i = 1, #chars do
    local c = chars:sub(i, i)
    -- if not already mapped, map for text input
    if not mapped_chars[c] then
      safe_map(c, function()
        if state.mode == 'text' then
          handle_input_char(c)
        end
      end, opts)
    end
  end
end

function M.start()
  if state.active then
    return
  end

  init_styles()

  state.active = true
  state.original_ve = vim.o.virtualedit
  vim.o.virtualedit = 'all'

  -- Create Namespace
  state.ns_id = vim.api.nvim_create_namespace 'diagram_mode_markers'

  vim.b.minisurround_disable = true
  vim.b.miniai_disable = true
  vim.b.miniindentscope_disable = true
  vim.b.minipairs_disable = true

  open_sidebar()
  set_mappings()
  update_status 'Ready'
end

function M.stop()
  if not state.active then
    return
  end
  state.active = false
  vim.o.virtualedit = state.original_ve

  vim.b.minisurround_disable = nil
  vim.b.miniai_disable = nil
  vim.b.miniindentscope_disable = nil
  vim.b.minipairs_disable = nil

  close_sidebar()
  clear_start_marker()

  for _, key in ipairs(state.mapped_keys) do
    pcall(vim.api.nvim_buf_del_keymap, 0, 'n', key)
  end
  state.mapped_keys = {}
  -- print 'Exited Diagram Mode.'

  state.mode = nil
  state.box_start = nil
  state.clipboard = nil
end

return M
