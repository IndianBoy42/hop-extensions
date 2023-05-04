local M = {}
local window = require("hop.window")

local hutils = require("hop-extensions.utils")
local wrap_targets = hutils.wrap_targets
local override_opts = hutils.override_opts

local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

-- Fix indexing
local function treesitter_filter_window(opts, node, nodes_set, nodes_others, hop_to_start, hop_to_end)
	if hop_to_start == nil then
		hop_to_start = true
	end
	if hop_to_end == nil then
		hop_to_end = true
	end

	if hop_to_start then
		local line, column, _ = node:start()
		if
			not opts.filter_window(opts, {
				line = line,
				column = column + 1,
				window = 0,
				ts_node = node,
			}, nodes_set)
		then
			nodes_others[line .. column] = node
		end
	end
	if hop_to_end then
		local line, column, _ = node:end_()
		if
			not opts.filter_window(opts, {
				line = line,
				column = column + 1,
				window = 0,
				ts_node = node,
			}, nodes_set)
		then
			nodes_others[line .. column] = node
		end
	end
end
local function jump_if_none_visible(nodes_set, nodes_other, opts)
	if #nodes_set == 0 then
		if #nodes_other > 0 then
			local node = nodes_other[1]
			local line, column, _ = node:start()
			vim.api.nvim_win_set_cursor(0, { line, column })
		end
	end
end

local treesitter_targets = function(nodes, opts)
	local context = window.get_window_context(opts.multi_windows)
	local nodes_set = {}
	local nodes_other = {}
	if type(nodes) == "table" then
		for _, node in ipairs(nodes) do
			treesitter_filter_window(opts, node, nodes_set, nodes_other, opts.hop_to_start, opts.hop_to_end)
		end
	else
		for node in nodes do
			treesitter_filter_window(opts, node, nodes_set, nodes_other, opts.hop_to_start, opts.hop_to_end)
		end
	end
	return wrap_targets(vim.tbl_values(nodes_set))
end

M.hint_from_list_of_nodes = treesitter_targets

local recurse_nodes = require("nvim-treesitter.locals").recurse_local_nodes
local treesitter_locals = function(filter)
	if filter == nil then
		filter = function(_, _)
			return true
		end
	end
	if type(filter) == "table" then
		local list = filter
		filter = function(name, _)
			for _, f in ipairs(list) do
				if name == f then
					return true
				end
			end
			return false
		end
	end
	return function(opts)
		local locals = require("nvim-treesitter.locals")
		local local_nodes = locals.get_locals()
		local context = window.get_window_context(opts.multi_windows)

		-- Make sure the nodes are unique.
		local nodes_set = {}
		local nodes_other = {}
		for _, loc in ipairs(local_nodes) do
			recurse_nodes(loc, function(_, node, name, _)
				if filter(name, node) then
					treesitter_filter_window(opts, node, nodes_set, nodes_other, true, false)
				end
			end)
		end
		return wrap_targets(vim.tbl_values(nodes_set))
	end
end

local treesitter_queries = function(opts)
	opts = vim.tbl_extend("keep", opts or {}, {
		captures = nil,
		query = nil,
		queryfile = "textobjects",
		filter = function(_, _)
			return true
		end,
		root = nil,
		lang = nil,
		hop_to_start = true,
		hop_to_end = true,
	})
	if type(opts.filter) == "table" then
		local list = opts.filter
		opts.filter = function(name, _)
			for _, f in ipairs(list) do
				if name == f then
					return true
				end
			end
			return false
		end
	end
	return function(hint_opts)
		local queries = require("nvim-treesitter.query")
		local nodes_set = {}
		local nodes_other = {}

		if opts.query then
			local buf_lang = require("nvim-treesitter.parsers").get_buf_lang(0)
			vim.treesitter.query.set(buf_lang, "hop-extensions", opts.query)
			opts.queryfile = "hop-extensions"
		end
		if opts.captures then
			for _, match in ipairs(queries.get_capture_matches(0, opts.captures, opts.queryfile, opts.root, opts.lang)) do
				recurse_nodes(match, function(_, node, name, _)
					if opts.filter(name, node) then
						treesitter_filter_window(
							hint_opts,
							node,
							nodes_set,
							nodes_other,
							opts.hop_to_start,
							opts.hop_to_end
						)
					end
				end)
			end
		else
			for match in queries.iter_group_results(0, opts.queryfile, opts.root, opts.lang) do
				recurse_nodes(match, function(_, node, name, _)
					if opts.filter(name, node) then
						treesitter_filter_window(
							hint_opts,
							node,
							nodes_set,
							nodes_other,
							opts.hop_to_start,
							opts.hop_to_end
						)
					end
				end)
			end
		end

		return wrap_targets(vim.tbl_values(nodes_set))
	end
end
-- Treesitter hintings
function M.hint_locals(opts, filter)
	opts = override_opts(opts)
	opts.hint_with(treesitter_locals(filter), opts)
