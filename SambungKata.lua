-- ==========================================
-- Sambung Kata Auto Win Script
-- Compatible: Delta Executor / Fluxus / etc
-- ==========================================

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- KAMUS KATA LENGKAP A-Z
-- ==========================================
local KamusKata = {
    ["a"] = {
        "apel","angin","awan","api","ayam","alam","air","akar","anak","asap",
        "awal","akhir","asin","atap","asing","arah","arus","asli","adem","adik",
        "amplop","andal","angsa","anjing","antar","arang","arif","atlas","awas","axle"
    },
    ["b"] = {
        "batu","bulan","bumi","bunga","biru","besar","baik","burung","bola","bantal",
        "bakso","bambu","batas","becak","bekal","benar","benci","bensin","berita","berkat",
        "beton","bidang","bijak","bilik","bintang","bocah","bogor","bonus","botol","budak"
    },
    ["c"] = {
        "cahaya","cinta","cuaca","celana","cepat","cerdas","cicak","coklat","cantik","cabai",
        "calon","cambuk","campak","candu","capit","cebok","cedal","celah","cemara","cemas",
        "cendol","cerah","cerai","cerita","cerna","cermin","cetok","cikan","cincin","cipta"
    },
    ["d"] = {
        "daun","dunia","diam","dalam","dekat","desa","dingin","dinding","domba","danau",
        "dadak","daftar","daging","dahak","damai","dampar","dangkal","dapur","darat","dasar",
        "dawai","debu","delman","delta","dempel","dendeng","depan","dermaga","desak","detik"
    },
    ["e"] = {
        "elang","emas","enak","embun","emosi","energi","ekor","empat","es","esok",
        "ember","embus","empang","empal","encer","endap","enggan","entah","erak","erang"
    },
    ["f"] = {
        "foto","fajar","fakta","fantasi","flora","fauna","fisik","fungsi","favorit","festival",
        "fabrik","fadil","famili","faedah","fiber","figur","filem","final","firma","flamingo"
    },
    ["g"] = {
        "gunung","gajah","garam","gelas","gelap","gempa","gitar","gula","guru","garpu",
        "gabung","gadis","gagal","galak","galang","gali","gambar","gampang","ganas","gandeng",
        "ganggu","ganjil","ganti","garap","garis","garuk","gasing","gaung","gawal","gebrak"
    },
    ["h"] = {
        "hari","hujan","hewan","hutan","hijau","harap","hangat","hebat","hidup","hitam",
        "habis","hadap","hadiah","hafal","haji","hakikat","halal","halang","halus","hambat",
        "hamil","hampir","hancur","handuk","hangus","hanyut","hapus","harga","harum","hasta"
    },
    ["i"] = {
        "ikan","indah","ilmu","istana","irama","inti","intan","itik","izin","ibu",
        "idam","iklan","ikat","ikut","ilham","imbang","impian","induk","ingin","ingat"
    },
    ["j"] = {
        "jalan","jeruk","jendela","juara","janji","jelas","jatuh","jambu","jagung","jubah",
        "jabat","jadwal","jaga","jahat","jahit","jajak","jajal","jaksa","jalur","jambak"
    },
    ["k"] = {
        "kucing","kuda","kertas","kunci","kapal","kebun","kilat","kota","kursi","kacang",
        "kabur","kacau","kadar","kaget","kain","kakak","kalah","kalung","kamar","kamera",
        "kampung","kanan","kandang","kangkung","kantor","kapak","kapur","karang","kartu","kasur"
    },
    ["l"] = {
        "langit","laut","lampu","lemari","lemon","lebah","lilin","logam","lumba","lapar",
        "labuh","lacak","ladang","laga","lagu","lahar","lahir","lain","laki","laku",
        "lalat","lama","lambat","lamin","lampir","landak","langkah","lantai","lapang","laras"
    },
    ["m"] = {
        "matahari","malam","meja","mangga","merah","murid","musik","mawar","mimpi","mobil",
        "maaf","mahal","mahir","main","makan","makin","malas","malu","mampu","mandek",
        "mangkok","manis","mantap","marah","marga","masak","masuk","matang","mati","mau"
    },
    ["n"] = {
        "naga","nasi","negara","nyala","nanas","novel","nomor","nyamuk","nilai","niat",
        "nafas","nafsu","naik","nakal","nama","nampak","nanti","napas","narasi","nasib"
    },
    ["o"] = {
        "orang","ombak","obat","objek","oleh","opera","orbit","oven","otak","oktan",
        "ojek","olah","omong","ondel","ongkos","opini","optimal","oralit","orkestra","otot"
    },
    ["p"] = {
        "pantai","pohon","pintu","panas","piring","perak","pulau","pasir","pensil","pisang",
        "pacar","padang","pagar","pagi","pahit","pajak","pakai","pakan","paket","palsu",
        "paman","pamer","pancing","pandai","panen","pangkal","panjang","papan","parade","parit"
    },
    ["q"] = {"quran","qari","quartz"},
    ["r"] = {
        "rumah","rambut","raja","rantai","rasa","ringan","robot","ruang","racun","roti",
        "rabuk","racik","radar","ragam","ragu","raih","rajin","rakus","ramah","rambat",
        "rampas","rangka","rantau","rapih","raport","rawat","rawan","rayap","rebus","redam"
    },
    ["s"] = {
        "sinar","salju","sayur","sungai","suara","sendok","semut","sepatu","sawah","sabun",
        "sabar","sadap","sagu","saham","sahut","sains","saji","sakit","saku","salah",
        "saldo","salib","salon","sambil","sampah","sandal","sangat","santai","sapu","sarat"
    },
    ["t"] = {
        "tanah","taman","tikus","telur","tangan","tomat","tirai","tulang","topeng","teras",
        "tabir","tabrak","tadah","tagar","tahan","tahap","takar","takdir","taksi","takut",
        "talam","talang","tali","tamat","tambah","tampan","tandem","tanduk","tangga","tangis"
    },
    ["u"] = {
        "udara","ulat","utara","unggas","untuk","ubur","ukir","unsur","upaya","usaha",
        "ubah","ubin","ucap","udang","ugal","ujian","ukur","ulang","ulet","umpan"
    },
    ["v"] = {
        "violet","vulkan","vaksin","variasi","volume","vokal","visi","vital","venus","video",
        "vandal","vapor","vektor","ventilasi","versi","veteran","vibra","viral","visa","vonis"
    },
    ["w"] = {
        "warna","waktu","wadah","wajah","wajar","wangi","wisata","wortel","wilayah","wahana",
        "wabah","wacana","waduk","wahyu","wajar","wakil","walau","walet","wali","walrus"
    },
    ["x"] = {"xenon","xilofon","xerox"},
    ["y"] = {"yang","yakin","yatim","yogurt","yoga","yuan","yuri","yakni"},
    ["z"] = {"zebra","zaman","zona","zaitun","zodiak","zat","zenith","zigzag","zombie","ziarah"}
}

