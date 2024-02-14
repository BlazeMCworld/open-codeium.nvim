local M = {}

local Popup = require("nui.popup")
local Layout = require("nui.layout")
local Input = require("nui.input")
local worker = require("codeium.worker")

local function layout_options()
    return {
        position = "50%",
        size = {
            width = math.floor(vim.o.columns * 0.8),
            height = math.floor(vim.o.lines * 0.8)
        }
    }
end

local prompt = ""
local chat_buffer = vim.api.nvim_create_buf(false, true)
M.show = function()
    vim.bo[chat_buffer].filetype = "markdown"
    local history = Popup({
        border = "single",
        bufnr = chat_buffer
    })
    local chatbox = Input({
        border = "single",
        enter = true
    }, {})

    local layout = Layout(
        layout_options(),
        Layout.Box({
            Layout.Box(history, { size = "80%" }),
            Layout.Box(chatbox, { size = "20%" })
        }, { dir = "col" })
    )

    local function scroll()
        local max_line = vim.api.nvim_buf_line_count(chat_buffer)
        vim.api.nvim_win_set_cursor(history.winid, { max_line, 0 })
    end

    layout:mount()
    scroll()

    chatbox:map("n", "<Esc>", function()
        layout:unmount()
    end)

    chatbox:map("i", "<CR>", vim.schedule_wrap(function()
        local value = table.concat(vim.api.nvim_buf_get_lines(chatbox.bufnr, 0, -1, false), "\n")
        vim.api.nvim_buf_set_lines(chatbox.bufnr, 0, -1, false, {})

        if value == "/clear" or value == "/new" then
            prompt = ""
            vim.api.nvim_buf_set_lines(chat_buffer, 0, -1, false, {})
            return
        end

        if #prompt == 0 then
            vim.api.nvim_buf_set_lines(chat_buffer, 0, -1, false,
                vim.split("# You:\n" .. value .. "\n\n# Codeium:\n", "\n"))
        else
            vim.api.nvim_buf_set_lines(chat_buffer, -1, -1, false,
                vim.split("\n# You:\n" .. value .. "\n\n# Codeium:\n", "\n"))
            prompt = prompt .. "\n\n"
        end

        prompt = prompt .. "User:\n" .. value
        scroll()
        local out = ""

        local send_prompt = prompt
        prompt = prompt .. "\n\nAssistant:\n"

        worker.send({
            type = "fetch_chat_message",
            prompt = send_prompt
        }, vim.schedule_wrap(function(chunk)
            local lines = vim.split(chunk, "\n")
            for i, line in ipairs(lines) do
                if i > 1 then
                    vim.api.nvim_buf_set_lines(chat_buffer, -1, -1, false, { "" })
                end
                local last_line = vim.api.nvim_buf_get_lines(chat_buffer, -2, -1, false)[1]
                vim.api.nvim_buf_set_text(chat_buffer, -1, #last_line, -1, #last_line, { line })
            end
            out = out .. chunk
            scroll()
        end))
    end))
end

return M
