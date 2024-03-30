local base64 = require("oatmeal.base64")
local utils = require("oatmeal.utils")

local M = {}

local config = {}
local session_context = {}

function M.set_context()
  local start_line = vim.api.nvim_win_get_cursor(0)[1]
  local end_line = nil
  local code = ""

  -- In visual mode
  if utils.in_visual_mode() then
    local start_row, end_row, visual_code
    visual_code, start_row, end_row = utils.get_visual()
    if start_row ~= nil and end_row ~= nil then
      code = visual_code
      start_line = start_row
      end_line = end_row
    end
  end

  -- In command prompt coming from visual mode.
  if end_line == nil then
    local start_row, end_row, visual_code
    visual_code, start_row, end_row = utils.get_previous_visual()
    if start_row ~= nil and end_row ~= nil and start_row == start_line then
      code = visual_code
      start_line = start_row
      end_line = end_row
    end
  end

  -- If no code blocks selected, send the entire file.
  if code == "" then
    code = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    start_line = 0
    end_line = nil
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
    "open-ai-token",
    "open-ai-url",
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
