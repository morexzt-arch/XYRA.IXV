-- Scripts/utils/executor.lua
local executor = {}

-- Fungsi untuk mengeksekusi string kode Lua
function executor.run(code, scriptName)
    scriptName = scriptName or "remote_script"
    
    -- Metode 1: loadstring (Lua 5.1 / Luau)
    if type(loadstring) == "function" then
        local func, err = loadstring(code, scriptName)
        if func then return pcall(func) else return false, "loadstring error: " .. tostring(err) end
    end

    -- Metode 2: load (Lua 5.2+ / 5.4)
    if type(load) == "function" then
        local func, err = load(code, scriptName)
        if func then return pcall(func) else return false, "load error: " .. tostring(err) end
    end

    -- Metode 3: Fallback writeToLocal + dofile (jika tersedia)
    if type(writeToLocal) == "function" and type(dofile) == "function" then
        local tempName = scriptName .. "_temp.lua"
        writeToLocal(tempName, code)
        local ok, err = pcall(dofile, tempName)
        return ok, err
    end

    return false, "Tidak ada metode eksekusi yang tersedia (loadstring/load/dofile tidak ditemukan)."
end

return executor
