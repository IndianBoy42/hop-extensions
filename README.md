# Hop Extensions for Treesitter and LSP

Work-in-progress. API may change. Performance may improve. Only Lua API for now

Install like any other plugin

```
Plug 'phaazon/hop.nvim'
Plug 'indianboy42/hop-extensions'
```

or Packer

```
use 'phaazon/hop.nvim'
use 'indianboy42/hop-extensions'

```

Usage:

```lua
local hop = require'hop-extension'

-- You can access anything in `require'hop'`
hop.hint_words()
hop.hint_lines()
hop.<fallback> -- etc.

-- Treesitter Extensions
-- locals in treesitter are nodes that represents variables, functions, classes etc
-- Including definitions, references, implementations etc

-- This will label all locals in the visible screen
hop.hint_locals(filter) -- You can provide a filter function that receives a treesitter node object and returns a boolean

-- Jump to definitions
hop.hint_definitions()
-- Jump to references
hop.hint_ts_references()
hop.hint_ts_references('<cword>')  -- Only label refernces that match <cword>
hop.hint_ts_references('<cWORD>')  -- Only label refernces that match <cWORD>
-- Jump to scopes
hop.hint_scopes()

-- Jump to textobjects (anything used in nvim-treesitter/nvim-treesitter-textobjects)
-- aka anything defined in textobjects.scm
hop.hint_textobjects()
hop.hint_textobjects('@function') -- You can ask for a specific textobject (capture group)
hop.hint_textobjects({'@function.inner', '@block.outer'}) -- or multiple
-- for all textobjects available for your language check
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects

-- The most general treesitter function for making your own
-- Basically wraps 'require'nvim-treesitter.query'.get_capture_matches()
hop.hint_from_captures({
    captures = nil, -- string|string[]|nil
    queryfile = "textobjects", -- string the name of query group (highlights or injections for example)
    query = nil, -- string If this is given then a custom query is used and queryfile is ignored
    filter = function(name, node)
        return true
    end,
    root = nil, -- TSNode|nil node from where to start the search
    lang = nil, -- string|nil the language from where to get the captures.
    hop_to_start = true, -- Add hop targets to the start of the node
    hop_to_end = true, -- Add hop targets to the end of the node
})

-- LSP
-- Hop to any of the below (see corresponding `vim.lsp.buf.<function>`)
hop.hint_symbols()
hop.hint_definition()
hop.hint_declaration()
hop.hint_type_definition()
hop.hint_references()
hop.hint_implementation()
```
