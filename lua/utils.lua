function M.tbl_length(T)
  local count = 0
  for _ in pairs(T) do
    count = count + 1
  end
  return count
end

function M.get_visual_selection()
  local _, csrow, cscol, cerow, cecol
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" then
    _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
    if mode == "V" then
      cscol, cecol = 0, 999
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  else
    _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  end
  if cerow < csrow then
    csrow, cerow = cerow, csrow
  end
  if cecol < cscol then
    cscol, cecol = cecol, cscol
  end
  local lines = vim.fn.getline(csrow, cerow)
  local n = M.tbl_length(lines)
  if n <= 0 then
    return ""
  end
  lines[n] = string.sub(lines[n], 1, cecol)
  lines[1] = string.sub(lines[1], cscol)
  return table.concat(lines, "\n"),
    {
      start = { line = csrow, char = cscol },
      ["end"] = { line = cerow, char = cecol },
    }
end

function M.mode_is_visual()
  local visual_modes = {
    v = true,
    vs = true,
    V = true,
    Vs = true,
    nov = true,
    noV = true,
    niV = true,
    Rv = true,
    Rvc = true,
    Rvx = true,
  }
  local mode = vim.api.nvim_get_mode()
  return visual_modes[mode.mode]
end

return M
