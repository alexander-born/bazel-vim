# Features
 - go to definition insides bazel files
 - build/test/run bazel target of current buffer
 - jump to BUILD file of current buffer
 - start debugger of gtest at current cursor position (requires nvim-dap or vimspector)
 - get full bazel label at current cursor position inside BUILD file
 
 For auto completion of bazel targets checkout [cmp-bazel](https://github.com/alexander-born/cmp-bazel)
 
### Installation
Use your favorite package mananger. Example packer:
```lua
use {'alexander-born/bazel-vim'}
```

### Dependencies
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
local bazel = require('bazel')

bazel.run(command, args, target, workspace, opts)
bazel.run_last()
bazel.run_here(command, args, opts)

bazel.get_workspace(path)
bazel.get_workspace_name(path)
bazel.is_bazel_workspace(path)
bazel.is_bazel_cache(path)
bazel.get_workspace_from_cache(path)
bazel.get_gtest_filter()

bazel.call_with_bazel_target(callback)
```

### Configuration
See configuration in [wiki](https://github.com/alexander-born/bazel-vim/wiki).
