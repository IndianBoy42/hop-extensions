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
M.hop = hop
M.hint_diagnostics = function(opts, diag_opts, popup)
	opts = override_opts(opts)
	local context = get_window_context( --[[ hint_opts --]])
	local diags = vim.diagnostic.get(0, diag_opts)

	local out = {}
	for _, diag in ipairs(diags) do
		diag.line = diag.lnum
		diag.column = diag.col + 1
		diag.window = 0
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
				require("hop").move_cursor_to(jt.window, jt.line + 1, jt.column - 1, opts.hint_offset, opts.direction)
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

-- TODO: can we implement pounce.nvim with this?
M.hint_fuzzy = function() end

M.hint_quickfix = function(list, opts, cb)
	list = list or vim.fn.getqflist()
	on_list_hop(opts, cb)({ items = list })
end
M.hint_loclist = function(list, opts, cb)
	list = list or vim.fn.getloclist(0)
	on_list_hop(opts, cb)({ items = list })
end

M.hint_patterns_from = function(opts, gen)
	if type(gen) == "table" then
		gen_opts = gen
		gen = function()
			if gen_opts.reg then
				return vim.fn.getreg(gen_opts.reg)
			elseif gen_opts.expand then
				return vim.fn.expand(gen_opts.expand)
			end
		end
	end
	M.hint_patterns(opts, gen())
end

return setmetatable(M, {
	__index = hop,
})
