# Hop Extensions for Treesitter and LSP

Work-in-progress. API may change. Performance may improve. Only Lua API for now

```lua
local hop = require'hop-extension'

-- You can access anything in `require'hop'`
hop.hint_words()
hop.hint_lines()
hop.<fallback> -- etc.

-- Jump to instances of cword or cWORD
hop.hint_cword() 
hop.hint_cWORD() 

-- Treesitter Extensions
-- locals in treesitter are nodes that represents variables, functions, classes etc
-- Including definitions, references, implementations etc

-- This will label all locals in the visible screen
hop.hint_locals(filter) -- You can provide a filter function that receives a treesitter node object and returns a boolean

-- Jump to definitions
hop.hint_definitions() 
-- Jump to references
hop.hint_references() 
hop.hint_references('<cword>')  -- Only label refernces that match <cword>
hop.hint_references('<cWORD>')  -- Only label refernces that match <cWORD>
-- Jump to scopes
hop.hint_scopes() 

-- Jump to textobjects (anything used in nvim-treesitter/nvim-treesitter-textobjects)
-- aka anything defined in textobjects.scm
hop.hint_textobjects()
hop.hint_textobjects('function') -- You can label specific textobjects
-- for all textobjects available for your language check
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects 

-- LSP (pretty incomplete)
-- Jump to any LSP diagnostic (errors, warnings etc)
hop.hint_diagnostics() 
-- Jump to any LSP symbols
hop.hint_symbols() 
```


