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
			loc.window = 0
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

function M.replace_feedkeys(keys, opts)
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes(keys, true, false, true),
		-- folds are opened manually now, no need to pass t.
		-- n prevents langmap from interfering.
		opts or "n",
		true
	)
end

-- pos: (0,0)-indexed.
function M.cursor_set_keys(pos, before)
	if before then
		if pos[2] == 0 then
			pos[1] = pos[1] - 1
			-- pos2 is set to last columnt of previous line.
			-- # counts bytes, but win_set_cursor expects bytes, so all's good.
			pos[2] = #vim.api.nvim_buf_get_lines(0, pos[1], pos[1] + 1, false)[1]
		else
			pos[2] = pos[2] - 1
		end
	end

	return "<cmd>lua vim.api.nvim_win_set_cursor(0,{"
		-- +1, win_set_cursor starts at 1.
		.. pos[1] + 1
		.. ","
		-- -1 works for multibyte because of rounding, apparently.
		.. pos[2]
		.. "})"
		.. "<cr><cmd>:silent! foldopen!<cr>"
end

-- any for any mode.
-- other functions prefixed with eg. normal have to be in that mode, the
-- initial esc removes that need.
function M.any_select(b, e, opts)

	-- stylua: ignore
	M.replace_feedkeys(

		-- this esc -> movement sometimes leads to a slight flicker
		-- TODO: look into preventing that reliably.
		-- simple move -> <esc>v isn't possible, leaving insert moves the
		-- cursor, maybe do check for mode beforehand.
		"<esc>"
		.. M.cursor_set_keys(b)
		.. "v"
		.. (vim.o.selection == "exclusive" and
			M.cursor_set_keys(e) or
			-- set before
			M.cursor_set_keys(e, true))
		.. "o" )
end

M.select_ts_node = function(node, opts)
	node = node or require("nvim-treesitter.ts_utils").get_node_at_cursor()
	local start, end_ = node:start(), node:end_()
	M.any_select(start, end_, opts)
end

M.move_cursor_to = function(jt, opts)
	require("hop").move_cursor_to(jt.window, jt.line + 1, jt.column - 1, opts.hint_offset, opts.direction)
end
-- vim-visual-multi
M.feedkeys_at = function(keys, jt, opts)
	M.move_cursor_to(jt, opts)
	M.replace_feedkeys(keys, "m")
end
M.add_cursor_at = function(jt, opts)
	M.feedkeys_at("<Plug>(VM-Add-Cursor-At-Pos)", jt, opts)
end
M.select_ts_node_at = function(jt, opts)
	M.move_cursor_to(jt, opts)
	M.select_ts_node(nil, opts)
end

return M
