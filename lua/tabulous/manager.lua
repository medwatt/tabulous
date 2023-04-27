------------------------------------------------------------------------
--                             variables                              --
------------------------------------------------------------------------
local M = {}

M.tab_num_dict = {}   -- key is the tab number, and value is a list of buffer numbers
M.tab_names_dict = {} -- key is the tab number, and value is a list of buffer paths (used for saving a session)

M.active_tab = 1
M.last_active_tab = 1

M.initialized = false -- spcifies whether a second tab was created

------------------------------------------------------------------------
--                              imports                               --
------------------------------------------------------------------------
local utils = require "tabulous.utils"

------------------------------------------------------------------------
--                           create new tab                           --
------------------------------------------------------------------------
function M.create_new_tab()
    -- On the creation of the second tab, the buffers of the first tab must
    -- first be saved
    if not M.initialized then
        table.insert(M.tab_num_dict, utils.get_active_buffer_list())
        M.initialized = true
    end

    -- Create new tab, go to it, and initialize an entry for it in the table
    vim.cmd('tabnew')
    local active_buffer = vim.api.nvim_get_current_buf()
    table.insert(M.tab_num_dict, M.active_tab, { active_buffer })
    M.hide_other_buffers()
end

------------------------------------------------------------------------
--                         hide other buffers                         --
------------------------------------------------------------------------
function M.change_buffer_property(tab, property, state)
    for t, b in pairs(M.tab_num_dict) do
        if t == tab then
            for _, buffer in ipairs(b) do
                vim.api.nvim_buf_set_option(buffer, property, state)
            end
        end
    end
end

-- Hide all buffers except those in the active one
function M.hide_other_buffers()
    M.change_buffer_property(M.last_active_tab, "buflisted", false)
    M.change_buffer_property(M.active_tab, "buflisted", true)
    if M.active_tab < #M.tab_num_dict then
        M.change_buffer_property(M.active_tab + 1, "buflisted", false)
    end
end

------------------------------------------------------------------------
--                             delete tab                             --
------------------------------------------------------------------------
-- Deleting a tab also deletes the buffers it contains
function M.delete_tab()
    if #M.tab_num_dict > 1 then
        local buffers = M.tab_num_dict[M.active_tab]

        table.remove(M.tab_num_dict, M.active_tab)
        vim.cmd("tabclose " .. M.active_tab)

        for _, buffer in ipairs(buffers) do
            vim.cmd("bdelete! " .. buffer)
        end

        M.last_active_tab = M.active_tab - 1
    end
end

------------------------------------------------------------------------
--                           delete buffer                            --
------------------------------------------------------------------------
-- Delete a buffer in a tab: this requires special handling since
-- the default behavior is to delete a tab when it has no windows.
-- We want to overide this behavior such that a tab is only deleted
-- when it contains no buffers (not windows)
function M.buffer_delete(buf_num)
    -- There's only 1 tab: just call regular buffer delete
    if #M.tab_num_dict < 2 then
        vim.cmd("bdelete")

        -- There's more than one tab
    else
        local buffers = M.tab_num_dict[M.active_tab]

        if buffers then
            local active_buffer = buf_num or vim.api.nvim_get_current_buf()

            -- There's only 1 buffer: we must close the tab and delete the buffer
            -- Doing this automatically brings the tab before this one into focus
            -- Therefore, we need to call `hide_other_buffers` to unhide its buffers
            if #buffers == 1 then
                M.delete_tab()

                -- When there are more than one tabs, we need to switch to a buffer
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
                M.tab_num_dict[M.active_tab] = utils.get_active_buffer_list()
            end
        end
    end
end

------------------------------------------------------------------------
--                            load session                            --
------------------------------------------------------------------------
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
    -- do a final refresh for the last tab that didn't call `M.hide_other_buffers`
    M.hide_other_buffers()
end

------------------------------------------------------------------------
--                         move buffer to tab                         --
------------------------------------------------------------------------
function M.move_buffer_to_tab(t_orig, t_dest, buf_num)
    -- remove tab from the entry of the current tab
    utils.remove_item_from_list(M.tab_num_dict[t_orig], buf_num)

    -- add entry for item in destination tab
    if not M.tab_num_dict[t_dest] then
        table.insert(M.tab_num_dict, { buf_num })
    else
        table.insert(M.tab_num_dict[t_dest], #M.tab_num_dict[t_dest] + 1, buf_num)
    end
end

------------------------------------------------------------------------
--                          maximize toggle                           --
------------------------------------------------------------------------

local maximized_window_id = nil
local origin_window_id = nil
local origin_tab = nil
local destination_tab = nil
local moved_buffer = nil

function M.MaximizeWindowToggle()
    -- Only allow one window to be maximized at a time,
    -- otherwise we might start leaving them all over the place
    if not moved_buffer or M.active_tab == destination_tab then
        if vim.fn.winnr('$') > 1 then
            -- There are more than one window in this tab
            if maximized_window_id then
                vim.cmd('wincmd w')
                vim.fn.win_gotoid(maximized_window_id)
            else
                -- Get active tab and active buffer
                local current_tab = vim.fn.tabpagenr()
                local active_buffer = vim.api.nvim_get_current_buf()

                -- Save them so that the tab list can be returned to its
                -- original state after the tab is closed
                origin_window_id = vim.fn.win_getid()
                origin_tab = current_tab
                destination_tab = #M.tab_num_dict + 1
                moved_buffer = active_buffer

                -- Move the buffer from its parent tab to a new tab
                M.move_buffer_to_tab(origin_tab, destination_tab, active_buffer)

                vim.cmd('wincmd w')

                -- Create a new tab and hide/unhide the buffers
                vim.cmd("tab sp")
                M.hide_other_buffers()

                -- Go to the tab and make the recently moved buffer active
                vim.cmd("normal! " .. #M.tab_num_dict .. "gt")
                vim.cmd("buffer " .. active_buffer)

                -- Get the id of the window of the buffer
                maximized_window_id = vim.fn.win_getid()
            end
        else
            -- This is the only window in this tab
            if origin_window_id then
                M.move_buffer_to_tab(destination_tab, origin_tab, moved_buffer)

                -- Delete the tab and go back to the window
                M.delete_tab()
                vim.fn.win_gotoid(origin_window_id)

                -- Unset the variables
                maximized_window_id = nil
                origin_window_id = nil
                origin_tab = nil
                destination_tab = nil
                moved_buffer = nil
            end
        end
    else
        print(string.format("There's already a maximized tab (%d). Unmaximize that first!", destination_tab))
    end
end

return M
