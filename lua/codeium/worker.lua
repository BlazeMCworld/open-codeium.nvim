local M = {}

local output = ""
local handlers = {}
local worker = vim.fn.jobstart({
    "node",
    "index.js"
}, {
    cwd = vim.env.HOME .. "/.open-codeium",
    on_stdout = function(_, d)
        output = output .. table.concat(d, "\n")
        while true do
            local newline = output:find("\n")
            if newline == nil then return end
            data = output:sub(1, newline - 1)
            output = output:sub(newline + 1)
            local json = vim.json.decode(data)
            if json.error then
                vim.print(json.error)
                handlers[json.id] = nil
                return
            end
            vim.schedule(function()
                if handlers[json.id] then
                    handlers[json.id](json.data)
                end
            end)
        end
    end,
    on_stderr = function(_, d)
        vim.print(table.concat(d, "\n"))
    end
})

local requestId = 0
M.send = function(payload, handler)
    requestId = requestId + 1
    if requestId > 100 then
        requestId = 1
    end
    handlers[requestId] = handler
    vim.fn.chansend(worker, vim.json.encode({
        id = requestId,
        data = payload
    }) .. "\n")
end

return M;
