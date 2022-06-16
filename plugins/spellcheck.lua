-- mod-version:3
local core = require "core"
local style = require "core.style"
local config = require "core.config"
local command = require "core.command"
local common = require "core.common"
local DocView = require "core.docview"
local Doc = require "core.doc"

local platform_dictionary_file
if PLATFORM == "Windows" then
  platform_dictionary_file = EXEDIR .. "/words.txt"
else
  platform_dictionary_file = "/usr/share/dict/words"
end

config.plugins.spellcheck = common.merge({
  enabled = true,
  files = { "%.txt$", "%.md$", "%.markdown$" },
  dictionary_file = platform_dictionary_file
}, config.plugins.spellcheck)

local last_input_time = 0
local word_pattern = "%a+"
local words

local function load_dictionary()
  core.add_thread(function()
    local t = {}
    local i = 0
    for line in io.lines(config.plugins.spellcheck.dictionary_file) do
      for word in line:gmatch(word_pattern) do
        t[word:lower()] = true
      end
      i = i + 1
      if i % 1000 == 0 then coroutine.yield() end
    end
    words = t
    core.redraw = true
    core.log_quiet(
      "Finished loading dictionary file: \"%s\"",
      config.plugins.spellcheck.dictionary_file
    )
  end)
end


local function matches_any(filename, ptns)
  for _, ptn in ipairs(ptns) do
    if filename:find(ptn) then return true end
  end
end


local function active_word(doc, line, tail)
  local l, c = doc:get_selection()
  return l == line and c == tail
     and doc == core.active_view.doc
     and system.get_time() - last_input_time < 0.5
end


local text_input = Doc.text_input

function Doc:text_input(...)
  text_input(self, ...)
  last_input_time = system.get_time()
end


local draw_line_text = DocView.draw_line_text

function DocView:draw_line_text(idx, x, y)
  local lh = draw_line_text(self, idx, x, y)

  if
    not config.plugins.spellcheck.enabled
    or
    not words
    or
    not matches_any(self.doc.filename or "", config.plugins.spellcheck.files)
  then
    return lh
  end

  local s, e = 0, 0
  local text = self.doc.lines[idx]

  while true do
    s, e = text:find(word_pattern, e + 1)
    if not s then break end
    local word = text:sub(s, e):lower()
    if not words[word] and not active_word(self.doc, idx, e + 1) then
      local color = style.spellcheck_error or style.syntax.keyword2
      local x1, y1 = self:get_line_screen_position(idx, s)
      local x2, y2 = self:get_line_screen_position(idx, e + 1)
      local h = math.ceil(1 * SCALE)
      renderer.draw_rect(x1, y1 + self:get_line_height() - h, x2 - x1, h, color)
    end
  end
  return lh
end


local function get_word_at_caret()
  local doc = core.active_view.doc
  local l, c = doc:get_selection()
  local s, e = 0, 0
  local text = doc.lines[l]
  while true do
    s, e = text:find(word_pattern, e + 1)
    if c >= s and c <= e + 1 then
      return text:sub(s, e):lower(), s, e
    end
  end
end


local function compare_words(word1, word2)
  local res = 0
  for i = 1, math.max(#word1, #word2) do
    if word1:byte(i) ~= word2:byte(i) then
      res = res + 1
    end
  end
  return res
end


-- The config specification used by the settings gui
config.plugins.spellcheck.config_spec = {
  name = "Spell Check",
  {
    label = "Enabled",
    description = "Disable or enable spell checking.",
    path = "enabled",
    type = "toggle",
    default = true
  },
  {
    label = "Files",
    description = "List of Lua patterns matching files to spell check.",
    path = "files",
    type = "list_strings",
    default = { "%.txt$", "%.md$", "%.markdown$" }
  },
  {
    label = "Dictionary File",
    description = "Path to a text file that contains a list of dictionary words.",
    path = "dictionary_file",
    type = "string",
    default = platform_dictionary_file,
    on_apply = function()
      load_dictionary()
    end
  }
}

load_dictionary()

command.add("core.docview", {

  ["spell-check:toggle"] = function()
    config.plugins.spellcheck.enabled = not config.plugins.spellcheck.enabled
  end,

  ["spell-check:add-to-dictionary"] = function()
    local word = get_word_at_caret()
    if words[word] then
      core.error("\"%s\" already exists in the dictionary", word)
      return
    end
    if word then
      local fp = assert(io.open(config.plugins.spellcheck.dictionary_file, "a"))
      fp:write("\n" .. word .. "\n")
      fp:close()
      words[word] = true
      core.log("Added \"%s\" to dictionary", word)
    end
  end,


  ["spell-check:replace"] = function()
    local word, s, e = get_word_at_caret()

    -- find suggestions
    local suggestions = {}
    local word_len = #word
    for w in pairs(words) do
      if math.abs(#w - word_len) <= 2 then
        local diff = compare_words(word, w)
        if diff < word_len * 0.5 then
          table.insert(suggestions, { diff = diff, text = w })
        end
      end
    end
    if #suggestions == 0 then
      core.error("Could not find any suggestions for \"%s\"", word)
      return
    end

    -- sort suggestions table and convert to properly-capitalized text
    table.sort(suggestions, function(a, b) return a.diff < b.diff end)
    local doc = core.active_view.doc
    local line = doc:get_selection()
    local has_upper = doc.lines[line]:sub(s, s):match("[A-Z]")
    for k, v in pairs(suggestions) do
      if has_upper then
        v.text = v.text:gsub("^.", string.upper)
      end
      suggestions[k] = v.text
    end

    -- select word and init replacement selector
    local label = string.format("Replace \"%s\" With", word)
    doc:set_selection(line, e + 1, line, s)
    core.command_view:enter(label, {
      submit = function(text, item)
        text = item and item.text or text
        doc:replace(function() return text end)
      end,
      suggest = function(text)
        local t = {}
        for _, w in ipairs(suggestions) do
          if w:lower():find(text:lower(), 1, true) then
            table.insert(t, w)
          end
        end
        return t
      end
    })
  end,

})

local contextmenu = require "plugins.contextmenu"
contextmenu:register("core.docview", {
  contextmenu.DIVIDER,
  { text = "View Suggestions",  command = "spell-check:replace" },
  { text = "Add to Dictionary", command = "spell-check:add-to-dictionary" }
})
