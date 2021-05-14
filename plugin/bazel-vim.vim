let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

python3 << EOF
import sys
from os.path import normpath, join
import vim
plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'plugin'))
sys.path.insert(0, python_root_dir)
import bazel_vim
EOF

function! GoToBazelDefinition()
    python3 bazel_vim.find_definition()
endfunction

function! GoToBazelTarget()
  let current_file = expand("%:t")
  let pattern = "\\V\\<" . current_file . "\\>"
  exe "edit" findfile("BUILD", ".;")
  call search(pattern, "w", 0, 500)
endfunction

function! BazelGetCurrentBufTarget()
    let g:current_bazel_target = py3eval("bazel_vim.get_bazel_target()")
endfunction

function! RunBazel()
    :execute 'Bazel ' . g:bazel_command . ' ' . g:current_bazel_target
endfunction

function! RunBazelHere(command)
    :let g:bazel_command = a:command
    :call BazelGetCurrentBufTarget()
    :call RunBazel()
endfunction

function! PrintLabel()
    python3 bazel_vim.print_label()
endfunction

command! -nargs=0 PrintLabel call PrintLabel()
