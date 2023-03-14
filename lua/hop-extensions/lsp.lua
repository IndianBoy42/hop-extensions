local M = {}
-- local hop = require "hop"
local get_window_context = require("hop.window").get_window_context
local hint_with = require("hop").hint_with
local hint_with_callback = require("hop").hint_with_callback
local teutils = require("telescope.utils")

local wrap_targets = require("hop-extensions.utils").wrap_targets
local override_opts = require("hop-extensions.utils").override_opts
local filter_window = require("hop-extensions.utils").filter_window

local on_list_hop = function(opts, callback)
	return {
		on_list = require("hop-extensions.utils").on_list_hop(opts, callback),
	}
end

M.hint_symbols = function(opts, cb)
	-- TODO: support multi-window with workspace symbols
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
