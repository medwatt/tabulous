local M = {}

-- Check if a buffer is active (visible and listed)
function M.is_active(buf_num)
    if not buf_num or buf_num < 1 then
        return false
    end
    local exists = vim.api.nvim_buf_is_valid(buf_num)
    return vim.bo[buf_num].buflisted and exists
end

-- Search for a value in a table
function M.is_present(value, tbl)
    for _, item in ipairs(tbl) do
        if item == value then
            return true
        end
    end
    return false
end

-- Remove nil values
function M.remove_nil_values(tabs)
    local new_list = {}
    for _, item in ipairs(tabs) do
        if item then
            table.insert(new_list, item)
        end
    end
    return new_list
end

-- Remove an item from a list
function M.remove_item_from_list(list, item)
    for i = 1, #list do
        if list[i] == item then
            table.remove(list, i)
            break
        end
    end
end

-- Get a list of all active buffers
function M.get_active_buffer_list()
    local buf_list = vim.api.nvim_list_bufs()
    local active_buffers = {}
    for _, buffer in ipairs(buf_list) do
        if M.is_active(buffer) then
            table.insert(active_buffers, buffer)
        end
    end
    return active_buffers
end

return M
