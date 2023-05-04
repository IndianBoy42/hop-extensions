local M = {}
-- local hop = require "hop"

local on_list_hop = require("hop-extensions.utils").on_list_hop

-- TODO: fallback to just jumping if none visible
-- TODO: use sync?

M.hint_symbols = function(opts, cb)
	-- TODO: support multi-window
	vim.lsp.buf.document_symbol(on_list_hop(opts, cb))
end
M.hint_definition = function(opts, cb)
	vim.lsp.buf.definition(on_list_hop(opts, cb))
end
M.hint_declaration = function(opts, cb)
	vim.lsp.buf.declaration(on_list_hop(opts, cb))
end
M.hint_type_definition = function(opts, cb)
	vim.lsp.buf.type_definition(on_list_hop(opts, cb))
end
M.hint_references = function(opts, cb)
	vim.lsp.buf.references(nil, on_list_hop(opts, cb))
end
M.hint_implementation = function(opts, cb)
	vim.lsp.buf.implementation(on_list_hop(opts, cb))
end

return M
