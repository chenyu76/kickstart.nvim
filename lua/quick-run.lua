-- different file types use different commands to run
local ft_cmds = {
	python = 'cd "$dir" && python "$fileName"',
	latex = 'cd "$dir" && xelatex -synctex=1 --shell-escape "$fileName"',
	tex = 'cd "$dir" && xelatex -synctex=1 --shell-escape "$fileName"',
	typst = 'cd "$dir" && typst compile "$fileName"',
	sh = 'bash "$fullFileName"',
	c = "gcc ./$fileName -o ./$fileNameWithoutExt.o && ./$fileNameWithoutExt.o",
	cpp = "g++ ./$fileName -o ./$fileNameWithoutExt.o && ./$fileNameWithoutExt.o",
	java = "javac $fullFileName",
	javascript = "node $fullFileName",
	rust = function()
		-- 检测 Rust cargo 项目
		local function is_cargo_project()
			local current_file = vim.fn.expand("%:p")
			local dir = vim.fn.fnamemodify(current_file, ":h")

			-- 向上查找 Cargo.toml 直到根目录
			while true do
				local cargo_toml = dir .. "/Cargo.toml"
				if vim.fn.filereadable(cargo_toml) == 1 then
					return true
				end
				local parent = vim.fn.fnamemodify(dir, ":h")
				if parent == dir then
					break -- 到达根目录
				end
				dir = parent
			end
			return false
		end
		if is_cargo_project() then
			RunCommand("cargo run")
		else
			RunCommand("rustc $fullFileName -o $fileNameWithoutExt && ./$fileNameWithoutExt")
		end
	end,
	go = "go run $fileName",
	ruby = "ruby $fullFileName",
	php = "php $fullFileName",
	swift = "swift $fullFileName",
	lua = "lua $fullFileName",
	perl = "perl $fullFileName",
	r = "Rscript $fullFileName",
	groovy = "groovy $fullFileName",
	kotlin = "kotlinc $fullFileName -include-runtime -d $fileNameWithoutExt.jar && java -jar $fileNameWithoutExt.jar",
	dart = "dart run $fullFileName",
	haskell = "runhaskell $fullFileName",
	elixir = "elixir $fullFileName",
	clojure = "clojure -M $fullFileName",
	scala = "scala $fullFileName",
	julia = "julia $fullFileName",
	ocaml = "ocaml $fullFileName",
	nim = "nim c -r $fullFileName",
	v = "v run $fullFileName",
	zig = "zig run $fullFileName",
}

-- 通用命令执行函数（支持 TermExec 和路径格式化）
function RunCommand(cmd_pattern)
	-- 获取文件路径信息
	local file_info = {
		dir = vim.fn.expand("%:p:h"), -- 文件所在目录（含末尾斜杠）
		dirWithoutTrailingSlash = vim.fn.expand("%:p:h:gs?/?$??"), -- 去除末尾斜杠的目录
		fullFileName = vim.fn.expand("%:p"), -- 完整文件路径
		fileName = vim.fn.expand("%:t"), -- 带扩展名的文件名
		fileNameWithoutExt = vim.fn.expand("%:t:r"), -- 不带扩展名的文件名
	}

	-- 路径转义处理函数（处理空格和特殊字符）
	local escape_shell = function(s)
		return s:gsub('"', '\\"'):gsub("'", "\\'")
	end

	-- 替换格式化变量
	local cmd = cmd_pattern:gsub("$(%w+)", function(var)
		local value = file_info[var]
		if value then
			-- 特殊处理目录末尾斜杠
			if var == "dirWithoutTrailingSlash" then
				value = value:gsub("/+$", "")
			end
			return value
		end
		return "$" .. var -- 未识别的变量保持原样
	end)

	-- 执行 TermExec 命令
	-- vim.notify('TermExec cmd="' .. escape_shell(cmd) .. '"')
	vim.cmd("ToggleTerm") -- 打开终端窗口
	vim.cmd("TermExec cmd='" .. cmd .. "' dir='" .. file_info.dir .. "'")
end

-- 新增：Shebang 检测函数
local function get_shebang_command()
	local file_path = vim.fn.expand("%:p")
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end
	local first_line = file:read("*l")
	file:close()

	if not first_line or first_line:sub(1, 2) ~= "#!" then
		return nil
	end

	local shebang = first_line:sub(3)
	-- 清理 Shebang 行的换行符和尾部空格
	shebang = shebang:gsub("%s+$", "")
	-- 获取完整文件路径并拼接命令
	local fullFileName = vim.fn.expand("%:p")
	return shebang .. " " .. fullFileName
end

function Compile_current_file()
	vim.cmd("w") -- 先保存文件

	local filetype = vim.bo.filetype
	local cmd = ft_cmds[filetype] or "SnipRun" -- 默认使用 SnipRun

	if cmd == "SnipRun" then
		vim.cmd("SnipRun")
	else
		if type(cmd) == "function" then
			cmd() -- 如果是函数，调用它
		else
			-- 修改点：添加 Shebang 判断逻辑
			local shebang_cmd = get_shebang_command()
			if shebang_cmd then
				RunCommand(shebang_cmd)
			else
				RunCommand(cmd)
			end
		end
	end
end

-- 编译tex文件时，检查是否需要运行 BibTeX并执行
function TryBibTeX()
	local tex_path = vim.fn.expand("%:p") -- 获取当前 tex 文件的完整路径
	local aux_path = tex_path:gsub("%.tex$", ".aux") -- 生成对应的 aux 文件路径

	-- 检查 aux 文件是否存在
	local aux_file = io.open(aux_path, "r")
	if not aux_file then
		return
	end

	-- 检查是否包含 bibdata 条目
	local needs_bibtex = false
	for line in aux_file:lines() do
		if line:find("\\bibdata{") then
			needs_bibtex = true
			break
		end
	end
	aux_file:close()

	-- 执行 BibTeX 编译
	if needs_bibtex then
		-- 静默执行并捕获输出
		local success, output = pcall(
			vim.fn.systemlist,
			"cd " .. vim.fn.expand("%:p:h") .. " &&  bibtex " .. vim.fn.shellescape(vim.fn.expand("%:t:r") .. ".aux")
		)

		-- 显示编译结果
		if success then
			vim.notify("BibTeX build success:\n" .. table.concat(output, "\n"), vim.log.levels.INFO)
		else
			vim.notify("BibTeX build fail:\n" .. table.concat(output, "\n"), vim.log.levels.ERROR)
		end
	end
end

-- 设置 Leader + R 快捷键
-- 在 keybindings 中
-- vim.api.nvim_set_keymap("n", "<leader>R", ":lua Compile_current_file()<CR>", { noremap = true, silent = true })
