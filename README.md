# features
 - go to definition insides bazel files
 - build/test/run bazel target of current buffer
 - jump to BUILD file of current buffer
 - start debugger of gtest at current cursor position (requires nvim-dap or vimspector)
 - get full bazel label at current cursor position inside BUILD file
 
 For auto completion of bazel targets checkout [cmp-bazel](https://github.com/alexander-born/cmp-bazel)

### dependencies
```lua
    use {'bazelbuild/vim-bazel'}
    use {'nvim-treesitter/nvim-treesitter'} -- needed for lua functions (debugging bazel gtests)
```


### vim functions:
```viml
BazelGetCurrentBufTarget()   " Get the bazel target of current buffer
GoToBazelTarget()            " Jumps to the BUILD file of current target
RunBazelHere(command)        " Runs the current bazel target with given command
RunBazel()                   " Repeats the last bazel run
GetLabel()                   " Returns bazel label of target in build file
```

### lua functions:
```lua
require('bazel').get_gtest_filter()
require('bazel').get_bazel_test_executable()
```

### example keybindings
This plugin adds no keybindings, you need to manually add keybindings. Example:
```lua
local map = vim.keymap.set
vim.api.nvim_create_autocmd("FileType", { pattern = "bzl", callback = function() map('n', 'gd', vim.fn.GoToBazelDefinition, { buffer = 0 }) end })
map('n', 'gbt',         vim.fn.GoToBazelTarget)
map('n', '<Leader>bl',  vim.fn.RunBazel)
map('n', '<Leader>bdt', require'config.bazel'.DebugThisTest)
map('n', '<Leader>bt',  function() vim.fn.RunBazelHere("test "  .. vim.g.bazel_config .. " -c opt") end)
map('n', '<Leader>bb',  function() vim.fn.RunBazelHere("build " .. vim.g.bazel_config .. " -c opt") end)
map('n', '<Leader>br',  function() vim.fn.RunBazelHere("run "   .. vim.g.bazel_config .. " -c opt") end)
map('n', '<Leader>bdb', function() vim.fn.RunBazelHere("build " .. vim.g.bazel_config .. " -c dbg") end)
function YankLabel()
    local label = vim.fn.GetLabel()
    print('yanking ' .. label .. ' to + and " register')
    vim.fn.setreg('+', label)
    vim.fn.setreg('"', label)
end
map('n', '<Leader>y', YankLabel)
```

```viml
autocmd FileType bzl nnoremap <buffer> gd :call GoToBazelDefinition()<CR>
nnoremap gbt :call GoToBazelTarget()<CR>
nnoremap <Leader>bt  :call RunBazelHere("test " . g:bazel_config . " -c opt" )<CR>
nnoremap <Leader>bb  :call RunBazelHere("build " . g:bazel_config . " -c opt")<CR>
nnoremap <Leader>bdb :call RunBazelHere("build " . g:bazel_config . " -c dbg")<CR>
nnoremap <Leader>bdt :lua  require'config.bazel'.DebugThisTest()<CR>
nnoremap <Leader>bl  :call RunBazel()<CR>
function! YankLabel()
    let label = GetLabel()
    echo "yanking " . label . " to + and \" register"
    call setreg('+', label)
    call setreg('"', label)
endfunction
nnoremap <Leader>y  :call YankLabel()<CR>

```

### debug (nvim-dap) of current bazel gtest
Add the following snippet to your config: (i.e. /lua/config/bazel.lua )

```lua
local function StartDebugger(program, args)
    require'dapui'.open()
    require'dap'.run({
        name = "Launch",
        type = "cppdbg",
        request = "launch",
        program = function() return program end,
        cwd = vim.fn.getcwd(),
        stopOnEntry = false,
        args = args,
        runInTerminal = false,
    })
end

function M.DebugThisTest()
    local program = require('bazel').get_bazel_test_executable()
    local args = {'--gtest_filter=' .. require('bazel').get_gtest_filter()}
    vim.cmd('new')
    local on_exit = function(_, code)
        if code == 0 then
            vim.cmd('bdelete')
            StartDebugger(program, args)
        end
    end
    vim.fn.termopen('bazel build ' .. vim.g.bazel_config .. ' -c dbg ' .. vim.g.current_bazel_target, {on_exit = on_exit})
end

return M
```

### debug (vimspector) of current bazel gtest

Add the following snippet to your config: (i.e. /lua/config/bazel.lua )

```lua
local function write_to_file(filename, lines)
    vim.cmd('e ' .. filename)
    vim.cmd('%delete')
    for _,line in pairs(lines) do
        vim.cmd("call append(line('$'), '" .. line .. "')")
    end
    vim.cmd('1d')
    vim.cmd('w')
    vim.cmd('e#')
end

local function create_cpp_vimspector_json_for_bazel_test()
    local test_filter = require('bazel').get_gtest_filter()
    local executable =  require('bazel').get_bazel_test_executable()
    local lines = {
        '{',
        '  "configurations": {',
        '    "GTest": {',
        '      "adapter": "vscode-cpptools",',
        '      "configuration": {',
        '        "request": "launch",',
        '        "program": "' .. executable .. '",',
        '        "args": ["--gtest_filter=\'\'' .. test_filter .. '\'\'"],',
        '        "stopOnEntry": false',
        '      }',
        '    }',
        '  }',
        '}'}
    write_to_file('.vimspector.json', lines)
end

local M = {}

function M.DebugThisTest()
    create_cpp_vimspector_json_for_bazel_test()
    vim.cmd('new')
    vim.cmd('call termopen("bazel build " . g:bazel_config . " -c dbg " . g:current_bazel_target, {"on_exit": "StartVimspector"})')
end

return M
```
