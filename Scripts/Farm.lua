-- ============================================================================
-- XYRA.IXV - BOREN CONSOLE REMOTE SCRIPT LOADER
-- Version: 1.1.0 | Target: Growlauncher
-- Catalog: GitHub manifest.json (manual updates)
--
-- IMPORTANT:
-- - Only add utility scripts you own or have permission to run.
-- - Remote Lua executes with the permissions of the Growlauncher runtime.
-- - Review each script in GitHub before pressing RUN.
-- ============================================================================

local XYRA = {
    name = "XYRA.IXV",
    version = "1.1.0",
    repo = "https://raw.githubusercontent.com/morexzt-arch/XYRA.IXV/main/",
    manifestPath = "manifest.json",
    state = {
        tab = 1,
        minimized = false,
        busy = false,
        manifest = nil,
        scripts = {},
        selected = 0,
        detail = nil,
        logs = {},
        status = "READY",
        lastError = "",
        loadedScript = nil
    }
}

local S = XYRA.state

local function log(message)
    local line = os and os.date and os.date("%H:%M:%S") or "--:--:--"
    table.insert(S.logs, 1, "[" .. line .. "] " .. tostring(message))
    while #S.logs > 80 do table.remove(S.logs) end
    if type(LogToConsole) == "function" then
        pcall(LogToConsole, "`6[XYRA.IXV]`0 " .. tostring(message))
    end
end

local function notify(title, message)
    if type(sendDialog) == "function" then
        pcall(sendDialog, { title = title, message = message })
    elseif type(sendNotification) == "function" then
        pcall(sendNotification, title .. "\n" .. message)
    else
        log(title .. ": " .. message)
    end
end

local function safeFetch(url)
    if type(fetch) ~= "function" then
        return nil, "Growlauncher fetch() tidak tersedia."
    end

    local ok, body, fetchErr = pcall(fetch, url)
    if not ok then return nil, tostring(body) end
    if type(body) ~= "string" or body == "" then
        return nil, tostring(fetchErr or "Respons kosong dari server.")
    end
    return body, nil
end

local function getJson()
    if type(require) ~= "function" then
        return nil, "require() tidak tersedia untuk memuat modul JSON."
    end
    local ok, module = pcall(require, "json")
    if not ok or type(module) ~= "table" or type(module.decode) ~= "function" then
        return nil, "Modul json atau fungsi json:decode() tidak tersedia."
    end
    return module, nil
end

