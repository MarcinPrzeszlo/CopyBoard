#Requires AutoHotkey v2.0
#SingleInstance Force


global ActiveHotkeys := Map() 
global DefaultFolderPath := A_ScriptDir . "\Files"
global DefaultShowGuiHotkey := "^!1"

global IsGuiShowed := false

global FolderPath := IniRead("config.ini", "Settings", "AbsoluteFolderPath", DefaultFolderPath)
ShowGuiHotkey := IniRead("config.ini", "Settings", "ShowGuiHotkey", "^!1")


if (FolderPath == "")    
    FolderPath := DefaultFolderPath
if (ShowGuiHotkey == "")    
    ShowGuiHotkey := DefaultShowGuiHotkey

^!1::ToggleMenu()

ToggleMenu(){
    if (IsGuiShowed){
        CleanExit()
    }
    else{
        ShowMenu()
    }
}

ShowMenu() {
    global ActiveHotkeys, FolderPath, IsGuiShowed, DefaultFolderPath
    global MyGui := Gui(, "Kopiejka")
    
    ; Clean up any existing hotkeys before creating new ones
    
    ; Main GUI
    MyGui.OnEvent("Close", CleanExit)
    MyGui.OnEvent("Escape", CleanExit)
    ;MyGui.SetFont(, "")
    MyGui.SetFont(, "MS Sans Serif")

    ; Get all files in the folder
    Files := []
    try {
        Loop Files, FolderPath "\*.*" {
            Files.Push(A_LoopFilePath)
        }
    } catch as Err {
        MsgBox("Error reading files:`n" Err.Message, "Error", "Icon!")
    }

    if (Files.Length = 0) {
        MsgBox("No files found in the selected folder. Default folder path is " . DefaultFolderPath, "Info", "Iconi")
    }

    ; Create buttons for each file
    ; Dodac druga kolum ne z bindowaniem do Fxx
    for Index, FilePath in Files {

        SplitPath(FilePath, &FileName)
        FileName := SubStr(FileName, 1, -4)  ; Remove extension

        if (Index < 10) {
            FileName := Index . ". " . FileName
        }
        else{
            FileName := "   " . FileName
        }

        Btn := MyGui.Add("Button", "w150 h50 +Theme Left", "  " . FileName)
        Btn.OnEvent("Click", ((f) => (*) => CopyFileContent(f))(FilePath))
        
        ; Hotkey def
        if (Index < 10) {    
            callback := ((f) => (*) => CopyFileContent(f))(FilePath)

            hotkeyNameNumpad := "Numpad" . Index
            hotkeyNameNumeric := Index
            
            Hotkey(hotkeyNameNumpad, callback)
            Hotkey(hotkeyNameNumpad,"On")
            ActiveHotkeys[hotkeyNameNumpad] := callback

            Hotkey(hotkeyNameNumeric, callback)      
            Hotkey(hotkeyNameNumeric,"On")  
            ActiveHotkeys[hotkeyNameNumeric] := callback
        }

    }

    MyGui.Add("Button", "w150 h50 +Theme", "Change folder").OnEvent("Click", ChangeFolderPath)
    ; dodac return2defaultFolder

    MyGui.Show()
    IsGuiShowed := true
}

CopyFileContent(FilePath) {
    try {
        Content := FileRead(FilePath, "UTF-8")
        A_Clipboard := Content
    } catch as Err {
        MsgBox("Failed to read file:`n" FilePath "`n`nError: " Err.Message, "Error", "Icon!")
    }

    CleanExit()
}

CleanExit(*) {
    global ActiveHotkeys, IsGuiShowed
    
    ; Unbind hotkeys
    for hotkeyName, callback in ActiveHotkeys {
        try Hotkey(hotkeyName, "Off")
    }
    ActiveHotkeys.Clear()
    myGui.Hide()
    IsGuiShowed := false
}



ChangeFolderPath(*) {
    global FolderPath
    CleanExit()

    SelectedPath := DirSelect("*" A_ScriptDir, 3, "Select a folder containing files")
    if (SelectedPath != "") {
        FolderPath := SelectedPath
        ShowMenu()
    }
}