-- ==========================================
-- KONFIGURASI
-- ==========================================
local CONFIG = {
    AutoPlay        = true,
    AutoWin         = true,
    DelayBeforeSend = 0.3,
    ScanInterval    = 0.5,
    AntiDetect      = true,
    HumanDelay      = true,
    MinDelay        = 0.3,
    MaxDelay        = 1.2,
    LogEnabled      = true,
    MaxRetry        = 5
}

-- ==========================================
-- VARIABEL GLOBAL
-- ==========================================
local kataTerpakai = {}
local lastKataDetected = ""
local isRunning = false
local scoreTracker = 0

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local function Log(msg)
    if CONFIG.LogEnabled then
        print("[SambungKata] " .. tostring(msg))
    end
end

local function HumanLikeDelay()
    if CONFIG.HumanDelay then
        local delay = math.random() * (CONFIG.MaxDelay - CONFIG.MinDelay) + CONFIG.MinDelay
        task.wait(delay)
    else
        task.wait(CONFIG.DelayBeforeSend)
    end
end

local function HurufTerakhir(kata)
    if not kata or #kata == 0 then return "" end
    return string.lower(string.sub(kata, -1))
end

local function HurufPertama(kata)
    if not kata or #kata == 0 then return "" end
    return string.lower(string.sub(kata, 1, 1))
