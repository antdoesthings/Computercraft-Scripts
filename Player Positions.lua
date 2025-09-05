local pastebinID = "jdhdDNH9" -- Replace with your Pastebin ID
local scriptName = "playerPositions.lua" -- Name of this script

local function updateScript()
    local url = "https://pastebin.com/raw/" .. pastebinID
    local response = http.get(url)

    if response then
        local newCode = response.readAll()
        response.close()

        if fs.exists("temp_update.lua") then
            fs.delete("temp_update.lua")
        end

        local tempFile = fs.open("temp_update.lua", "w")
        if tempFile then
            tempFile.write(newCode)
            tempFile.close()
        else
            return
        end

        local startupFile = fs.open("startup.lua", "w")
        if startupFile then
            startupFile.write([[
if fs.exists("temp_update.lua") then
    fs.delete("]] .. scriptName .. [[")
    fs.move("temp_update.lua", "]] .. scriptName .. [[")
end
shell.run("]] .. scriptName .. [[")
            ]])
            startupFile.close()
        else
            return
        end

        os.reboot()
    else
        print("Failed to fetch update from Pastebin.")
    end
end

local function checkForUpdates()
    local url = "https://pastebin.com/raw/" .. pastebinID
    local response = http.get(url)

    if response then
        local newCode = response.readAll()
        response.close()

        local currentFile = fs.open(scriptName, "r")
        if currentFile then
            local currentCode = currentFile.readAll()
            currentFile.close()

            if newCode ~= currentCode then
                updateScript()
            end
        end
    else
        print("Failed to check for updates.")
    end
end

checkForUpdates()

-- Attach peripherals
local playerDetector = peripheral.find("playerDetector")
local monitor = peripheral.find("monitor")

if not playerDetector or not monitor then
    error("Player detector or monitor not found. Check your connections.")
end

-- Set up the monitor
monitor.setBackgroundColor(colors.black)
monitor.setTextScale(0.5) -- Adjust text scale for better readability
monitor.clear()
monitor.setCursorPos(1, 1)

-- Function to set monitor text color based on coordinate type
local function setColorForCoordinate(coordType)
    if coordType == "x" then
        monitor.setTextColor(colors.green)
    elseif coordType == "y" then
        monitor.setTextColor(colors.blue)
    elseif coordType == "z" then
        monitor.setTextColor(colors.red)
    else
        monitor.setTextColor(colors.white)
    end
end

-- Function to clean and capitalize dimension name
local function cleanDimensionName(dimension)
    local cleanName = dimension:gsub("minecraft:", "")
    return cleanName:sub(1, 1):upper() .. cleanName:sub(2)
end

-- Function to get text color based on dimension
local function getColorForDimension(dimension)
    if dimension == "Overworld" then
        return colors.green
    elseif dimension == "Nether" then
        return colors.red
    elseif dimension == "End" then
        return colors.yellow
    else
        return colors.white
    end
end

-- Function to display player positions
local function displayPlayerPositions()
    local width, height = monitor.getSize()
    local buffer = {}

    -- Center the title
    local title = "Player Positions"
    local xPos = math.floor((width - #title) / 2) + 1
    table.insert(buffer, {xPos, 1, colors.white, title})

    local players = playerDetector.getOnlinePlayers()

    if #players == 0 then
        table.insert(buffer, {1, 3, colors.white, "No players detected."})
    else
        for i, player in ipairs(players) do
            local data = playerDetector.getPlayerPos(player)
            if data then
                local x, y, z, dimension = data.x, data.y, data.z, data.dimension or "Unknown"
                local cleanDim = cleanDimensionName(dimension)

                table.insert(buffer, {1, 2 + i, colors.white, player .. ": "})
                table.insert(buffer, {1 + #player + 2, 2 + i, colors.green, tostring(x) .. " "})
                table.insert(buffer, {1 + #player + 3 + #tostring(x), 2 + i, colors.blue, tostring(y) .. " "})
                table.insert(buffer, {1 + #player + 4 + #tostring(x) + #tostring(y), 2 + i, colors.red, tostring(z) .. " "})
                table.insert(buffer, {1 + #player + 5 + #tostring(x) + #tostring(y) + #tostring(z), 2 + i, getColorForDimension(cleanDim), cleanDim})
            else
                table.insert(buffer, {1, 2 + i, colors.white, player .. ": Position not available"})
            end
        end
    end

    -- Update monitor without clearing
    for _, item in ipairs(buffer) do
        local x, y, color, text = unpack(item)
        monitor.setCursorPos(x, y)
        monitor.setTextColor(color)
        monitor.write(text)
    end
end

-- Main loop
while true do
    displayPlayerPositions()
end
