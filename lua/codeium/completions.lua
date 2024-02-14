local worker = require("codeium.worker")

local completion_namespace = vim.api.nvim_create_namespace("CodeiumCompletions")
local dispose_completion = nil
local accept_completion = function() end
local completion_id = 0
local next_completion = function() end
local prev_completion = function() end
local completion_shown = false
local which_completion = "0"

local function set_completion(buf, completions, cursor, line_suffix)
    if completions[which_completion] == nil then return end
    local lines = vim.split(completions[which_completion], "\n")

    local virt_lines = {}
    for _, line in ipairs(lines) do
        table.insert(virt_lines, { { line, "Comment" } })
    end
    virt_lines[#virt_lines] = { { virt_lines[#virt_lines][1][1] .. line_suffix, "Comment" } }

    vim.api.nvim_buf_set_extmark(buf, completion_namespace, cursor[1] - 1, cursor[2], {
        virt_text_pos = "overlay",
        virt_text = table.remove(virt_lines, 1),
        virt_lines = virt_lines,
        id = 1
    })
    completion_shown = true
    accept_completion = function()
        completion_id = completion_id + 1
        vim.api.nvim_buf_set_text(buf, cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2], lines)
        if #lines == 1 then
            vim.api.nvim_win_set_cursor(0, { cursor[1], cursor[2] + #lines[1] })
        else
            vim.api.nvim_win_set_cursor(0, { cursor[1] + #lines - 1, #(lines[#lines]) })
        end
        if dispose_completion ~= nil then
            dispose_completion()
            dispose_completion = nil
        end
    end
    dispose_completion = function()
        if vim.fn.bufloaded(buf) ~= 0 then
            vim.api.nvim_buf_del_extmark(buf, completion_namespace, 1)
        end
        completion_shown = false
        accept_completion = function() end
        next_completion = function() end
        prev_completion = function() end
    end

    next_completion = function()
        which_completion = tostring(tonumber(which_completion) + 1)
        if not completions[which_completion] then
            which_completion = "0"
        end
        set_completion(buf, completions, cursor, line_suffix)
    end

    prev_completion = function()
        which_completion = tostring(tonumber(which_completion) - 1)
        if not completions[which_completion] then
            local all = vim.tbl_keys(completions)
            which_completion = all[#all]
        end
        set_completion(buf, completions, cursor, line_suffix)
    end
end

local function complete()
    if dispose_completion ~= nil then
        dispose_completion()
        dispose_completion = nil
    end
    local timer = vim.loop.new_timer()
    local my_id = completion_id + 1
    completion_id = my_id

    timer:start(800, 0, vim.schedule_wrap(function()
        if vim.fn.mode() ~= "i" then return end
        local buf = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local prefix = table.concat(vim.api.nvim_buf_get_text(buf, 0, 0, cursor[1] - 1, cursor[2], {}), "\n")
        local suffix_lines = vim.api.nvim_buf_get_text(buf, cursor[1] - 1, cursor[2], -1, -1, {})
        local suffix = table.concat(suffix_lines, "\n")
        local file = vim.api.nvim_buf_get_name(buf)
        which_completion = "0"

        local completions = {}
        worker.send({
            type = "fetch_completions",
            file = file,
            prefix = prefix,
            suffix = suffix
        }, vim.schedule_wrap(function(raw)
            if my_id ~= completion_id or vim.fn.mode() ~= "i" then
                return
            end

            for k, v in pairs(raw) do
                if not completions[k] then
                    completions[k] = ""
                end
                completions[k] = completions[k] .. v
            end
            set_completion(buf, completions, cursor, suffix_lines[1])
        end))
    end))
    dispose_completion = function()
        timer:stop()
    end
end


vim.api.nvim_create_autocmd("InsertEnter", { callback = complete })

vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
        if dispose_completion ~= nil then
            dispose_completion()
            dispose_completion = nil
        end
    end
})

vim.api.nvim_create_autocmd("CursorMovedI", { callback = complete })

return {
    accept = function() accept_completion() end,
    dispose = function()
        if dispose_completion ~= nil then
            dispose_completion()
            dispose_completion = nil
        end
    end,
    next = function() next_completion() end,
    prev = function() prev_completion() end,
    is_shown = function() return completion_shown end
}
