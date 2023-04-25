local M = {}

local utils = require "tabulous.utils"
local manager = require "tabulous.manager"
local session = require "tabulous.sessions"

------------------------------------------------------------------------
--                             functions                              --
------------------------------------------------------------------------

function M.create_new_tab()
    if manager.initialized then
        manager.create_new_tab()
    else
        print("Tab 1 is already empty")
    end
end

function M.delete_buffer()
    manager.buffer_delete()
end

function M.delete_tab()
    manager.delete_tab()
end

function M.MaximizeWindowToggle()
    manager.MaximizeWindowToggle()
end

function M.load_session_from_file()
    if M.options.sessions_path then
        manager.tab_names_dict = session.load_session_from_file(M.options.sessions_path)
        manager.load_session()
    else
        print("Sessions path is not configured!")
    end
end

function M.save_session_to_file()
    if M.options.sessions_path then
        session.save_session_to_file(M.options.sessions_path, manager.tab_num_dict)
    else
        print("Sessions path is not configured!")
    end
end

------------------------------------------------------------------------
--                          auto commands                             --
------------------------------------------------------------------------

function M._auto_commands()
    local group = vim.api.nvim_create_augroup("tabulous", {})

    vim.api.nvim_create_autocmd({ "TabEnter" }, {
        group = group,
        callback = function()
            manager.active_tab = vim.fn.tabpagenr()
            manager.hide_other_buffers()
        end,
    })

    vim.api.nvim_create_autocmd({ "TabLeave" }, {
        group = group,
        callback = function() manager.last_active_tab = vim.fn.tabpagenr() end,
    })

    vim.api.nvim_create_autocmd({ "BufRead", "TermOpen" }, {
        group = group,
        callback = function()
            M.active_tab = vim.fn.tabpagenr()
            manager.tab_num_dict[M.active_tab] = utils.get_active_buffer_list()
            manager.initialized = true

            -- remove no name tab when a tab is loaded
            if #manager.tab_num_dict[M.active_tab] == 2 then
                local buf_num = manager.tab_num_dict[M.active_tab][1]
                local buf_name = vim.fn.bufname(buf_num)
                if #buf_name == 0 then
                    vim.cmd("bd " .. buf_num)
                    manager.tab_num_dict[M.active_tab] = utils.get_active_buffer_list()
                end
            end
        end,
    })
end

------------------------------------------------------------------------
--                           user commands                            --
------------------------------------------------------------------------

function M._user_commands()
    vim.api.nvim_create_user_command(
        "TabulousCreateNewTab",
        function() M.create_new_tab() end,
        { nargs = 0 }
    )

    vim.api.nvim_create_user_command(
        "TabulousDeleteTab",
        function() M.delete_tab() end,
        { nargs = 0 }
    )

    vim.api.nvim_create_user_command(
        "TabulousDeleteBuffer",
        function() M.delete_buffer() end,
        { nargs = 0 }
    )

    vim.api.nvim_create_user_command(
        "TabulousLoadSession",
        function() M.load_session_from_file() end,
        { nargs = 0 }
    )

    vim.api.nvim_create_user_command(
        "TabulousSaveSession",
        function() M.save_session_to_file() end,
        { nargs = 0 }
    )
end

function M.setup(options)
    if not options then
        M.options = {}
    else
        M.options = options
    end

    M._auto_commands()
    M._user_commands()
end

return M
