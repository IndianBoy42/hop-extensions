local M = {}

local hop = require("hop")

local get_window_context = require("hop.window").get_window_context
local override_opts = require("hop-extensions.utils").override_opts
local wrap_targets = require("hop-extensions.utils").wrap_targets
local on_list_hop = require("hop-extensions.utils").on_list_hop

M.ts = require("hop-extensions.ts")
M.lsp = require("hop-extensions.lsp")
M.hop = hop
M.hint_diagnostics = function(opts, diag_opts, popup)
	opts = override_opts(opts)
	local context = get_window_context(opts.multi_windows --[[ hint_opts --]])
	local diags = vim.diagnostic.get(0, diag_opts)

	local out = {}
	for _, diag in ipairs(diags) do
		diag.line = diag.lnum
		diag.column = diag.col + 1
		diag.window = 0
		opts.filter_window(opts, diag, out)
	end
	local targets = wrap_targets(vim.tbl_values(out), context)

	local callback = nil
	if popup ~= false then
		opts.callback = function(jt)
			require("hop").move_cursor_to(jt.window, jt.line + 1, jt.column - 1, opts.hint_offset, opts.direction)
			if type(popup) == "table" then
				vim.diagnostic.open_float(popup)
			elseif type(popup) == "function" then
				popup(jt)
			else
				local scope = type(popup) == "string" and popup or "line"
				vim.diagnostic.open_float({ scope = scope })
			end
		end
	end
	opts.hint_with(function()
		return targets
	end, opts)
end

-- TODO: can we implement pounce.nvim with this?
M.hint_fuzzy = function()
	local ok, fzy = pcall(require, "fuzzy_nvim")
	if not ok then
		return
	end
end

-- TODO: implement iswap and imove commands

M.hint_quickfix = function(list, opts, cb)
	list = list or vim.fn.getqflist()
	on_list_hop(opts, cb).on_list({ items = list })
end
M.hint_loclist = function(list, opts, cb)
	list = list or vim.fn.getloclist(0)
	on_list_hop(opts, cb).on_list({ items = list })
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
