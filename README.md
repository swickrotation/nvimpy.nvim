# nvimpy.nvim
A set of functions and keymaps to make testing python code very simple from within the editing window. Only one buffer necessary, no tmux or vim-slime necessary.<br>
<br>
\<leader\>rp toggles the python instance.<br>
\<leader\>rf sends the whole file in normal mode.<br>
\<leader\>rl sends the selected line in normal mode.<br>
\<leader\>rb sends a selected block in visual mode.<br>
<br>
The editing window and the python window are navigable between the two of them with tmux commands. By default, the python window opens below the editing window. The windows are navigable between each other using tmux commands, i.e. you should have tmux-navigator installed- but it is not *strictly* necessary for this to work. Just have fun moving window to window without it.
