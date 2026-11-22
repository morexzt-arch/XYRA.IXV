
-- ==========================================
-- XYRA.IXV LOADER
-- GitHub Connection Test v1.0.0
-- Target: Growlauncher 7.0.39
-- ==========================================

local MANIFEST_URL =
    "https://raw.githubusercontent.com/morexzt-arch/XYRA.IXV/main/manifest.json"

local function showDialog(title, message)
    if type(sendDialog) == "function" then
        pcall(sendDialog, {
            title = title,
            message = message
        })
    elseif type(sendNotification) == "function" then
        pcall(sendNotification, title .. "\n" .. message)
    end
end

local function runConnectionTest()
    if type(fetch) ~= "function" then
        showDialog(
            "XYRA.IXV - Error",
            "Fungsi fetch() tidak tersedia."
        )
        return
    end

    local success, response, fetchError =
        pcall(fetch, MANIFEST_URL)

    if not success then
        showDialog(
            "XYRA.IXV - Error",
            "Fetch gagal dijalankan:\n" .. tostring(response)
        )
        return
    end

    if response == nil or response == "" then
        showDialog(
            "XYRA.IXV - Error",
            "Manifest tidak berhasil diambil.\n\n" ..
            tostring(fetchError or "Respons kosong.")
        )
        return
    end

    local body = tostring(response)

    showDialog(
        "XYRA.IXV - GitHub Test",
        "Koneksi berhasil menerima respons.\n" ..
        "Panjang data: " .. tostring(#body) ..
        " karakter\n\n" ..
        "Preview manifest:\n" ..
        string.sub(body, 1, 900)
    )
end

runConnectionTest()
