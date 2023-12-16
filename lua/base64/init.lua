--[[

 base64 -- v1.5.3 public domain Lua base64 encoder/decoder
 no warranty implied; use at your own risk

 Needs bit32.extract function. If not present it's implemented using BitOp
 or Lua 5.3 native bit operators. For Lua 5.1 fallbacks to pure Lua
 implementation inspired by Rici Lake's post:
   http://ricilake.blogspot.co.uk/2007/10/iterating-bits-in-lua.html

 author: Ilya Kolbin (iskolbin@gmail.com)
 url: github.com/iskolbin/lbase64

 COMPATIBILITY

 Lua 5.1+, LuaJIT

 LICENSE

 See end of file for license information.
--]]

local base64 = {}

local extract = _G.bit32 and _G.bit32.extract -- Lua 5.2/Lua 5.3 in compatibility mode
if not extract then
  if _G.bit then -- LuaJIT
    local shl, shr, band = _G.bit.lshift, _G.bit.rshift, _G.bit.band
    extract = function(v, from, width)
      return band(shr(v, from), shl(1, width) - 1)
    end
  elseif _G._VERSION == "Lua 5.1" then
    extract = function(v, from, width)
      local w = 0
      local flag = 2 ^ from
      for i = 0, width - 1 do
        local flag2 = flag + flag
        if v % flag2 >= flag then
          w = w + 2 ^ i
        end
        flag = flag2
      end
      return w
    end
  else -- Lua 5.3+
    extract = load([[return function( v, from, width )
			return ( v >> from ) & ((1 << width) - 1)
		end]])()
  end
end

function base64.makeencoder(s62, s63, spad)
  local encoder = {}
  for b64code, char in pairs({
    [0] = "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    s62 or "+",
    s63 or "/",
    spad or "=",
  }) do
    encoder[b64code] = char:byte()
  end
  return encoder
end

function base64.makedecoder(s62, s63, spad)
  local decoder = {}
  for b64code, charcode in pairs(base64.makeencoder(s62, s63, spad)) do
    decoder[charcode] = b64code
  end
  return decoder
end

local DEFAULT_ENCODER = base64.makeencoder()

local char, concat = string.char, table.concat

function base64.encode(str, encoder, usecaching)
  encoder = encoder or DEFAULT_ENCODER
  local t, k, n = {}, 1, #str
  local lastn = n % 3
  local cache = {}
  for i = 1, n - lastn, 3 do
    local a, b, c = str:byte(i, i + 2)
    local v = a * 0x10000 + b * 0x100 + c
    local s
    if usecaching then
      s = cache[v]
      if not s then
        s = char(
          encoder[extract(v, 18, 6)],
          encoder[extract(v, 12, 6)],
          encoder[extract(v, 6, 6)],
          encoder[extract(v, 0, 6)]
        )
        cache[v] = s
      end
    else
      s = char(
        encoder[extract(v, 18, 6)],
        encoder[extract(v, 12, 6)],
        encoder[extract(v, 6, 6)],
        encoder[extract(v, 0, 6)]
      )
    end
    t[k] = s
    k = k + 1
  end
  if lastn == 2 then
    local a, b = str:byte(n - 1, n)
    local v = a * 0x10000 + b * 0x100
    t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)], encoder[64])
  elseif lastn == 1 then
    local v = str:byte(n) * 0x10000
    t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[64], encoder[64])
  end
  return concat(t)
end

return base64

--[[
ALTERNATIVE A - MIT License
Copyright (c) 2018 Ilya Kolbin
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]
