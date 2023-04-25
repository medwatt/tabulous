------------------------------------------------------------------------
--                             variables                              --
------------------------------------------------------------------------
local M = {}

M.tab_num_dict = {}   -- key is the tab number, and value is a list of buffer numbers
M.tab_names_dict = {} -- key is the tab number, and value is a list of buffer paths (used for saving a session)

M.last_active_tab_num = 1
M.initialized = false -- spcifies whether a second tab was created

------------------------------------------------------------------------
--                              imports                               --
------------------------------------------------------------------------
local utils = require "tabulous.utils"

------------------------------------------------------------------------
--                           implementation                           --
------------------------------------------------------------------------

function M.create_new_tab()
    -- On the creation of the second tab, the buffers of the first tab must
    -- first be saved
    if not M.initialized then
        table.insert(M.tab_num_dict, utils.get_active_buffer_list())
        M.initialized = true
    end

    -- Create a new tab and initialize it
    vim.cmd('tabnew')
    table.insert(M.tab_num_dict, {})
end

-- Deleting a tab also deletes the buffers it contains
function M.delete_tab()
    if #M.tab_num_dict > 1 then
        local current_tab = vim.fn.tabpagenr()
        local buffers = M.tab_num_dict[current_tab]

        table.remove(M.tab_num_dict, current_tab)
        vim.cmd("tabclose " .. current_tab)

        for _, buffer in ipairs(buffers) do
            vim.cmd("bdelete! " .. buffer)
        end

        M.last_active_tab_num = current_tab - 1
        M.hide_other_buffers()
    end
end

-- Hide the buffers of the last active tab and unhide those of the current active tab
function M.hide_other_buffers()
    local current_tab = vim.fn.tabpagenr()
    for tab, buffers in pairs(M.tab_num_dict) do
        if tab == M.last_active_tab_num then
            for _, buffer in ipairs(buffers) do
                vim.api.nvim_buf_set_option(buffer, 'buflisted', false)
            end
        elseif tab == current_tab then
            for _, buffer in ipairs(buffers) do
                vim.api.nvim_buf_set_option(buffer, 'buflisted', true)
            end
        end
    end
end

-- Deletes a buffer in a tab: this requires special handling since
-- the default behavior is to delete a tab when it has no windows.
-- We want to overide this behavior such that a tab is only deleted
-- when it contains no buffers (not windows)
function M.buffer_delete()
    -- There's only 1 tab: just call regular buffer delete
    if #M.tab_num_dict < 2 then
        vim.cmd("bdelete")

        -- There's more than one tab
    else
        local current_tab = vim.fn.tabpagenr()
        local buffers = M.tab_num_dict[current_tab]

        if buffers then
            local active_buffer = vim.api.nvim_get_current_buf()

            -- There's only 1 buffer: we must close the tab and delete the buffer
            -- Doing this automatically brings the tab before this one into focus
            -- Therefore, we need to call `hide_other_buffers` to unhide its buffers
            if #buffers == 1 then
                vim.cmd("tabclose " .. current_tab)
                vim.cmd("bdelete " .. active_buffer)
                table.remove(M.tab_num_dict, current_tab)
                M.hide_other_buffers()

                -- When there are more than one tabs, we need to switch to a tab
                -- other than the active one before deleting, otherwise vim will
                -- close the tab
            else
                -- Switch to the next buffer in the list
                for i, buffer in ipairs(buffers) do
                    if buffer == active_buffer then
                        if i == #buffers then
                            vim.cmd('bprevious')
                        else
                            vim.cmd('bnext')
                        end
                        break
                    end
                end
                vim.cmd('bdelete ' .. active_buffer)
                M.tab_num_dict[current_tab] = utils.get_active_buffer_list()
            end
        end
    end
end

-- Load session from file
function M.load_session()
    for i, buffers in ipairs(M.tab_names_dict) do
        if i == 1 then
            for _, buffer in ipairs(buffers) do
                vim.cmd("e " .. buffer)
            end
            M.initialized = true
        else
            M.create_new_tab()
            for _, buffer in ipairs(buffers) do
                vim.cmd("e " .. buffer)
            end
        end
    end
end

return M
