local queries = require('nvim-treesitter.query')
local ts_utils = require('nvim-treesitter.ts_utils')

local M = {}

local function contains(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

local function is_gtest(test_type)
    local gtest_types = {'TEST', 'TEST_F', 'TEST_P', 'TYPED_TEST_P', 'TYPED_TEST'}
    return contains(gtest_types, test_type)
end

local function get_current_gtest(bufnr)
    local node_at_cursor = ts_utils.get_node_at_cursor()
    local gtests = queries.get_capture_matches(bufnr, '@gtest', 'bazel')
    for _, m in pairs(gtests) do
        if ts_utils.is_parent(m.node, node_at_cursor) or m.node == node_at_cursor then
            return m.node
        end
    end
    error('Cursor not in a gtest')
end

local function get_text_of_capture(bufnr, query, root)
    local node = queries.get_capture_matches(bufnr, query, 'bazel', root)[1].node
    return vim.treesitter.query.get_node_text(node, 0)
end

local function get_gtest_info()
    local bufnr = vim.fn.bufnr()
    local gtest_node = get_current_gtest(bufnr)
    local test_type = get_text_of_capture(bufnr, '@test_type', gtest_node)
    if not is_gtest(test_type) then return error('Cursor not in a gtest') end
    return {test_type  = test_type,
            test_suite = get_text_of_capture(bufnr, '@test_suite', gtest_node),
            test_name  = get_text_of_capture(bufnr, '@test_name', gtest_node)}
end

local function get_parent_path_with_file(path, file)
    local initial_path = path or vim.fn.expand(('#%d:p:h'):format(vim.fn.bufnr()))
    local workspace = initial_path
    while(1)
    do
        if(vim.fn.filereadable(workspace .. '/' .. file) == 1) then
            break
        end
        if(workspace == '/') then
            return initial_path
        end
        workspace = vim.fn.fnamemodify(workspace, ":h");
    end
    return workspace
end

function M.get_workspace(path)
    return get_parent_path_with_file(path, 'WORKSPACE')
end

function M.is_bazel_workspace(path)
    return vim.fn.filereadable(M.get_workspace(path) .. '/WORKSPACE') == 1
end

local function get_cache_file(path)
    return get_parent_path_with_file(path, 'DO_NOT_BUILD_HERE') .. '/DO_NOT_BUILD_HERE'
end

function M.is_bazel_cache(path)
    return vim.fn.filereadable(get_cache_file(path)) == 1
end

function M.get_workspace_from_cache(path)
    return vim.fn.system('cat ' .. get_cache_file(path))
end

function M.get_gtest_filter()
    local test_info = get_gtest_info()
    local test_filter = test_info.test_suite .. '.' .. test_info.test_name
    if test_info.test_type == 'TEST_P' then test_filter = '*' .. test_filter .. '*' end
    if contains({'TYPED_TEST', 'TYPED_TEST_P'}, test_info.test_type) then test_filter = '*' .. test_info.test_suite .. '*' .. test_info.test_name end
    return test_filter
end

function M.get_executable()
    vim.fn.BazelGetCurrentBufTarget()
    local executable = vim.g.current_bazel_target:gsub(':', '/')
    return M.get_workspace() .. '/' .. executable:gsub('//', 'bazel-bin/')

end

return M
