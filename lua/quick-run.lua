-- quickly run code snippets or files based on their file type.

-- different file types use different commands to run
-- Three ways to define commands:
-- 1. string:
--      a command pattern with optional variables:
--        $dir
--        $dirWithoutTrailingSlash
--        $fullFileName
--        $fileName
--        $fileNameWithoutExt
--        $arg
-- 2. function:
--      a Lua function that executes the desired command(s)
-- 3. table:
--      a table with a 'cmd' field (string or function)
--      and optional field:
--        reload(boolean): reload the file after running the command
local ft_cmds = {
  python = {
    cmd = 'cd "$dir" && python "$fileName" $arg',
    reload = true,
  },
  tex = function()
    -- 检测是否有 .latexmkrc 文件
    local function have_latexmkrc()
      local current_file = vim.fn.expand '%:p'
      local dir = vim.fn.fnamemodify(current_file, ':h')
      local latexmkrc = dir .. '/.latexmkrc'
      return vim.fn.filereadable(latexmkrc) == 1
    end

    if have_latexmkrc() then
      RunCommand 'cd "$dir" && latexmk && exit'
    else
      TryBibTeX()
      RunCommand 'cd "$dir" && xelatex -synctex=1 --shell-escape -interaction=scrollmode "$fileName" && exit'
    end
  end,
  typst = 'cd "$dir" && typst compile "$fileName"',
  sh = 'bash "$fullFileName"',
  c = 'gcc ./$fileName -o ./$fileNameWithoutExt.o && ./$fileNameWithoutExt.o $arg',
  cpp = 'g++ ./$fileName -o ./$fileNameWithoutExt.o && ./$fileNameWithoutExt.o $arg',
  java = 'javac $fullFileName',
  javascript = 'node $fullFileName',
  rust = function()
    -- 检测 Rust cargo 项目
    local function is_cargo_project()
      local current_file = vim.fn.expand '%:p'
      local dir = vim.fn.fnamemodify(current_file, ':h')

      -- 向上查找 Cargo.toml 直到根目录
      while true do
        local cargo_toml = dir .. '/Cargo.toml'
        if vim.fn.filereadable(cargo_toml) == 1 then
          return true
        end
        local parent = vim.fn.fnamemodify(dir, ':h')
        if parent == dir then
          break -- 到达根目录
        end
        dir = parent
      end
      return false
    end
    if is_cargo_project() then
      RunCommand 'cargo run'
    else
      RunCommand 'rustc $fullFileName -o $fileNameWithoutExt && ./$fileNameWithoutExt'
    end
  end,
  html = 'xdg-open $fullFileName && exit',
  go = 'go run $fileName',
  ruby = 'ruby $fullFileName',
  php = 'php $fullFileName',
  swift = 'swift $fullFileName',
  lua = 'lua $fullFileName',
  perl = 'perl $fullFileName',
  r = 'Rscript $fullFileName',
  groovy = 'groovy $fullFileName',
  kotlin = 'kotlinc $fullFileName -include-runtime -d $fileNameWithoutExt.jar && java -jar $fileNameWithoutExt.jar',
  dart = 'dart run $fullFileName',
  haskell = 'runhaskell $fullFileName',
  elixir = 'elixir $fullFileName',
  clojure = 'clojure -M $fullFileName',
  scala = 'scala $fullFileName',
  julia = 'julia $fullFileName',
  ocaml = 'ocaml $fullFileName',
  nim = 'nim c -r $fullFileName',
  v = 'v run $fullFileName',
  zig = 'zig run $fullFileName',
}

-- 通用命令执行函数（支持 TermExec 和路径格式化）
function RunCommand(cmd_pattern, arg)
  -- 获取文件路径信息
  local file_info = {
    dir = vim.fn.expand '%:p:h', -- 文件所在目录（含末尾斜杠）
    dirWithoutTrailingSlash = vim.fn.expand '%:p:h:gs?/?$??', -- 去除末尾斜杠的目录
    fullFileName = vim.fn.expand '%:p', -- 完整文件路径
    fileName = vim.fn.expand '%:t', -- 带扩展名的文件名
    fileNameWithoutExt = vim.fn.expand '%:t:r', -- 不带扩展名的文件名
    arg = arg or '', -- 传递给脚本的参数
  }

  -- 路径转义处理函数（处理空格和特殊字符）
  local escape_shell = function(s)
    return s:gsub('"', '\\"'):gsub("'", "\\'")
  end

  -- 替换格式化变量
  local cmd = cmd_pattern:gsub('$(%w+)', function(var)
    local value = file_info[var]
    if value then
      -- 特殊处理目录末尾斜杠
      if var == 'dirWithoutTrailingSlash' then
        value = value:gsub('/+$', '')
      end
      return value
    end
    return '$' .. var -- 未识别的变量保持原样
  end)

  -- 执行 TermExec 命令
  -- vim.notify('TermExec cmd="' .. escape_shell(cmd) .. '"')
  vim.cmd 'ToggleTerm' -- 打开终端窗口
  vim.cmd("TermExec cmd='" .. cmd .. "' dir='" .. file_info.dir .. "'")
