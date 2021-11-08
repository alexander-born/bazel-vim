# bazel-vim

### dependency
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
