#Requires AutoHotkey v2.0
#SingleInstance Force

; =========================
; 基本設定
; =========================

global appTitle := "Magick ICO Maker"
global iniFile := A_ScriptDir "\Settings.ini"
global magickPath := IniRead(iniFile, "General", "MagickPath", "")
global selectedFile := ""

; =========================
; GUI Layout
; =========================

guiW := 580
guiH := 320
labelX := 20
labelW := 90
editX := 110
editW := 360
buttonX := 485
buttonW := 75

magickY := 20
imgY := 100
imgFileTextY := 160
icoSizeY := 200
convertY := 240
statusY := 300

rowH := 60
buttonH := 35

; =========================
; GUI
; =========================

mainGui := Gui("", appTitle)
mainGui.SetFont("s10", "Microsoft JhengHei")

; ===== Magick.exe =====
mainGui.AddText("x" labelX " y" (magickY + 10) " w" labelW " h35 +0x200", "Magick.exe:")
magickEdit := mainGui.AddEdit(
    "x" editX " y" magickY " w" editW " h" rowH " -VScroll",
    magickPath
)
btnSelectMagick := mainGui.AddButton(
    "x" buttonX " y" (magickY + 10) " w" buttonW " h" buttonH,
    "選擇"
)

; ===== Image =====
mainGui.AddText("x" labelX " y" (imgY + 10) " w" labelW " h35 +0x200", "選擇圖片:")
imageEdit := mainGui.AddEdit(
    "x" editX " y" imgY " w" editW " h" rowH " -VScroll",
    "拖曳 PNG / JPG / WEBP 到這裡"
)
btnSelectImage := mainGui.AddButton(
    "x" buttonX " y" (imgY + 10) " w" buttonW " h" buttonH,
    "選擇"
)

imgFileText := mainGui.AddText(
    "x" labelX " y" imgFileTextY " w540",
    "尚未選擇圖片"
)

; ===== ICO Size =====
mainGui.AddText(
    "x" labelX " y" icoSizeY " w" labelW,
    "ICO 尺寸:"
)

cbX := editX
cbGap := 60

cb16 := mainGui.AddCheckbox("x" cbX " y" icoSizeY " Checked", "16")
cb24 := mainGui.AddCheckbox("x" (cbX + cbGap * 1) " y" icoSizeY, "24")
cb32 := mainGui.AddCheckbox("x" (cbX + cbGap * 2) " y" icoSizeY " Checked", "32")
cb48 := mainGui.AddCheckbox("x" (cbX + cbGap * 3) " y" icoSizeY " Checked", "48")
cb64 := mainGui.AddCheckbox("x" (cbX + cbGap * 4) " y" icoSizeY " Checked", "64")
cb128 := mainGui.AddCheckbox("x" (cbX + cbGap * 5) " y" icoSizeY " Checked", "128")
cb256 := mainGui.AddCheckbox("x" (cbX + cbGap * 6 + 10) " y" icoSizeY " Checked", "256")

btnConvert := mainGui.AddButton(
    "x" editX " y" convertY " w" editW " h" buttonH,
    "轉成 ICO"
)

mainGui.AddText("x" 0 " y" (statusY - 5) " w" (GuiW+5) " h1 0x10")

statusText := mainGui.AddText(
    "x" labelX " y" statusY " w540 h40",
    "狀態：等待操作"
)

btnSelectMagick.OnEvent("Click", SelectMagick)
btnSelectImage.OnEvent("Click", SelectImage)
btnConvert.OnEvent("Click", ConvertToIco)
mainGui.OnEvent("DropFiles", DropFilesHandler)

mainGui.OnEvent("Close", (*) => ExitApp())

mainGui.Show("w" guiW " h" guiH)

; =========================
; 選擇 magick.exe
; =========================

SelectMagick(*) {
    global magickPath, magickEdit, iniFile, statusText

    selected := FileSelect(1, , "選擇 magick.exe", "magick.exe (*.exe)")

    if (!selected)
        return

    magickPath := selected
    magickEdit.Value := magickPath

    IniWrite(magickPath, iniFile, "General", "MagickPath")

    statusText.Value := "狀態：已儲存 magick.exe 路徑"
}