end

-- ==========================================
-- CARI KATA (SMART SEARCH)
-- ==========================================
local function CariKataUnik(hurufAwal)
    local huruf = string.lower(hurufAwal)
    if not KamusKata[huruf] then return nil end

    -- Prioritas: kata yang huruf terakhirnya punya banyak opsi
    local bestKata = nil
    local bestScore = -1

    for _, kata in ipairs(KamusKata[huruf]) do
        if not kataTerpakai[kata] then
            local akhir = HurufTerakhir(kata)
            local opsi = KamusKata[akhir] and #KamusKata[akhir] or 0
            if opsi > bestScore then
                bestScore = opsi
                bestKata = kata
            end
        end
    end

    if bestKata then
        kataTerpakai[bestKata] = true
        return bestKata
    end

    -- Fallback: ambil kata apapun yang belum dipakai
    for _, kata in ipairs(KamusKata[huruf]) do
        if not kataTerpakai[kata] then
            kataTerpakai[kata] = true
            return kata
        end
    end

    return nil
end

-- ==========================================
-- SCAN REMOTE EVENTS
-- ==========================================
local cachedRemotes = {}

local function ScanRemotes()
    cachedRemotes = {}
    local function scanDescendants(parent)
        for _, obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local nameLower = string.lower(obj.Name)
                if string.find(nameLower, "chat") or
                   string.find(nameLower, "answer") or
                   string.find(nameLower, "send") or
                   string.find(nameLower, "guess") or
                   string.find(nameLower, "word") or
                   string.find(nameLower, "submit") or
                   string.find(nameLower, "input") or
                   string.find(nameLower, "message") or
                   string.find(nameLower, "text") or
                   string.find(nameLower, "type") or
                   string.find(nameLower, "sambung") or
                   string.find(nameLower, "kata") then
                    table.insert(cachedRemotes, obj)
                    Log("Remote ditemukan: " .. obj:GetFullName())
                end
            end
        end
    end
    scanDescendants(ReplicatedStorage)

    -- Scan workspace juga
    pcall(function()
        scanDescendants(game:GetService("Workspace"))
    end)

    Log("Total remote ditemukan: " .. #cachedRemotes)
end

-- ==========================================
-- SEND JAWABAN (MULTI METHOD)
-- ==========================================
local function SendJawaban(jawaban)
    local sent = false

    -- METHOD 1: Cari TextBox di PlayerGui
    pcall(function()
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if gui:IsA("TextBox") then
                local nameLower = string.lower(gui.Name)
                if string.find(nameLower, "input") or
                   string.find(nameLower, "chat") or
                   string.find(nameLower, "text") or
                   string.find(nameLower, "answer") or
                   string.find(nameLower, "type") or
                   string.find(nameLower, "box") or
                   string.find(nameLower, "field") then
                    gui:CaptureFocus()
                    task.wait(0.1)
                    gui.Text = jawaban
                    task.wait(0.1)

                    -- Simulasi Enter key
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    end)

                    gui:ReleaseFocus(true)
                    sent = true
                    Log("Sent via TextBox: " .. gui:GetFullName())
                end
            end
        end
    end)

    -- METHOD 2: Fire semua remote yang relevan
    pcall(function()
        for _, remote in ipairs(cachedRemotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(jawaban)
                    remote:FireServer({message = jawaban})
                    remote:FireServer(jawaban, LocalPlayer)
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(jawaban)
                end
            end)
        end
    end)

    -- METHOD 3: Cari semua TextBox (brute force)
    if not sent then
        pcall(function()
            for _, gui in ipairs(PlayerGui:GetDescendants()) do
                if gui:IsA("TextBox") and gui.Visible then
                    gui:CaptureFocus()
                    task.wait(0.1)
                    gui.Text = jawaban
                    task.wait(0.1)
                    gui:ReleaseFocus(true)
                    sent = true
                    Log("Sent via Visible TextBox: " .. gui:GetFullName())
                    break
                end
            end
        end)
    end

    -- METHOD 4: Fire chat
    pcall(function()
        game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            :FindFirstChild("SayMessageRequest"):FireServer(jawaban, "All")
    end)

    return sent
