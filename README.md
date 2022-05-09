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
local function StartDebugger(_, code)
    if code == 0 then
        vim.cmd('bdelete')
        require'dapui'.open()
        require'dap'.run({
            name = "Launch",
            type = "cppdbg",
            request = "launch",
            program = function() return require('bazel').get_bazel_test_executable() end,
            cwd = vim.fn.getcwd(),
            stopOnEntry = false,
            args = {'--gtest_filter=' .. require('bazel').get_gtest_filter()},
            runInTerminal = false,
        })
    end
end

local M = {}

function M.DebugThisTest()
    vim.fn.BazelGetCurrentBufTarget()
    vim.cmd('new')
    vim.fn.termopen('bazel build ' .. vim.g.bazel_config .. ' -c dbg ' .. vim.g.current_bazel_target, {on_exit = StartDebugger })
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