end
function M.hint_definitions(opts)
	M.hint_locals(opts, function(name)
		return name:sub(1, #"definition") == "definition"
	end)
end
function M.hint_scopes(opts)
	M.hint_locals(opts, function(name)
		return name:sub(1, #"scope") == "scope"
	end)
end
function M.hint_defnref(opts)
	M.hint_locals(opts, function(name)
		return name:sub(1, #"scope") ~= "scope"
	end)
end
function M.hint_references(opts)
	M.hint_locals(opts, function(name)
		return name:sub(1, #"reference") == "reference"
	end)
end
function M.hint_defnref_pattern(opts, pattern)
	if pattern == "<cword>" or pattern == "<cWORD>" then
		pattern = vim.fn.expand(pattern)
	end
	local bufnr = vim.api.nvim_get_current_buf()
	M.hint_locals(opts, function(name, node)
		if name:sub(1, #"scope") == "scope" then
			return false
		end
		local t = vim.treesitter.get_node_text(node, bufnr)
		if t == nil then
			return false
		end
		t = type(t) == "string" and t or t[1]
		if pattern == nil then
			return true
		end
		return string.match(t, pattern)
	end)
end
function M.hint_scopes_pattern(opts, pattern)
	if pattern == "<cword>" or pattern == "<cWORD>" then
		pattern = vim.fn.expand(pattern)
	end
	local bufnr = vim.api.nvim_get_current_buf()
	M.hint_locals(opts, function(name, node)
		if name:sub(1, #"scope") ~= "scope" then
			return false
		end
		local t = vim.treesitter.get_node_text(node, bufnr)
		if t == nil then
			return false
		end
		t = type(t) == "string" and t or t[1]
		if pattern == nil then
			return true
		end
		return string.match(t, pattern)
	end)
end
function M.hint_usages(opts)
	M.hint_defnref_pattern(opts, "<cword>")
	-- FIXME: doesn't work?
	-- local targets = treesitter_targets(
	-- 	require("nvim-treesitter.locals").find_usages(
	-- 		require("nvim-treesitter.ts_utils").get_node_at_cursor(),
	-- 		nil,
	-- 		vim.api.nvim_get_current_buf()
	-- 	),
	-- 	true,
	-- 	false
	-- )
	-- opts.hint_with(function()
	-- 	return targets
	-- end, override_opts(opts))
end
function M.hint_containing_scopes(opts)
	opts = override_opts(opts)
	opts.hint_with(function()
		return treesitter_targets(
			require("nvim-treesitter.locals").iter_scope_tree(
				require("nvim-treesitter.ts_utils").get_node_at_cursor(),
				vim.api.nvim_get_current_buf()
			),
			opts
		)
	end, opts)
end

function M.hint_from_queryfile(opts, ts_opts)
	ts_opts = ts_opts or {}
	if type(ts_opts) == "string" then
		-- if ends_with(captures, "outer") then
		-- end
		ts_opts = { queryfile = ts_opts }
	end
	opts = override_opts(opts)
	opts.hint_with(treesitter_queries(ts_opts), opts)
end
function M.hint_from_query(opts, ts_opts)
	ts_opts = ts_opts or {}
	if type(ts_opts) == "string" then
		-- if ends_with(captures, "outer") then
		-- end
		ts_opts = { query = ts_opts }
	end
	opts = override_opts(opts)
	opts.hint_with(treesitter_queries(ts_opts), opts)
end
function M.hint_textobjects(opts, ts_opts)
	ts_opts = ts_opts or { queryfile = "textobjects" }
	if type(ts_opts) == "string" then
		-- if ends_with(captures, "outer") then
		-- end
		ts_opts = { captures = ts_opts, queryfile = "textobjects" }
	end
	ts_opts.queryfile = "textobjects"
	ts_opts.filter = ts_opts.filter or { "outer", "inner" }
	opts = override_opts(opts)
	opts.hint_with(treesitter_queries(ts_opts), opts)
end

local function insert_parent_nodes(nodes, node)
	table.insert(nodes, node)
	local parent = node:parent()
	while parent do
		table.insert(nodes, parent)
		parent = parent:parent()
	end
end
local function get_parser(bufnr)
	local has_lang, lang = pcall(function()
		return require("nvim-treesitter.parsers").ft_to_lang(vim.bo.filetype)
	end)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, has_lang and lang or nil)
	local err
	if ok then
		return parser
	else
		err = parser
	end
	if string.find(vim.bo.filetype, "%.") then
		for ft in string.gmatch(vim.bo.filetype, "([^.]+)") do
			ok, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
			if ok then
				return parser
			end
		end
	end
	error(err)
end
local function ts_parents_from_cursor(opts)
	local injection = opts and opts.ignore_injections == false or false
	local parser = get_parser(0)
	local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))

	local node_id, nodes = nil, {}

	-- assume parser injection
	if injection then
		local node = vim.treesitter.get_node({ bufnr = 0, pos = { lnum - 1, col }, ignore_injections = false })
		if node ~= nil then
			node_id = node:id()
			insert_parent_nodes(nodes, node)
		end
	end

	-- ignore parser injection
	local trees = parser:parse()
	local root = trees[1]:root()
	local cursor_node = root:descendant_for_range(lnum - 1, col, lnum - 1)

	-- if assumed injection is absent, return current list of the nodes
	if injection and cursor_node:id() == node_id then
		return nodes
	end

	-- insert parent nodes of cursor_node
	insert_parent_nodes(nodes, cursor_node)
	return nodes
end

-- from treehopper
function M.hint_containing_nodes(opts)
	opts = override_opts(opts)
	opts.hint_with(function()
		local nodes = ts_parents_from_cursor(opts)
		return treesitter_targets(nodes, opts)
	end, opts)
end
function M.hint_sibling_nodes(opts)
	-- TODO: implement this
	-- local internal = require("iswap.internal")
	-- opts = override_opts(opts)
	-- opts.hint_with(function()
	-- 	local bufnr = vim.api.nvim_get_current_buf()
	-- 	local winid = vim.api.nvim_get_current_win()
	-- 	local parent = internal.get_list_node_at_cursor(winid, config)
	-- 	if not parent then
	-- 		err("did not find a satisfiable parent node", config.debug)
	-- 		return
	-- 	end
	-- end, opts)
end

M.select = setmetatable({}, {
	__index = function(t, k)
		return function(opts, ...)
			opts.callback = "select_ts_node"
			M[k](opts, ...)
		end
	end,
})

return M
