local M = {}

function M.save_session_to_file(parent_dir, tab_num_dict)

    -- get input form the user
    local session_name = vim.fn.input('Enter name for session file: ')
    if #session_name < 1 then
        print('Error: Name cannot be empty')
        return
    end
    local session_path = parent_dir .. '/' .. session_name

    -- tab_num_dict contains a list of buffer numbers
    -- we must get the path of the buffers before saving
    local buffer_paths = {}
    for i, buffer_numbers in ipairs(tab_num_dict) do
        local paths = {}
        for _, buffer_number in ipairs(buffer_numbers) do
            local buffer_path = vim.fn.bufname(buffer_number)
            if buffer_path ~= '' then
                table.insert(paths, buffer_path)
            end
        end
        buffer_paths[i] = paths
    end

    -- writing to file
    local session_data = vim.fn.json_encode(buffer_paths)
    local file = io.open(session_path, "w")
    if file then
        file:write(session_data)
        file:close()
        print("Session saved to file: " .. session_path)
    else
        print("Could not open file: " .. session_path)
    end
end

function M.load_session_from_file(parent_dir)

    -- get input form the user
    local session_name = vim.fn.input('Enter name for session file: ')
    if #session_name < 1 then
        print('Error: Name cannot be empty')
        return
    end
    local session_path = parent_dir .. '/' .. session_name

    local tab_names_dict = {}
    local file = io.open(session_path, "r")
    if file then
        local contents = file:read("*all")
        tab_names_dict = vim.fn.json_decode(contents)
        file:close()
        print("Session loaded from file: " .. session_path)
    else
        print("Could not open file: " .. session_path)
    end
    return tab_names_dict
end

return M