end

-- ==========================================
-- DETECT CURRENT WORD
-- ==========================================
local function DetectCurrentWord()
    local detectedWord = nil

    pcall(function()
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                local text = gui.Text
                local nameLower = string.lower(gui.Name)

                if text and #text >= 2 and #text <= 30 then
                    if string.find(nameLower, "word") or
                       string.find(nameLower, "kata") or
                       string.find(nameLower, "current") or
                       string.find(nameLower, "question") or
                       string.find(nameLower, "display") or
                       string.find(nameLower, "show") or
                       string.find(nameLower, "label") or
                       string.find(nameLower, "main") or
                       string.find(nameLower, "last") or
                       string.find(nameLower, "prev") then

                        -- Filter: pastikan itu kata (bukan angka/simbol)
                        if string.match(text, "^%a+$") then
                            detectedWord = text
                            Log("Word detected from: " .. gui:GetFullName() .. " = " .. text)
                        end
                    end
                end
            end
        end
    end)

    -- Fallback: scan semua TextLabel besar yang visible
    if not detectedWord then
        pcall(function()
            for _, gui in ipairs(PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") and gui.Visible then
                    local text = gui.Text
                    if text and #text >= 2 and #text <= 20 then
                        if string.match(text, "^%a+$") then
                            -- Cek apakah font size besar (kemungkinan kata utama)
                            if gui.TextSize and gui.TextSize >= 20 then
                                detectedWord = text
                            end
                        end
                    end
                end
            end
        end)
    end

    return detectedWord
end

-- ==========================================
-- AUTO WIN ENGINE
-- ==========================================
local function AutoWinEngine()
    Log("=== AUTO WIN ENGINE STARTED ===")
    isRunning = true
    ScanRemotes()

    while CONFIG.AutoPlay and isRunning do
        pcall(function()
            local currentWord = DetectCurrentWord()

            if currentWord and currentWord ~= lastKataDetected then
                lastKataDetected = currentWord
                Log("Kata terdeteksi: " .. currentWord)

                local hurufTarget = HurufTerakhir(currentWord)
                local jawaban = CariKataUnik(hurufTarget)

                if jawaban then
                    Log(">>> Jawaban: " .. jawaban)
                    HumanLikeDelay()
                    SendJawaban(jawaban)
                    scoreTracker = scoreTracker + 1
                    Log("Score: " .. scoreTracker)
                else
                    Log("Tidak ada kata untuk huruf: " .. hurufTarget)
                    -- Reset kata terpakai jika habis
                    kataTerpakai = {}
                    Log("Reset kamus - mencoba ulang...")
                    jawaban = CariKataUnik(hurufTarget)
                    if jawaban then
                        HumanLikeDelay()
                        SendJawaban(jawaban)
                    end
                end
            end
        end)

        task.wait(CONFIG.ScanInterval)
    end
end

-- ==========================================
-- AUTO REJOIN / ROUND DETECTION
-- ==========================================
local function MonitorRound()
    while CONFIG.AutoPlay do
        pcall(function()
            for _, gui in ipairs(PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    local text = string.lower(gui.Text or "")
                    -- Deteksi round baru / game restart
                    if string.find(text, "round") or
                       string.find(text, "mulai") or
                       string.find(text, "start") or
                       string.find(text, "new game") or
                       string.find(text, "ronde") then
                        -- Reset untuk round baru
                        kataTerpakai = {}
                        lastKataDetected = ""
                        Log("=== ROUND BARU TERDETEKSI ===")
                    end

                    -- Auto click Play button
                    if gui:IsA("TextButton") then
                        if string.find(text, "play") or
                           string.find(text, "main") or
                           string.find(text, "start") or
                           string.find(text, "mulai") or
                           string.find(text, "ready") or
                           string.find(text, "siap") then
                            pcall(function()
                                firesignal(gui.MouseButton1Click)
                                -- Alternative click methods
                                gui.MouseButton1Click:Fire()
                            end)
                            Log("Auto-click: " .. gui.Text)
                        end
                    end
                end
            end
        end)
        task.wait(2)
    end
end

-- ==========================================
-- GUI CONTROL PANEL
-- ==========================================
local function CreateGUI()
    pcall(function()
        -- Hapus GUI lama jika ada
        local old = LocalPlayer.PlayerGui:FindFirstChild("SambungKataGUI")
        if old then old:Destroy() end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "SambungKataGUI"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.Parent = PlayerGui

        local MainFrame = Instance.new("Frame")
        MainFrame.Size = UDim2.new(0, 220, 0, 280)
        MainFrame.Position = UDim2.new(0, 10, 0.3, 0)
        MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.Draggable = true
        MainFrame.Parent = ScreenGui

        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 10)
        UICorner.Parent = MainFrame

        -- Title
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 35)
        Title.
      
-- ==========================================
-- MAIN EXECUTION (LANJUTAN)
-- ==========================================
Log("==========================================")
Log("  Sambung Kata Auto Win Script v2.0")
Log("  Compatible: Delta Executor")
Log("==========================================")

-- Buat GUI Control Panel
CreateGUI()
Log("GUI Created!")

-- Jalankan Auto Win Engine
task.spawn(function()
    task.wait(1)
    AutoWinEngine()
end)

-- Jalankan Monitor Round
task.spawn(function()
    task.wait(2)
    MonitorRound()
end)

-- ==========================================
-- ANTI AFK (Biar gak ke-kick)
-- ==========================================
task.spawn(function()
    while true do
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        task.wait(60)
    end
end)

-- ==========================================
-- AUTO RECONNECT REMOTES
-- (Jika game load remote baru)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            ScanRemotes()
        end)
    end