end

-- Shebang 检测函数
local function get_shebang_command()
  local file_path = vim.fn.expand '%:p'
  local file = io.open(file_path, 'r')
  if not file then
    return nil
  end
  local first_line = file:read '*l'
  file:close()

  if not first_line or first_line:sub(1, 2) ~= '#!' then
    return nil
  end

  local shebang = first_line:sub(3)
  -- 清理 Shebang 行的换行符和尾部空格
  shebang = shebang:gsub('%s+$', '')
  -- 获取完整文件路径并拼接命令
  local fullFileName = vim.fn.expand '%:p'
  return shebang .. ' ' .. fullFileName
end

-- 检查所有窗口中的缓冲区并重载
local function reload_modified_buffers()
  -- 遍历所有窗口
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    -- 获取该窗口中的缓冲区 ID
    local bufnr = vim.api.nvim_win_get_buf(winid)

    -- 检查该缓冲区是否有一个关联的文件（非 scratch/unlisted 缓冲区）
    -- 并且该文件是可见的（即在某个窗口中显示）
    if vim.api.nvim_get_option_value('buflisted', { buf = bufnr }) and vim.api.nvim_get_option_value('filetype', { buf = bufnr }) ~= '' then
      -- 在该窗口执行 :checktime
      -- :checktime 会检查该缓冲区文件在磁盘上的修改时间。
      -- 如果文件在外部修改了，且缓冲区未修改，它会自动重新加载。
      vim.api.nvim_win_call(winid, function()
        vim.cmd 'checktime'
      end)
    end
  end
end

-- 主函数，根据文件类型选择命令执行
-- arg 参数可选，传递给脚本
function Compile_current_file(arg)
  vim.cmd 'w' -- 先保存文件

  local filetype = vim.bo.filetype
  local cmd = ft_cmds[filetype] or 'SnipRun'

  if type(cmd) ~= 'table' then
    cmd = {
      cmd = cmd,
    }
  end

  -- 没有配置的话使用 SnipRun
  if cmd == 'SnipRun' then
    vim.cmd 'SnipRun'
  else
    if type(cmd.cmd) == 'function' then
      cmd.cmd() -- 如果是函数，调用它
    else
      -- 优先使用 shebang 行
      local shebang_cmd = get_shebang_command()
      if shebang_cmd then
        RunCommand(shebang_cmd, arg)
      else
        RunCommand(cmd.cmd, arg)
      end
    end
    if cmd.reload then
      -- 重载所有修改过的缓冲区
      -- 现在有一个问题
      -- 命令执行是异步的
      -- 可能在命令执行完成前就执行了重载
      -- 但目前我不知道怎么知道什么时候命令执行完成了
      -- 所以现在是等待一段时间后尝试重载
      vim.defer_fn(reload_modified_buffers, 300)
      vim.defer_fn(reload_modified_buffers, 1000)
      vim.defer_fn(reload_modified_buffers, 2000)
    end
  end
end

function Compile_current_file_with_arg()
  vim.cmd 'w' -- 先保存文件
  local arg = vim.fn.input 'Input arguments: '
  Compile_current_file(arg)
end

-- 编译tex文件时，检查是否需要运行 BibTeX并执行
function TryBibTeX()
  local tex_path = vim.fn.expand '%:p' -- 获取当前 tex 文件的完整路径
  local aux_path = tex_path:gsub('%.tex$', '.aux') -- 生成对应的 aux 文件路径

  -- 检查 aux 文件是否存在
  local aux_file = io.open(aux_path, 'r')
  if not aux_file then
    return
  end

  -- 检查是否包含 bibdata 条目
  local needs_bibtex = false
  for line in aux_file:lines() do
    if line:find '\\bibdata{' then
      needs_bibtex = true
      break
    end
  end
  aux_file:close()

  -- 执行 BibTeX 编译
  if needs_bibtex then
    -- 静默执行并捕获输出
    local success, output = pcall(vim.fn.systemlist, 'cd ' .. vim.fn.expand '%:p:h' .. ' &&  bibtex ' .. vim.fn.shellescape(vim.fn.expand '%:t:r' .. '.aux'))

    -- 显示编译结果
    if success then
      vim.notify('BibTeX build success:\n' .. table.concat(output, '\n'), vim.log.levels.INFO)
    else
      vim.notify('BibTeX build fail:\n' .. table.concat(output, '\n'), vim.log.levels.ERROR)
    end
  end
end
