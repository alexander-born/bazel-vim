# features
 - go to definition insides bazel files
 - build/test/run bazel target of current buffer
 - jump to BUILD file of current buffer
 - start debugger of gtest at current cursor position (requires nvim-dap or vimspector)
 - get full bazel label at current cursor position inside BUILD file
 
 For auto completion of bazel targets checkout [cmp-bazel](https://github.com/alexander-born/cmp-bazel)

### dependencies
```lua
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
require('bazel').get_executable()
require('bazel').get_workspace()
```

### configuration
See configuration in [wiki](https://github.com/alexander-born/bazel-vim/wiki).
