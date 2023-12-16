local base64 = require("base64")
local utils = require("utils")

local M = {}

local config = {}
local session_context = {}

function M.set_context()
  local start_line = vim.api.nvim_win_get_cursor(0)[1]
  local end_line = nil
  local code = ""

  if common_utils.in_visual() then
    local start_pos, end_pos
    code, start_pos, end_pos = common_utils.get_visual()

    if code == nil then
      return
    end

    start_line = start_pos
    end_line = end_pos
  end

  session_context = {
    file_path = vim.fn.expand("%:p"),
    language = vim.bo.filetype,
    buffer_id = vim.fn.bufnr(),
    code = base64.encode(code),
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
  local end_line = json["end_line"]
  if json["start_line"] ~= 0 then
    start_line = json["start_line"] - 1
  end

  if json["end_line"] == nil or json["end_line"] == vim.NIL then
    vim.api.nvim_buf_set_lines(session_context.buffer_id, start_line, start_line, true, lines)
  elseif json["accept_type"] == "append" then
    end_line = vim.api.nvim__buf_stats(session_context.buffer_id).current_lnum
    vim.api.nvim_buf_set_lines(session_context.buffer_id, end_line, end_line, true, lines)
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

  local flags = {
    "backend",
    "backend-health-check-timeout",
    "editor",
    "model",
    "ollama-url",
    "openai-token",
    "openai-url",
    "theme",
    "theme-file",
  }
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

  if conf["hotkey"] == nil then
    conf["hotkey"] = "<leader>om"
  end
  if conf["hotkey"] ~= "" then
    vim.keymap.set("n", conf["hotkey"], M.start, { silent = true, noremap = true })
    vim.keymap.set("v", conf["hotkey"], M.start, { silent = true, noremap = true })
  end
end

_G.oatmeal_submit_changes = M.submit_changes
_G.oatmeal_get_context = M.get_context
_G.oatmeal_clear_context = M.clear_context

vim.api.nvim_create_user_command("Oatmeal", M.start, { desc = "Start Oatmeal session", range = true })
return M
