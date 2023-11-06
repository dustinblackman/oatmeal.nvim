local M = {}

local config = {}
local session_context = {}

local function to_base64(data)
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	return (
		(data:gsub(".", function(x)
			local r, b = "", x:byte()
			for i = 8, 1, -1 do
				r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
			end
			return r
		end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
			if #x < 6 then
				return ""
			end
			local c = 0
			for i = 1, 6 do
				c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
			end
			return b:sub(c + 1, c + 1)
		end) .. ({ "", "==", "=" })[#data % 3 + 1]
	)
end

function M.set_context()
	local start_line = vim.api.nvim_win_get_cursor(0)[1]
	local end_line = nil
	local code = ""

	-- Visual Mode
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")
	if vstart ~= nil and vend ~= nil and vend[2] ~= 0 then
		start_line = vstart[2]
		end_line = vend[2]

		local select_start_line = start_line
		if select_start_line ~= 0 then
			select_start_line = select_start_line - 1
		end

		local lines = vim.api.nvim_buf_get_lines(0, select_start_line, end_line, true)
		code = table.concat(lines, "\n")
	end

	session_context = {
		file_path = vim.fn.expand("%:p"),
		language = vim.bo.filetype,
		buffer_id = vim.fn.bufnr(),
		code = to_base64(code),
		start_line = start_line,
		end_line = end_line,
	}
end

function M.submit_changes(file_path)
	local f = assert(io.open(file_path, "rb"))
	local json_string = f:read("*all")
	local json = vim.json.decode(json_string)

	local lines = {}
	for s in json["code"]:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end

	local start_line = 0
	if json["start_line"] ~= 0 then
		start_line = json["start_line"] - 1
	end

	if json["end_line"] == nil or json["end_line"] == vim.NIL then
		vim.api.nvim_buf_set_lines(session_context.buffer_id, start_line, start_line, true, lines)
	elseif json["accept_type"] == "append" then
		vim.api.nvim_buf_set_lines(session_context.buffer_id, json["end_line"], json["end_line"], true, lines)
	else
		vim.api.nvim_buf_set_lines(session_context.buffer_id, start_line, json["end_line"], true, lines)
	end

	os.remove(file_path)
end

function M.get_context()
	return vim.json.encode(session_context)
end

function M.clear_context()
	if config["close_terminal_on_quit"] ~= false and session_context.terminal_buffer_id ~= nil then
		vim.cmd("bd! " .. session_context.terminal_buffer_id)
	end

	session_context = {}
end

function M.start()
	M.set_context()

	local args = {}

	if vim.fn.has("macunix") then
		table.insert(args, "oatmeal")
	else
		table.insert(args, "oatmeal.exe")
	end

	table.insert(args, "--editor")
	table.insert(args, "neovim")

	local flags = { "backend", "model", "theme", "theme-file", "openai-url", "openai-token" }
	for _, key in pairs(flags) do
		local config_name = string.gsub(key, "-", "_")
		if config[config_name] ~= nil then
			table.insert(args, "--" .. key)
			table.insert(args, config[config_name])
		end
	end

	vim.cmd.vsplit()
	vim.cmd.terminal()
	vim.api.nvim_chan_send(vim.bo.channel, table.concat(args, " ") .. "\r")
	vim.api.nvim_feedkeys("a", "t", false)

	session_context.terminal_buffer_id = vim.fn.bufnr()
end

function M.setup(conf)
	config = conf
end

_G.oatmeal_submit_changes = M.submit_changes
_G.oatmeal_get_context = M.get_context
_G.oatmeal_clear_context = M.clear_context

vim.api.nvim_create_user_command("Oatmeal", M.start, { desc = "Start Oatmeal session", range = true })
vim.keymap.set("n", "<leader>om", M.start, { silent = true, noremap = true })
vim.keymap.set("v", "<leader>om", M.start, { silent = true, noremap = true })
return M
