local M = {}

local hop = require("hop")
local get_window_context = require("hop.window").get_window_context
local override_opts = require("hop-extensions.utils").override_opts
local filter_window = require("hop-extensions.utils").filter_window
local hint_with = require("hop").hint_with
local hint_with_callback = require("hop").hint_with_callback
local jump_target = require("hop.jump_target")
local wrap_targets = require("hop-extensions.utils").wrap_targets
local on_list_hop = require("hop-extensions.utils").on_list_hop

M.ts = require("hop-extensions.ts")
M.lsp = require("hop-extensions.lsp")

M.hint_diagnostics = function(opts, diag_opts, popup)
	opts = override_opts(opts)
	local context = get_window_context( --[[ hint_opts --]])
	local diags = vim.diagnostic.get(diag_opts)

	local out = {}
	for _, diag in ipairs(diags) do
		filter_window(diag, context, out)
	end
	local targets = wrap_targets(vim.tbl_values(out), context)

	if popup ~= false then
		hint_with_callback(
			function()
				return targets
			end,
			opts,
			function(jt)
				if type(popup) == "table" then
					vim.diagnostic.open_float(popup)
				elseif type(popup) == "function" then
					popup(jt)
				else
					vim.diagnostic.open_float({ scope = "line" })
				end
			end
		)
	else
		hint_with(function()
			return targets
		end, opts)
	end
end

M.hint_quickfix = function(list, opts, cb)
	list = list or vim.fn.getqflist()
	on_list_hop(opts, cb)({ items = list })
end
M.hint_loclist = function(list, opts, cb)
	list = list or vim.fn.getloclist(0)
	on_list_hop(opts, cb)({ items = list })
end

return setmetatable(M, {
	__index = function(_, key)
		return hop[key] or M.ts[key] or M.lsp[key]
	end,
})
