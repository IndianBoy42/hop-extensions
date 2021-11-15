local M = {}
local hint_with = require("hop").hint_with
local window = require("hop.window")

local wrap_targets = require("hop-extensions.utils").wrap_targets
local override_opts = require("hop-extensions.utils").override_opts

local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

local function treesitter_filter_window(node, context, nodes_set)
	local line, col, start = node:start()
	if line <= context.bot_line and line >= context.top_line then
		nodes_set[start] = {
			line = line,
			column = col + 1,
			window = 0,
		}
	end
end

-- TODO: performance of these functions may not be optimal
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

local treesitter_queries = function(query, inners, outers, queryfile)
	queryfile = queryfile or "textobjects"
	if inners == nil then
		inners = true
	end
	if outers == nil then
		outers = true
	end
	return function(hint_opts)
		local context = window.get_window_context()
		local queries = require("nvim-treesitter.query")
		local tsutils = require("nvim-treesitter.utils")
		local nodes_set = {}
		-- utils.dump(queries.collect_group_results(0, "textobjects"))

		local function extract(match)
			for _, node in pairs(match) do
				if inners and node.outer then
					treesitter_filter_window(node.outer.node, context, nodes_set)
				end
				if outers and node.inner then
					treesitter_filter_window(node.inner.node, context, nodes_set)
				end
			end
		end

		if query == nil then
			for match in queries.iter_group_results(0, queryfile) do
				extract(match)
			end
		else
			for match in queries.iter_group_results(0, queryfile) do
				local insert = tsutils.get_at_path(match, query)
				if insert then
					extract(match)
				end
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
function M.hint_references(pattern, opts)
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

function M.hint_textobjects(query, opts)
	if type(query) == "string" then
		-- if ends_with(query, "outer") then
		-- end
		query = { query = query }
	end
	hint_with(
		treesitter_queries(
			query and query.query,
			query and query.inners,
			query and query.outers,
			query and query.queryfile
		),
		override_opts(opts)
	)
end
return M
