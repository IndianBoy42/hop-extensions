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
	hint_with(
		hint_with(jump_target.jump_targets_by_scanning_lines(jump_target.regex_by_searching(pat, true)), opts),
		opts
	)
end

return setmetatable(M, {
	__index = function(_, key)
		return hop[key] or M.ts[key] or M.lsp[key]
	end,
})
