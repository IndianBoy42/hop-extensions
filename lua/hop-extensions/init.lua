local M = {}

local hop = require("hop")
local override_opts = require("hop-extensions.utils").override_opts
local hint_with = require("hop").hint_with
local jump_target = require("hop.jump_target")

M.ts = require("hop-extensions.ts")
M.lsp = require("hop-extensions.lsp")

M.hint_cWORD = function(opts)
	opts = override_opts(opts)
	local pat = vim.fn.expand("<cWORD>")
	hint_with(jump_target.jump_targets_by_scanning_lines(jump_target.regex_by_searching(pat, true)), opts)
end

M.hint_cword = function(opts)
	opts = override_opts(opts)
	local pat = vim.fn.expand("<cword>")
	hint_with(jump_target.jump_targets_by_scanning_lines(jump_target.regex_by_searching(pat, true)), opts)
end

M.hint_vertical = function(opts)
	opts = override_opts(opts)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_col = cursor_pos[2]
	hint_with(
		jump_target.jump_targets_by_scanning_lines({
			oneshot = true,
			match = function()
				return cursor_col, cursor_col, false
				-- return cursor_col + 1, cursor_col + 1, false
			end,
		}),
		opts
	)
end

return setmetatable(M, {
	__index = function(_, key)
		return hop[key] or M.ts[key] or M.lsp[key]
	end,
})
