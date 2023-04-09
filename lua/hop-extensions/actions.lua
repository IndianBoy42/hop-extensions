local M = {}
local hop = require("hop")
local ts_utils = require("nvim-treesitter.ts_utils")
local meta_M = {}

function M.replace_feedkeys(keys, opts)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), opts or "n", true)
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

M.select_ts_node_at = function(node, opts)
	node = node or ts_utils.get_node_at_cursor()
	ts_utils.update_selection(0, node, opts.select_mode)
	-- local start, end_ = node:start(), node:end_()
	-- M.any_select(start, end_, opts)
end

M.move_cursor_to = function(jt, opts)
	hop.move_cursor_to(jt.window, jt.line + 1, jt.column - 1, opts.hint_offset, opts.direction)
end

--  ╭──────────────────────────────────────────────────────────╮
--  │ NOTE: CALLBACKS:                                         │
--  ╰──────────────────────────────────────────────────────────╯

local chain_meta = {
	__call = function(t, jt)
		for _, e in ipairs(t) do
			e[1](jt, e[2])
		end
	end,
	__index = function(t, fn)
		return function(opts)
			table.insert(t, { fn, opts })
			return t
		end
	end,
}
local chainable = function()
	return setmetatable({}, chain_meta)
end

M.move_cursor = function(opts)
	return function(jt)
		M.move_cursor_to(jt, opts)
	end
end
-- vim-visual-multi
M.feedkeys = function(opts)
	return function(jt)
		M.move_cursor_to(jt, opts)
		M.replace_feedkeys(opts.feedkeys, "m")
	end
end
M.add_cursor = function(opts)
	return function(jt)
		opts.feedkeys = "<Plug>(VM-Add-Cursor-At-Pos)"
		M.feedkeys_at(jt, opts)
	end
end
M.select_ts_node = function(opts)
	return function(jt)
		if not jt.ts_node then
			M.move_cursor_to(jt, opts)
		end
		M.select_ts_node_at(jt.ts_node, opts)
	end
end
M.swap_ts_node_with = function(opts)
	return function(jt)
		-- TODO:
		local from_node = jt.from_node or ts_utils.get_node_at_cursor()
		if not jt.ts_node then
			M.move_cursor_to(jt, opts)
		end
		ts_utils.swap_nodes(from_node, jt.ts_node or ts_utils.get_node_at_cursor())
	end
end

meta_M.__index = function(_, k)
	if k == "chainable" then
		return chainable()
	end
end

return setmetatable(M, meta_M)
