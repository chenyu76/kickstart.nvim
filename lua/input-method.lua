-- 定义一个函数来获取输入法状态，并返回 1: 'pinyin' 或 0: 'keyboard-us'
local function get_fcitx_state()
	local state = vim.fn.system("/usr/bin/fcitx5-remote -n")
	if state:match("pinyin") then
		return 1
	else
		return 0
	end
end

-- 定义一个函数来设置输入法状态
local function set_fcitx_state(state)
	-- 如果是拼音(1)，就打开输入法
	if state == 1 then
		-- vim.notify("拼音打开", vim.log.levels.INFO)
		vim.fn.system("/usr/bin/fcitx5-remote -o")
	end
end

-- 保存输入法状态到 vim.g 变量中
vim.g.fcitx_status = get_fcitx_state()

-- 配置自动命令
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
	pattern = { "*" },
	callback = function()
		vim.g.fcitx_status = get_fcitx_state()
		vim.fn.system("/usr/bin/fcitx5-remote -c")
	end,
})
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
	pattern = { "*" },
	callback = function()
		set_fcitx_state(vim.g.fcitx_status)
	end,
})

-- 在 BufCreate, BufEnter, BufLeave 时调用 fcitx5-remote -c 来关闭输入法
vim.api.nvim_create_autocmd({ "BufCreate", "BufEnter", "BufLeave" }, {
	pattern = { "*" },
	callback = function()
		vim.fn.system("/usr/bin/fcitx5-remote -c")
	end,
})

-- 在插入模式下连续输入两个空格时，自动切换输入法
--[[ vim.api.nvim_create_autocmd({ "InsertEnter" }, {
	pattern = { "*" },
	callback = function()
		vim.api.nvim_buf_set_keymap(0, "i", "  ", " ", {
			callback = function()
				set_fcitx_state(1 - get_fcitx_state())
				vim.g.fcitx_status = get_fcitx_state()
				vim.api.nvim_feedkeys(" ", "n", true)
			end,
		})
	end,
})

local last_space_time = 0
local space_delay = 0.3 -- 双击空格的时间间隔，单位是秒

vim.api.nvim_set_keymap("i", "<Space>", "", {
	noremap = true,
	silent = true,
	callback = function()
		local current_time = vim.fn.reltimefloat(vim.fn.reltime())
		if current_time - last_space_time < space_delay then
			-- 双击空格时切换输入法并删除一个空格
			set_fcitx_state(1 - get_fcitx_state())
			vim.g.fcitx_status = get_fcitx_state()
			-- 删除一个空格
			vim.api.nvim_input("<BS>") -- 模拟按下退格键
		else
			-- 单击空格时正常输入空格
			vim.api.nvim_input("<Space>")
		end
		last_space_time = current_time
	end,
})
-- 连续输入两次空格切换输入法并删除多余的空格
local last_space_time = 0
local space_count = 0
local space_delay = 500 -- 空格之间允许的最大时间间隔（毫秒）

vim.api.nvim_buf_set_keymap(0, "i", "<Space>", "<Nop>", {
	noremap = true,
	silent = true,
	callback = function()
		vim.notify("hit space", vim.log.levels.INFO)
		vim.api.nvim_input("<Space>")
	end,
})
vim.api.nvim_buf_set_keymap(0, "i", "<Space>", "<Nop>", {
	noremap = true,
	silent = true,
	callback = function()
		local current_time = vim.fn.reltimefloat(vim.fn.reltime())
		vim.notify("hit space", vim.log.levels.INFO)
		if current_time - last_space_time < space_delay / 1000 then
			-- 如果两次空格之间的时间间隔小于 space_delay，增加空格计数
			space_count = space_count + 1
		else
			-- 如果间隔时间较长，重置空格计数
			space_count = 1
		end

		if space_count == 2 then
			-- 双击空格时切换输入法并删除一个空格
			set_fcitx_state(1 - get_fcitx_state())
			vim.g.fcitx_status = get_fcitx_state()
			-- 删除一个空格
			-- vim.api.nvim_input("<BS>") -- 模拟按下退格键
			space_count = 0 -- 重置空格计数
		else
			vim.api.nvim_input("<Space>")
		end

		-- 更新最后一次按空格的时间
		last_space_time = current_time
	end,
})

]]
--[[ vim.keymap.set("i", "<Space>", function()
	vim.notify("输入空格", vim.log.levels.INFO)
	-- 继续插入空格
	vim.api.nvim_input("<Space>")
end, {
	noremap = false,
	silent = true,
})
-- 配置 Leader + Leader 切换输入法并进入插入模式
vim.keymap.set("i", "<Leader><Space>", function()
	set_fcitx_state(1 - get_fcitx_state())
	vim.g.fcitx_status = get_fcitx_state()
	-- vim.api.nvim_input("i") -- 进入插入模式
end, { noremap = true, silent = true })
]]