local function validateManifest(data)
    if type(data) ~= "table" then
        return false, "Manifest harus berupa object JSON."
    end
    if type(data.scripts) ~= "table" then
        return false, "Field 'scripts' tidak ditemukan atau bukan array."
    end

    local clean = {}
    local seen = {}

    for _, item in ipairs(data.scripts) do
        if type(item) == "table"
            and type(item.id) == "string"
            and type(item.name) == "string"
            and type(item.file) == "string"
            and item.enabled == true then

            local safePath = item.file
            local safe = not safePath:find("..", 1, true)
                and not safePath:find("^/")
                and not safePath:find("://", 1, true)
                and safePath:match("^[%w_/%-%.]+%.lua$") ~= nil

            -- Keep this loader limited to ordinary, non-gambling utilities.
            local metadata = (item.id .. " " .. item.name .. " " ..
                tostring(item.category or "") .. " " .. safePath):lower()
            local restricted = metadata:find("casino", 1, true)
                or metadata:find("blackjack", 1, true)
                or metadata:find("gambling", 1, true)
                or metadata:find("betting", 1, true)
                or metadata:find("roulette", 1, true)
                or metadata:find("slot", 1, true)
                or metadata:find("wager", 1, true)
                or metadata:find("
bj", 1, true)

            if safe and not restricted and not seen[item.id] then
                seen[item.id] = true
                table.insert(clean, item)
            end
        end
    end

    return true, clean
end

local function refreshCatalog()
    if S.busy then return end
    S.busy = true
    S.status = "FETCHING"
    log("Mengambil manifest dari GitHub...")

    local body, fetchErr = safeFetch(XYRA.repo .. XYRA.manifestPath)
    if not body then
        S.status = "ERROR"
        S.lastError = fetchErr
        S.busy = false
        log("Manifest gagal diambil: " .. fetchErr)
        notify("XYRA.IXV - Fetch Error", fetchErr)
        return
    end

    local json, jsonErr = getJson()
    if not json then
        S.status = "ERROR"
        S.lastError = jsonErr
        S.busy = false
        log(jsonErr)
        notify("XYRA.IXV - JSON Error", jsonErr)
        return
    end

    local ok, decoded = pcall(function()
        return json:decode(body)
    end)

    if not ok then
        S.status = "ERROR"
        S.lastError = "JSON tidak valid: " .. tostring(decoded)
        S.busy = false
        log(S.lastError)
        notify("XYRA.IXV - Manifest Error", S.lastError)
        return
    end

    local valid, result = validateManifest(decoded)
    if not valid then
        S.status = "ERROR"
        S.lastError = result
        S.busy = false
        log(result)
        notify("XYRA.IXV - Manifest Error", result)
        return
    end

    S.manifest = decoded
    S.scripts = result
    S.selected = (#S.scripts > 0) and 1 or 0
    S.detail = S.scripts[S.selected]
    S.status = "ONLINE"
    S.lastError = ""
    S.busy = false

    log("Katalog diperbarui: " .. tostring(#S.scripts) .. " script aktif.")
end

local function selectScript(index)
    local item = S.scripts[index]
    if not item then return end
    S.selected = index
    S.detail = item
    S.tab = 2
    log("Dipilih: " .. tostring(item.name))
end

local function runSelected()
    local item = S.detail
    if not item then
        notify("XYRA.IXV", "Pilih script terlebih dahulu.")
        return
    end

    -- Construct the URL only from a validated relative path in the manifest.
    local sourceUrl = XYRA.repo .. item.file
    log("Mengambil sumber: " .. item.name)

    local source, fetchErr = safeFetch(sourceUrl)
    if not source then
        S.status = "ERROR"
        S.lastError = fetchErr
        log("Script gagal diambil: " .. fetchErr)
        notify("XYRA.IXV - Script Fetch Error", fetchErr)
        return
    end

    -- loadstring/load are runtime-dependent and not guaranteed by the
    -- documented Growlauncher API. Fail clearly if neither exists.
    local compiler = loadstring or load
    if type(compiler) ~= "function" then
        S.status = "READY"
        local message = "Runtime ini tidak menyediakan loadstring() atau load(). " ..
            "Sumber berhasil diambil, tetapi tidak dapat dieksekusi dari loader."
        log(message)
        notify("XYRA.IXV - Runtime Tidak Mendukung", message)
        return
    end

    local chunk, compileErr = compiler(source, "@XYRA/" .. item.file)
    if type(chunk) ~= "function" then
        S.status = "ERROR"
        S.lastError = tostring(compileErr or "Kompilasi Lua gagal.")
        log("Compile error: " .. S.lastError)
        notify("XYRA.IXV - Compile Error", S.lastError)
        return
    end

    log("Menjalankan: " .. item.name)
    local ok, runtimeErr = pcall(chunk)
    if not ok then
        S.status = "ERROR"
        S.lastError = tostring(runtimeErr)
        log("Runtime error: " .. S.lastError)
        notify("XYRA.IXV - Runtime Error", S.lastError)
        return
    end

    S.status = "ONLINE"
    S.loadedScript = item.name
    log("Selesai memanggil script: " .. item.name)
    notify("XYRA.IXV", item.name .. " berhasil dipanggil.")
end

local function text(value)
    if ImGui and ImGui.Text then ImGui.Text(tostring(value or "")) end
end

local function button(label)
    if ImGui and ImGui.Button then
        local ok, clicked = pcall(ImGui.Button, label)
        return ok and clicked == true
    end
    return false
end

local function drawLogs()
    text("CONSOLE ACTIVITY")
    if ImGui.BeginChild then
        local ok, visible = pcall(ImGui.BeginChild, "##xyra_logs", ImVec2 and ImVec2(0, 230) or nil, true)
        if ok and visible then
            if #S.logs == 0 then
                if ImGui.TextDisabled then ImGui.TextDisabled("Belum ada aktivitas.") end
            else
                for i = 1, #S.logs do
                    if ImGui.TextUnformatted then
                        ImGui.TextUnformatted(S.logs[i])
                    else
                        text(S.logs[i])
                    end
                end
            end
        end
        if ok then pcall(ImGui.EndChild) end
    else
        for i = 1, math.min(#S.logs, 15) do text(S.logs[i]) end
    end
end

local function drawCatalog()
    text("AVAILABLE SCRIPTS")
    text("Repository: morexzt-arch / XYRA.IXV")
    text(" ")

    if #S.scripts == 0 then
        text("Belum ada script aktif di manifest.")
        text("Tekan REFRESH untuk mengambil katalog.")
        return
    end

    for i, item in ipairs(S.scripts) do
        local prefix = (i == S.selected) and "> " or "  "
        if button(prefix .. tostring(item.name) .. "##xyra_script_" .. i) then
            selectScript(i)
        end
        if ImGui and ImGui.SameLine then ImGui.SameLine() end
        text(tostring(item.category or "Utility") .. " | v" .. tostring(item.version or "1.0.0"))
    end
end

local function drawDetails()
    local item = S.detail
    text("SCRIPT DETAILS")
    if not item then
        text("Belum ada script dipilih.")
        return
    end

    text("Name: " .. tostring(item.name))
    text("ID: " .. tostring(item.id))
    text("Category: " .. tostring(item.category or "Utility"))
    text("Version: " .. tostring(item.version or "N/A"))
    text("Description:")
    text(tostring(item.description or "Tidak ada deskripsi."))
    text("File: " .. tostring(item.file))
    text(" ")
    text("Periksa isi file di GitHub sebelum menjalankan.")
    if button("RUN SELECTED SCRIPT##xyra_run") then
        runSelected()
    end
    if ImGui and ImGui.SameLine then ImGui.SameLine() end
    if button("BACK TO CATALOG##xyra_back") then
        S.tab = 1
    end
end

function onDrawImGui()
    if not ImGui or not ImGui.Begin then return end

    if S.minimized then
        local miniOpen = ImGui.Begin("XYRA.IXV - MINI HUD##xyra_mini")
        if miniOpen then
            text("BOREN CONSOLE | " .. S.status)
            if ImGui.SameLine then ImGui.SameLine() end
            if button("EXPAND##xyra_expand") then S.minimized = false end
        end
        ImGui.End()
        return
    end

    if ImGui.SetNextWindowSize and ImVec2 then
        pcall(ImGui.SetNextWindowSize, ImVec2(620, 430),
            (ImGui.Cond and ImGui.Cond.FirstUseEver) or 4)
    end

    local open = ImGui.Begin("XYRA.IXV - BOREN CONSOLE##xyra_main")
    if open then
        text("STATUS: " .. S.status ..
            " | VERSION: " .. tostring((S.manifest and S.manifest.version) or XYRA.version))
        if ImGui.SameLine then ImGui.SameLine() end
        if button("MINIMIZE##xyra_min") then S.minimized = true end

        if ImGui.Separator then ImGui.Separator() end

        local tabs = { "CATALOG", "DETAILS", "CONSOLE" }
        for i, label in ipairs(tabs) do
            local shown = (S.tab == i) and ("[" .. label .. "]") or label
            if button(shown .. "##xyra_tab_" .. i) then S.tab = i end
            if i < #tabs and ImGui.SameLine then ImGui.SameLine() end
        end

        if ImGui.Separator then ImGui.Separator() end

        if S.tab == 1 then
            drawCatalog()
        elseif S.tab == 2 then
            drawDetails()
        else
            drawLogs()
        end

        if ImGui.Separator then ImGui.Separator() end
        if button("REFRESH MANIFEST##xyra_refresh") then refreshCatalog() end
        if ImGui.SameLine then ImGui.SameLine() end
        if button("OPEN DETAILS##xyra_details") then
            if S.selected > 0 then selectScript(S.selected) end
        end
    end
    ImGui.End()
end

-- Register the documented ImGui draw hook.
if type(addHook) == "function" and type(applyHook) == "function" then
    addHook(onDrawImGui, "ondrawimgui")
    applyHook()
    log("Boren Console hook terdaftar.")
else
    log("Hook ImGui tidak tersedia; periksa versi Growlauncher.")
end

refreshCatalog()
log("XYRA.IXV Boren Loader v" .. XYRA.version .. " siap.")
