# bazel-vim

### dependency
```
Plug 'bazelbuild/vim-bazel'
```

Adds the following:

### keybindings:
```
autocmd FileType bzl nnoremap <buffer> gd :call GoToBazelDefinition()<CR>
nnoremap gbt :call GoToBazelTarget()<CR>
```

### functions:
```
BazelGetCurrentBufTarget()
RunBazel()
RunBazelHere(command)
```

Special thanks to tim :)
