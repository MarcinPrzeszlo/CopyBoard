#Requires AutoHotkey v2.0
#SingleInstance Force

global ActiveHotkeys := Map() 

global IsGuiShowed := false
global FolderPath := GetDefaultFolderPath()

ShowGuiHotkey := IniRead("config.ini", "Settings", "ShowGuiHotkey", "^!1")
if (ShowGuiHotkey == "")    
    ShowGuiHotkey := "^!1"


^!1::ToggleMenu()

ToggleMenu(){
    if (IsGuiShowed)
        CleanExit()
    else
        ShowMenu()
}

ShowMenu() {
    global ActiveHotkeys, FolderPath, IsGuiShowed
    
    global MyGui := Gui("+AlwaysOnTop -MinimizeBox", "Kopiejka")
    MyGui.OnEvent("Close", CleanExit)
    MyGui.OnEvent("Escape", CleanExit)

    ;MyGui.SetFont(, "")
    ;MyGui.SetFont(, "MS Sans Serif")

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
        MsgBox("No files found in folder " . FolderPath, "Info", "Iconi")
    }

    ; Dodac druga kolum ne z bindowaniem do Fxx

    ; Create buttons for each file
    for Index, FilePath in Files {

        SplitPath(FilePath, &FileName)
        FileName := SubStr(FileName, 1, -4)  ; Remove extension

        if (Index < 10) {
            FileName := Index . ". " . FileName
        }
        else if (Index < 21) {
            FileName := "F" . Index - 9 . ". " . FileName
        }
        else {
            FileName := "   " . FileName
        }

        callback := ((f) => (*) => CopyFileContent(f))(FilePath)

        Btn := MyGui.Add("Button", "w150 h50 +Theme Left", "  " . FileName)
        Btn.OnEvent("Click", callback)
        
        ; Hotkey def
        if (Index < 10) {    
            hotkeyNameNumpad := "Numpad" . Index
            hotkeyNameNumeric := Index
            
            Hotkey(hotkeyNameNumpad, callback)
            Hotkey(hotkeyNameNumpad,"On")
            ActiveHotkeys[hotkeyNameNumpad] := callback

            Hotkey(hotkeyNameNumeric, callback)      
            Hotkey(hotkeyNameNumeric,"On")  
            ActiveHotkeys[hotkeyNameNumeric] := callback
        }
        else if (Index < 21){  
            hotkeyNameFunction := "F" . Index - 9

            Hotkey(hotkeyNameFunction, callback)      
            Hotkey(hotkeyNameFunction,"On")  
            ActiveHotkeys[hotkeyNameFunction] := callback
        }
    }

    MyGui.Add("Button", "y+10 w90 h50 +Theme", "Change folder").OnEvent("Click", ((f) => (*) => ChangeFolderPath(f))(""))
    MyGui.Add("Button", "x+15 w45 h50 +Theme", "Default folder").OnEvent("Click", ((f) => (*) => ChangeFolderPath(f))("default"))

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
    MyGui.Hide()
    IsGuiShowed := false
}


ChangeFolderPath(option) {
    global FolderPath
    CleanExit()
    
    if (option != "default")
        SelectedPath := DirSelect("*" A_ScriptDir, 3, "Select a folder containing files")

    if (option == "default" || SelectedPath == "")
        SelectedPath := GetDefaultFolderPath()
    
    FolderPath := SelectedPath
    ShowMenu()
}


GetDefaultFolderPath(*) {
    DefaultFolderPath := A_ScriptDir . "\Files"
    Path := IniRead("config.ini", "Settings", "AbsoluteFolderPath", DefaultFolderPath)
    
    if (Path == "")    
        Path := DefaultFolderPath
        
    return Path
}

