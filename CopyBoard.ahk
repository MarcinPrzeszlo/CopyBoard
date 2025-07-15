#Requires AutoHotkey v2.0
#SingleInstance Force

global ActiveHotkeys := Map() 
global FolderPath := GetDefaultFolderPath()

global IsGuiShowed := false
global BtnWidth := 150
global BtnStyle := " h50 +Theme "
global ToggleMenuHotkey := IniRead("config.ini", "Settings", "ToggleMenuHotkey", "^!1")
if (ToggleMenuHotkey == "")    
    ToggleMenuHotkey := "^!1"

toggleCallback := (() => (*) => ToggleMenu())()
Hotkey(ToggleMenuHotkey,toggleCallback)

ToggleMenu(){
    if (IsGuiShowed)
        CleanExit()
    else
        ShowMenu()
}

ShowMenu() {
    global ActiveHotkeys, FolderPath, IsGuiShowed
    
    global MyGui := Gui("+AlwaysOnTop -MinimizeBox", "CopyBoard")
    MyGui.SetFont("w300")
    MyGui.OnEvent("Close", CleanExit)
    MyGui.OnEvent("Escape", CleanExit)

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

    
    ; Create buttons for each file
    for Index, FilePath in Files {

        SplitPath(FilePath, &FileName)
        FileName := SubStr(FileName, 1, -4)  ; Remove extension

        if (Index < 10) {
            FileName := Index . ". " . FileName
        }
        else if (Index < 22) {
            FileName := "F" . Index - 9 . ". " . FileName
        }
        else {
            FileName := "   " . FileName
        }

        callback := ((f) => (*) => CopyFileContent(f))(FilePath)

        if (Index - ((Index // 10)*10) == 0)
            MyGui.Add("Text", "y-0 w150 h1", " ")


        Btn := MyGui.Add("Button", "w" . BtnWidth . BtnStyle . "Left", "  " . FileName)
        Btn.OnEvent("Click", callback)
        
        ; Hotkey def for 1-9
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
        ; Hotkey def for F1-F12
        else if (Index < 22){  
            hotkeyNameFunction := "F" . Index - 9

            Hotkey(hotkeyNameFunction, callback)      
            Hotkey(hotkeyNameFunction,"On")  
            ActiveHotkeys[hotkeyNameFunction] := callback
        }

        if (Index == 9)
            AddFolderButtons()
    }

    if (Files.Length < 9)
        AddFolderButtons()

    MyGui.Show()
    IsGuiShowed := true

    AddFolderButtons(){
        MyGui.Add("Button", "w65" . BtnStyle, "change folder").OnEvent("Click", ((f) => (*) => ChangeFolderPath(f))(""))
        MyGui.Add("Button", "x+20 w65" . BtnStyle, "default folder").OnEvent("Click", ((f) => (*) => ChangeFolderPath(f))("default"))
    }
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

