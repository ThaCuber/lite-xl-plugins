-- mod-version:3
-- Support for the Fennel programming language: https://fennel-lang.org
-- Covers all the keywords up to Fennel version 0.4.0

-- Currently only covers highlighting, not indentation, delimiter
-- matching, or evaluation.

local syntax = require "core.syntax"

syntax.add {
  name = "Fennel",
  files = "%.fnl$",
  comment = ";",
  patterns = {
    { pattern = ";.-\n",              type = "comment"  },
    { pattern = { '"', '"', '\\' },   type = "string"   },
    { pattern = "0x[%da-fA-F]+",      type = "number"   },
    { pattern = "-?%d+[%d%.]*",       type = "number"   },
    { pattern = "-?%.?%d+",           type = "number"   },
    { pattern = "%f[^(][^()'%s\"]+",  type = "function" },
    { pattern = "[^()'%s\"]+",        type = "symbol"   },
  },

  symbols = {
    ["eval-compiler"] = "keyword2",
    ["doc"] = "keyword2",
    ["lua"] = "keyword2",
    ["hashfn"] = "keyword2",
    ["macro"] = "keyword2",
    ["macros"] = "keyword2",
    ["import-macros"] = "keyword2",
    ["do"] = "keyword2",
    ["values"] = "keyword2",
    ["if"] = "keyword2",
    ["when"] = "keyword2",
    ["each"] = "keyword2",
    ["for"] = "keyword2",
    ["fn"] = "keyword2",
    ["lambda"] = "keyword2",
    ["λ"] = "keyword2",
    ["partial"] = "keyword2",
    ["while"] = "keyword2",
    ["set"] = "keyword2",
    ["global"] = "keyword2",
    ["var"] = "keyword2",
    ["local"] = "keyword2",
    ["let"] = "keyword2",
    ["tset"] = "keyword2",
    ["set-forcibly!"] = "keyword2",
    ["doto"] = "keyword2",
    ["match"] = "keyword2",
    ["or"] = "keyword2",
    ["and"] = "keyword2",
    ["not"] = "keyword2",
    ["not="] = "keyword2",
    ["pick-args"] = "keyword2",
    ["pick-values"] = "keyword2",
    ["macrodebug"] = "keyword2",

    ["."] = "keyword",
    ["+"] = "keyword",
    [".."] = "keyword",
    ["^"] = "keyword",
    ["-"] = "keyword",
    ["*"] = "keyword",
    ["%"] = "keyword",
    ["/"] = "keyword",
    [">"] = "keyword",
    ["<"] = "keyword",
    [">="] = "keyword",
    ["<="] = "keyword",
    ["="] = "keyword",
    ["#"] = "keyword",
    ["..."] = "keyword",
    [":"] = "keyword",
    ["->"] = "keyword",
    ["->>"] = "keyword",
    ["-?>"] = "keyword",
    ["-?>>"] = "keyword",
    ["$"] = "keyword",
    ["$1"] = "keyword",
    ["$2"] = "keyword",
    ["$3"] = "keyword",
    ["$4"] = "keyword",
    ["$5"] = "keyword",
    ["$6"] = "keyword",
    ["$7"] = "keyword",
    ["$8"] = "keyword",
    ["$9"] = "keyword",

    ["lshift"] = "keyword",
    ["rshift"] = "keyword",
    ["bor"] = "keyword",
    ["band"] = "keyword",
    ["bnot"] = "keyword",
    ["bxor"] = "keyword",

    ["nil"] = "literal",
    ["true"] = "literal",
    ["false"] = "literal",
  }
}