end)

-- ==========================================
-- HOTKEY CONTROLS
-- ==========================================
pcall(function()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- F1 = Toggle ON/OFF
        if input.KeyCode == Enum.KeyCode.F1 then
            CONFIG.AutoPlay = not CONFIG.AutoPlay
            Log("Auto Win: " .. (CONFIG.AutoPlay and "ON" or "OFF"))
            if CONFIG.AutoPlay and not isRunning then
                task.spawn(AutoWinEngine)
            end
        end

        -- F2 = Reset Kamus
        if input.KeyCode == Enum.KeyCode.F2 then
            kataTerpakai = {}
            lastKataDetected = ""
            scoreTracker = 0
            Log("Reset Complete!")
        end

        -- F3 = Toggle Speed
        if input.KeyCode == Enum.KeyCode.F3 then
            if CONFIG.ScanInterval >= 0.5 then
                CONFIG.MinDelay = 0.05
                CONFIG.MaxDelay = 0.15
                CONFIG.ScanInterval = 0.1
                Log("Speed: ULTRA")
            else
                CONFIG.MinDelay = 0.3
                CONFIG.MaxDelay = 1.2
                CONFIG.ScanInterval = 0.5
                Log("Speed: NORMAL")
            end
        end
    end)
end)

Log("=== SCRIPT FULLY LOADED ===")
Log("Hotkeys: F1=Toggle | F2=Reset | F3=Speed")
Log("=========================================")

      
