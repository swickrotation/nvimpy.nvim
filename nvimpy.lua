local M = {}

-- Get the Python terminal buffer
function M.get_python_term()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == 'terminal' and vim.fn.bufname(buf):match 'term://.*python' then
      return buf
    end
  end
  return nil
end

-- Open Python REPL if not found and send command
function M.send_to_python(cmd)
  local term_buf = M.get_python_term()
  local current_win = vim.api.nvim_get_current_win() -- Store current window

  -- Open terminal if missing
  if not term_buf then
    vim.cmd ':botright 10split | lcd %:p:h | terminal python3'
    vim.wait(100) -- Wait for terminal to initialize
    vim.cmd 'wincmd p' -- Switch back to editor
    term_buf = M.get_python_term()
  end

  if term_buf then
    vim.api.nvim_chan_send(vim.api.nvim_buf_get_var(term_buf, 'terminal_job_id'), cmd .. '\n')

    -- Scroll terminal to bottom
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == term_buf then
        vim.api.nvim_win_call(win, function()
          vim.cmd 'normal! G'
        end)
        break
      end
    end

    -- Restore focus to editor
    vim.api.nvim_set_current_win(current_win)
  else
    print 'Failed to open Python REPL!'
  end
end

-- Close the Python REPL if it exists
function M.close_python_repl()
  local term_buf = M.get_python_term()
  if term_buf then
    vim.api.nvim_buf_delete(term_buf, { force = true })
  end
end

-- Quit and close REPL if last normal buffer
function M.quit_with_repl(save)
  local normal_buffers = vim.tbl_count(vim.fn.filter(vim.api.nvim_list_bufs(), "v:val->getbufvar(v:val, '&buftype') == ''"))

  if normal_buffers <= 1 then
    M.close_python_repl()
  end

  if vim.fn.bufname '%' == '' then
    vim.cmd 'q!'
  else
    vim.cmd(save and 'wq' or 'q') -- Perform normal :wq or :q
  end
end

-- Command Overrides (No Display Change in UI)
vim.api.nvim_create_user_command('Q', function()
  M.quit_with_repl(false)
end, { desc = 'Quit neovim without saving' })
vim.api.nvim_create_user_command('Wq', function()
  M.quit_with_repl(true)
end, { desc = 'Save and quit neovim' })
vim.cmd 'cabbrev q Q'
vim.cmd 'cabbrev wq Wq'

-- Function to toggle the Python REPL while maintaining focus in the editor
function M.toggle_python_repl()
  local term_buf = M.get_python_term()
  local current_win = vim.api.nvim_get_current_win() -- Store the current window

  if term_buf then
    -- Check if the REPL is visible in any window
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == term_buf then
        vim.api.nvim_win_hide(win) -- Hide the REPL window
        return
      end
    end

    -- If the REPL buffer exists but is hidden, reopen it
    vim.cmd 'botright 10split'
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), term_buf)
    vim.cmd 'wincmd p' -- Switch back to editor
  else
    -- If no REPL buffer exists, create a new one
    vim.cmd ':botright 10split | lcd %:p:h | terminal python3'
    vim.wait(100) -- Wait for terminal to initialize
    vim.cmd 'wincmd p' -- Switch back to editor
  end
end

-- Keybinding to toggle the REPL while keeping focus in the editor
vim.keymap.set('n', '<leader>rp', function()
  M.toggle_python_repl()
end, { noremap = true, silent = true, desc = 'Toggle Python REPL' })

vim.keymap.set(
  'n',
  '<leader>rl',
  ':lua require("custom.core.nvimpy").send_to_python(vim.fn.getline("."))<CR>',
  { noremap = true, silent = true, desc = 'Send line to Python REPL' }
)

vim.keymap.set('v', '<leader>rb', function()
  -- Ensure Python REPL is open
  local term_buf = M.get_python_term()
  local current_win = vim.api.nvim_get_current_win() -- Store current window

  if not term_buf then
    vim.cmd ':botright 10split | lcd %:p:h | terminal python3'
    vim.wait(100) -- Wait for terminal to initialize
    vim.cmd 'wincmd p' -- Switch back to editor
    term_buf = M.get_python_term()
  end

  if term_buf then
    local selected_text = table.concat(vim.fn.getline("'<", "'>"), '\n')
    vim.api.nvim_chan_send(vim.api.nvim_buf_get_var(term_buf, 'terminal_job_id'), selected_text .. '\n')

    -- Scroll REPL to bottom
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == term_buf then
        vim.api.nvim_win_call(win, function()
          vim.cmd 'normal! G'
        end)
        break
      end
    end

    -- Restore focus to editor
    vim.api.nvim_set_current_win(current_win)
  else
    print 'Failed to open Python REPL!'
  end
end, { noremap = true, silent = true, desc = 'Send block to Python REPL' })

vim.keymap.set(
  'n',
  '<leader>rf',
  ':lua require("custom.core.nvimpy").send_to_python("exec(open(\\""..vim.fn.expand("%").."\\").read())")<CR>',
  { noremap = true, silent = true, desc = 'Run file in Python REPL' }
)

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true, desc = 'Quit terminal mode' })

return M
