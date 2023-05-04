local hop = require("hop-extension")

-- You can access anything in `require'hop'`
hop.hint_words()
hop.hint_lines()
-- hop.<fallback> -- etc.

-- An extension to hint_patterns that allows you to generate the pattern
hop.hint_patterns_from(hop_opts or {}, { reg = "a" }) -- From the `a` register
hop.hint_patterns_from(hop_opts or {}, { expand = "<cword>" }) -- From the current word (any vim.fn.expand expression)

-- Jump to diagnostics
-- popup is a controls how and whether `vim.diagnostic.open_float` should be called once jumped
--     `nil` will show a float with the diagnostic at the cursor
--     `false` will disable
--     a string will be assumed to be the `scope` argument to `open_float`
--     a table will be passed to `open_float` directly
--     a function will be called instead of `open_float`
-- diag_opts are passed to `vim.diagnostic.get` thus can be used to customize which diagnostics are shown
hop.hint_diagnostics(hop_opts or {}, diag_opts or {}, popup)

-- Treesitter Extensions are in hop.ts
-- locals in treesitter are nodes that represents variables, functions, classes etc
-- Including definitions, references, implementations etc

-- This will label all locals in the visible screen
hop.ts.hint_locals(hop_opts or {}, function(name, node)
	-- You can filter the list using any
	return true
end)

-- Jump to definitions
hop.ts.hint_definitions()
-- Jump to references
hop.ts.hint_references()

hop.ts.hint_references(hop_opts or {}, { expand = "<cword>" }) -- Only label refernces that match <cword>
hop.ts.hint_references(hop_opts or {}, { expand = "<cWORD>" }) -- Only label refernces that match <cWORD>
-- Jump to definitions or references
hop.ts.hint_references()
-- Jump to scopes
hop.ts.hint_scopes()

-- Jump to textobjects (anything used in nvim-treesitter/nvim-treesitter-textobjects)
-- aka anything defined in textobjects.scm
hop.ts.hint_textobjects(hop_opts or {})
hop.ts.hint_textobjects(hop_opts or {}, "@function") -- You can ask for a specific textobject (capture group)
hop.ts.hint_textobjects(hop_opts or {}, {
	captures = { "@function.inner", "@block.outer" },
}) -- or multiple
-- for all textobjects available for your language check
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects

-- The most general treesitter function for making your own
-- Basically wraps 'require'nvim-treesitter.query'.get_capture_matches()
hop.ts.hint_from_from_query({
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
hop.lsp.hint_symbols()
hop.lsp.hint_definition()
hop.lsp.hint_declaration()
hop.lsp.hint_type_definition()
hop.lsp.hint_references()
hop.lsp.hint_implementation()

-- Miscellaneous
hop.hint_quickfix(list, hop_opts or {})
hop.hint_loclist(list, hop_opts or {})