; =========================
; 拖放圖片
; =========================

DropFilesHandler(guiObj, guiCtrlObj, fileArray, x, y) {
    global selectedFile, imageEdit, imgFileText, statusText

    if (fileArray.Length = 0)
        return

    file := fileArray[1]

    if (!IsSupportedImage(file)) {
        statusText.Value := "狀態：不支援的圖片格式"
        return
    }

    selectedFile := file
    imageEdit.Value := selectedFile

    SplitPath(selectedFile, &imgFileName)
    imgFileText.Value := "已選擇圖片：" imgFileName
    statusText.Value := "狀態：已選擇圖片"
}

; =========================
; 選擇圖片按鈕
; =========================

SelectImage(*) {
    global selectedFile, imageEdit, imgFileText, statusText

    selected := FileSelect(
        1,
        ,
        "選擇圖片",
        "Images (*.png; *.jpg; *.jpeg; *.webp; *.bmp)"
    )

    if (!selected)
        return

    if (!IsSupportedImage(selected)) {
        statusText.Value := "狀態：不支援的圖片格式"
        return
    }

    selectedFile := selected
    imageEdit.Value := selectedFile

    SplitPath(selectedFile, &imgFileName)
    imgFileText.Value := "已選擇圖片：" imgFileName
    statusText.Value := "狀態：已選擇圖片"
}

; =========================
; 轉 ICO
; =========================

ConvertToIco(*) {
    global magickPath, selectedFile, statusText
    global cb16, cb24, cb32, cb48, cb64, cb128, cb256

    if (magickPath = "") {
        statusText.Value := "狀態：請先選擇 magick.exe"
        return
    }

    if (!FileExist(magickPath)) {
        statusText.Value := "狀態：找不到 magick.exe"
        return
    }

    if (selectedFile = "") {
        statusText.Value := "狀態：請先拖入圖片"
        return
    }

    if (!FileExist(selectedFile)) {
        statusText.Value := "狀態：找不到圖片檔"
        return
    }

    sizes := []

    if (cb16.Value)
        sizes.Push(16)

    if (cb24.Value)
        sizes.Push(24)

    if (cb32.Value)
        sizes.Push(32)

    if (cb48.Value)
        sizes.Push(48)

    if (cb64.Value)
        sizes.Push(64)

    if (cb128.Value)
        sizes.Push(128)

    if (cb256.Value)
        sizes.Push(256)

    if (sizes.Length = 0) {
        statusText.Value := "狀態：請至少選擇一個尺寸"
        return
    }

    sizesText := JoinArray(sizes, ",")

    SplitPath(selectedFile, , &outDir, , &fileNameNoExt)
    icoFile := outDir "\" fileNameNoExt ".ico"

    cmd := Format(
        '"{1}" "{2}" -define icon:auto-resize={3} "{4}"',
        magickPath,
        selectedFile,
        sizesText,
        icoFile
    )

    statusText.Value := "狀態：轉換中..."

    exitCode := RunWait(cmd, , "Hide")

    if (exitCode != 0) {
        statusText.Value := "狀態：轉換失敗，ExitCode=" exitCode
        return
    }

    statusText.Value := "狀態：完成，輸出：" icoFile
}

; =========================
; 檢查圖片格式
; =========================

IsSupportedImage(filePath) {
    SplitPath(filePath, , , &ext)

    ext := StrLower(ext)

    if (ext = "png")
        return true

    if (ext = "jpg")
        return true

    if (ext = "jpeg")
        return true

    if (ext = "webp")
        return true

    if (ext = "bmp")
        return true

    return false
}

; =========================
; Array join
; =========================

JoinArray(arr, separator) {
    result := ""

    for index, value in arr {
        if (index = 1)
            result .= value

        if (index > 1)
            result .= separator value
    }

    return result
}
