local M = {}
local hint_with = require("hop").hint_with
local window = require("hop.window")

local wrap_targets = require("hop-extensions.utils").wrap_targets
local override_opts = require("hop-extensions.utils").override_opts
local filter_window = require("hop-extensions.utils").filter_window

local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

-- Fix indexing
local function treesitter_filter_window(node, contexts, nodes_set, hop_to_start, hop_to_end)
	if hop_to_start == nil then
		hop_to_start = true
	end
	if hop_to_end == nil then
		hop_to_end = true
	end

	if hop_to_start then
		local line, column, _ = node:start()
		filter_window({
			line = line,
			column = column + 1,
			window = 0,
			ts_node = node,
		}, contexts, nodes_set)
	end
	if hop_to_end then
		local line, column, _ = node:end_()
		filter_window({
			line = line,
			column = column + 1,
			window = 0,
			ts_node = node,
		}, contexts, nodes_set)
	end
end

local treesitter_locals = function(filter, scope)
	if filter == nil then
		filter = function(_)
			return true
		end
	end
	return function(hint_opts)
		local locals = require("nvim-treesitter.locals")
		local local_nodes = locals.get_locals()
		local context = window.get_window_context()

		-- Make sure the nodes are unique.
		local nodes_set = {}
		for _, loc in ipairs(local_nodes) do
			if filter(loc) then
				locals.recurse_local_nodes(loc, function(_, node, _, match)
					treesitter_filter_window(node, context, nodes_set)
				end)
			end
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
			for _, filter in ipairs(list) do
				if filter then
					return true
				end
			end
			return false
		end
	end
	return function(hint_opts)
		local context = window.get_window_context()
		local queries = require("nvim-treesitter.query")
		local nodes_set = {}

		local function extract(match)
			if match.node then
				treesitter_filter_window(match.node, context, nodes_set, opts.hop_to_start, opts.hop_to_end)
			else
				if type(match) ~= "table" then
					return
				end
				for name, sub in pairs(match) do
					local ok, filtered = opts.filter(name, sub)
					if ok then
						filtered = filtered or sub
						extract(filtered)
					end
				end
			end
		end

		if opts.query then
			local buf_lang = require("nvim-treesitter.parsers").get_buf_lang(0)
			vim.treesitter.query.set_query(buf_lang, "hop-extensions", opts.query)
			opts.queryfile = "hop-extensions"
		end
		if opts.captures then
			for _, match in ipairs(queries.get_capture_matches(0, opts.captures, opts.queryfile, opts.root, opts.lang)) do
				extract(match)
			end
		else
			for match in queries.iter_group_results(0, opts.queryfile, opts.root, opts.lang) do
				extract(match)
			end
		end

		return wrap_targets(vim.tbl_values(nodes_set))
	end
end
-- Treesitter hintings
function M.hint_locals(filter, opts)
	hint_with(treesitter_locals(filter), override_opts(opts))
end
function M.hint_definitions(opts)
	M.hint_locals(function(loc)
		return loc.definition
	end, opts)
end
function M.hint_scopes(opts)
	M.hint_locals(function(loc)
		return loc.scope
	end, opts)
end
local ts_utils = require("nvim-treesitter.ts_utils")
function M.hint_ts_references(pattern, opts)
	if pattern == nil then
		M.hint_locals(function(loc)
			return loc.reference
		end, opts)
	else
		if pattern == "<cword>" or pattern == "<cWORD>" then
			pattern = vim.fn.expand(pattern)
		end
		M.hint_locals(function(loc)
			return loc.reference and string.match(ts_utils.get_node_text(loc.reference.node)[1], pattern)
				or loc.definition and string.match(ts_utils.get_node_text(loc.definition.node)[1], pattern)
		end, opts)
	end
end

function M.hint_from_queryfile(ts_opts, opts)
	ts_opts = ts_opts or {}
	if type(ts_opts) == "string" then
		-- if ends_with(captures, "outer") then
		-- end
		ts_opts = { queryfile = ts_opts }
	end
	hint_with(treesitter_queries(ts_opts), override_opts(opts))
end
function M.hint_from_query(ts_opts, opts)
	ts_opts = ts_opts or {}
	if type(ts_opts) == "string" then
		-- if ends_with(captures, "outer") then
		-- end
		ts_opts = { query = ts_opts }
	end
	hint_with(treesitter_queries(ts_opts), override_opts(opts))
end
function M.hint_textobjects(ts_opts, opts)
	ts_opts = ts_opts or {}
	if type(ts_opts) == "string" then
		-- if ends_with(captures, "outer") then
		-- end
		ts_opts = { captures = ts_opts }
	end
	ts_opts.queryfile = "textobjects"
	ts_opts.filter = ts_opts.filter or { "outer", "inner" }
	hint_with(treesitter_queries(ts_opts), override_opts(opts))
end
return M
