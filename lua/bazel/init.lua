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
            return nil
        end
        workspace = vim.fn.fnamemodify(workspace, ":h");
    end
    return workspace
end

function M.get_workspace(path)
    return get_parent_path_with_file(path, 'WORKSPACE')
end

function M.is_bazel_workspace(path)
    return M.get_workspace(path) ~= nil
end

local function get_cache_file(path)
    return get_parent_path_with_file(path, 'DO_NOT_BUILD_HERE') .. '/DO_NOT_BUILD_HERE'
end

function M.is_bazel_cache(path)
    return get_parent_path_with_file(path, 'DO_NOT_BUILD_HERE') ~= nil
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

local function query(args, workspace, callback)
    local query_cmd = "timeout 10 bazel query " .. args ..  " --color no --curses no --noshow_progress"
    local out = {}
    local function collect_stdout(_, stdout)
        for _, line in pairs(stdout) do
            if line ~= "" then table.insert(out, line) end
        end
    end

    local function on_exit(_, success) if success == 0 then callback(out) else print("No results for: " .. query_cmd) end end
    vim.fn.jobstart(query_cmd, { cwd = workspace, on_stdout = collect_stdout, on_exit = on_exit })
end

local function call_with_bazel_targets(callback)
    local fname = vim.fn.expand('%:p')
    local workspace = M.get_workspace(fname)
    if workspace == nil then print("Not in a bazel workspace.") return end
    local fname_rel = fname:match(workspace .. "/(.*)")
    local function query_targets(fname_label)
        local file_label = fname_label[1]
        local file_package = file_label:match("(.*):")
        local function query_cmd(attr) return "attr(" .. attr .. "," .. file_label .. "," .. file_package .. ":*)" end
        query("'" .. query_cmd("srcs") .. " union " .. query_cmd("hdrs") .. "'", workspace, callback)
    end
    query(fname_rel, workspace, query_targets)
end

function M.call_with_bazel_target(callback)
    local function choice(targets)
        local n = vim.tbl_count(targets)
        if n == 0 then print("No bazel targets found for this file.") return end
        if n == 1 then callback(targets[1]) end
        if n > 1 then vim.ui.select(targets, { prompt = "Choose bazel target:"}, function(target) if target ~= nil then callback(target) end end) end
    end
    call_with_bazel_targets(choice)
end

function M.run_bazel()
    if vim.g.current_bazel_target == nil then print("Current bazel target not set.") return end

    if vim.g.bazel_win == nil or not vim.api.nvim_win_is_valid(vim.g.bazel_win) then
        vim.cmd("new")
        vim.g.bazel_win = vim.api.nvim_get_current_win()
    else
        vim.api.nvim_set_current_win(vim.g.bazel_win)
        vim.api.nvim_win_set_buf(vim.g.bazel_win, vim.api.nvim_create_buf(false, true))
    end
    vim.fn.termopen('bazel ' .. vim.g.bazel_command .. ' ' .. vim.g.current_bazel_target, { cwd = M.get_workspace() })
    vim.fn.feedkeys("G")
end

function M.run_bazel_here(command)
    M.call_with_bazel_target(function(target)
        vim.g.bazel_command = command
        vim.g.current_bazel_target = target
        M.run_bazel()
    end)
end

return M
