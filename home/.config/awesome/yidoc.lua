local awful     = require("awful")
local naughty   = require("naughty")
local string    = string
local math      = math
local pairs     = pairs
local tostring  = tostring
local table     = table
local io        = io

local maxlen = 0
module("yidoc")

local nid = nil

-- trim left/right spaces
local function trim(str)
  local r,_ = str:gsub("^%s*(.-)%s*$", "%1")
  return r
end

-- Unicode "aware" length function (well, UTF8 aware)
-- See: http://lua-users.org/wiki/LuaUnicode
local function unilen(str)
   local _, count = string.gsub(str, "[^\128-\193]", "")
   return count
end

function parse(fname)
  local fh = io.open(fname)
  local result = {}
  maxlen = 0
  local title = ""
  while true do
    line = fh:read("*l")
    if line == nil then break end
    if string.find(line, "==") then
      local s,_ = string.gsub(line, "==", "")
      title = trim(s)
      result[title] = {}
    else
      local pos = string.find(line, "-")
      if pos then
        local left = trim(string.sub(line, 1, pos-1))
        maxlen = math.max(maxlen, unilen(left))
        local right = trim(string.sub(line, pos+1))
        result[title][left] = right
      end
    end
  end
  fh:close()
  return result
end

local function markup(keydocs, opt)
  local result = {}
  for title,grp in pairs(keydocs) do
    result[#result + 1] = '<span color="' .. opt.title_fg .. '"><b>' .. title .. '</b></span>'
    for key,doc in pairs(grp) do
      result[#result + 1] = 
        '<span color="' .. opt.key_fg .. '">' ..
        string.format("%" .. (maxlen - unilen(key)) .. "s  ", "") .. key ..
        '</span>  <span color="' .. opt.doc_fg .. '">' ..
        doc .. '</span>'
    end
  end
  return result
end

function display(fname, opt)
  opt.title_fg = opt.title_fg or "#EA6F81"
  opt.key_fg   = opt.key_fg   or "#D8D782"
  opt.doc_fg   = opt.doc_fg   or "white"
  opt.font     = opt.font     or "Dejavu Sans Mono 10"
  opt.opacity  = opt.opacity  or 0.9

  local lines = markup(parse(fname), opt)
  local result = ""
  for _,line in pairs(lines) do
    result = result .. line .. '\n'
  end

  nid = naughty.notify({
    text = result,
    replaces_id = nid,
    hover_timeout = 0.1,
    timeout = 10,
    font = opt.font,
    opacity = opt.opacity
  }).nid
end
