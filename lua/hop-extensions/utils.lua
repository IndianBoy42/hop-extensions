local M = {}
local jump_target = require("hop.jump_target")
-- Wrap all the given jump targets using manh_dist
local get_window_context = require("hop.window").get_window_context
M.wrap_targets = function(targets, contexts)
	-- contexts = contexts or get_window_context()
	-- local cursor_pos = contexts[1].contexts[1].cursor_pos
	-- local indir = {}
	-- for i, v in ipairs(targets) do
	-- 	indir[#indir + 1] = {
	-- 		index = i,
	-- 		score = -jump_target.manh_dist({ v.line, v.column }, cursor_pos),
	-- 	}
	-- end
	-- local indir = setmetatable({}, zero_jump_scores)
	return {
		jump_targets = targets,
		-- indirect_jump_targets = indir,
	}
end
-- Allows to override global options with user local overrides.
function M.override_opts(opts)
	local hopopts = require("hop").opts
	return setmetatable(opts or {}, {
		-- __index = function(_, key)
		--   return hopopts[key]
		-- end,
		__index = hopopts,
	})
end

function M.filter_window(node, contexts, nodes_set)
	if not node.line and node.lnum then
		node.line = node.lnum - 1 -- This comes from quickfix... just correct it
	end
	local line = node.line
	if not node.column and node.col then
		node.column = node.col
	end
	local column = node.column
	-- TODO: support multi window
	local context = contexts[1].contexts[1] -- Just the primary window
	if line > context.bot_line or line < context.top_line then
		return
	end
	if node.hwin and node.hwin ~= context.hwin then
		return
	end
	if node.bufnr and node.bufnr ~= contexts[1].hbuf then
		return
	end
	if node.filename then
		local bufnr = contexts[1].hbuf

		local name = vim.api.nvim_buf_get_name(bufnr)
		if name ~= node.filename then
			return
		end
	end

	-- nodes_set[line .. column] = {
	-- 	line = line,
	-- 	column = column,
	-- 	window = 0,
	-- }

	local n = {}
	for key, value in pairs(node) do
		n[key] = value
	end
	nodes_set[line .. column] = n
end

local hint_with = require("hop").hint_with
local hint_with_callback = require("hop").hint_with_callback
M.on_list_hop = function(opts, callback)
	opts = M.override_opts(opts)
	return function(list)
		local contexts = get_window_context( --[[ hint_opts --]])
		local items = list.items

		local out = {}
		for _, loc in ipairs(items) do
			M.filter_window(loc, contexts, out)
		end
		local targets = M.wrap_targets(vim.tbl_values(out), contexts)

		if callback then
			hint_with_callback(function()
				return targets
			end, opts, callback)
		else
			hint_with(function()
				return targets
			end, opts)
		end
	end
end
return M
