#Requires AutoHotkey v2.0
#SingleInstance Force               

GetConfigs()
A_TrayMenu.Add("Toggle menu",(*) => ToggleMenu())

Hotkey(toggleMenuHotkey,(*) => ToggleMenu())
ToggleMenu() {
    global activeWinId := ""

    if (isGuiShowed)
        CleanExit()
    else{
        activeWinId := WinExist("A")
        ShowMenu()

        if (insertSnippetIntoActiveWin == 0 && copySnippetIntoClipboard == 0)
            ShowMsgBox("disabled")
    }
}

ShowMenu() {
    global activeHotkeys, isGuiShowed, searchPhrase
    global activeHotkeys := Map() 

    global MainGui := Gui("+AlwaysOnTop -MinimizeBox", scirptName)
    MainGui.SetFont("w400")
    MainGui.OnEvent("Close", CleanExit)
    MainGui.OnEvent("Escape", CleanExit)

    ; Menu bar configuration
    FileMenu := Menu()
    FileMenu.Add("Open &Folder in file explorer", (*) => Run(folderPath)) 
    FileMenu.Add("&Change folder", ((f) => (*) => ChangeFolderPath(f))("select"))
    FileMenu.Add("&Default folder", ((f) => (*) => ChangeFolderPath(f))("default"))

    SearchMenu := Menu()
    SearchMenu.Add("&Serach for snippet",((*) => ShowSearchGui()))
    SearchMenu.Add("&Clear search input",((f) => (*) => SearchForSnippets(f))(""))

    SettingsMenu := Menu()
    SettingsMenu.Add("Toggle insertSnippetIntoActiveWin", ((f) => (*) => ToggleSetting(f))("insertSnippetIntoActiveWin"))
    SettingsMenu.Add("Toggle copySnippetIntoClipboard", ((f) => (*) => ToggleSetting(f))("copySnippetIntoClipboard"))
    SettingsMenu.Add("Show settings",((f) => (*) => ShowMsgBox(f))("settings"))

    HelpMenu := Menu()
    HelpMenu.Add("&About", (*) => MsgBox(aboutContent, "About", "OK 0x40000"))
    Menus := MenuBar()
    Menus.Add("&File", FileMenu)
    Menus.Add("&Search", SearchMenu)
    Menus.Add("Settings", SettingsMenu)
    Menus.Add("&Help", HelpMenu)
    MainGui.MenuBar := Menus

    ; Get files from selected folder
    Files := Map()
    try {
        Loop Files, folderPath "\*.*" {
            SplitPath(A_LoopFilePath, &name)

            if (searchPhrase == "" || (InStr(name, searchPhrase) > 0)){
                Files[A_LoopFilePath] := name
            }
                

        }
    } catch as Err {
        MsgBox("Error reading files:`n" Err.Message, "Error", "Icon!")
    }

    if (Files.Count == 0) {
        MsgBox("No files found!", "Info", "Iconi")

        if (searchPhrase != ""){
            searchPhrase := ""
            RefreshMenu()
        }
        else{
            MainGui.Add("Button","Default w180 h60","Default folder").OnEvent("Click", ((f) => (*) => ChangeFolderPath(f))("default"))
        }
    }

    ; Create buttons for each file
    rowCounter := 0


    for filePath, fileName in Files {

        index := A_Index
        rowCounter := rowCounter + 1
        
        if (fileOrderingSeparator != "") {
            FileOrderingEnd := InStr(fileName,  fileOrderingSeparator)

            if (FileOrderingEnd > 0)
                fileName := SubStr(fileName, FileOrderingEnd+StrLen( fileOrderingSeparator), StrLen(fileName))
        }
            
        fileName := SubStr(fileName, 1, -4)  ; Remove extension

        if (index <= 9) {
            fileName := index . ". " . fileName
        }
        else if (index <= 18) {
            fileName := "F" . index - 9 . ". " . fileName
        }
        else {
            fileName := "   " . fileName
        }

        callback := ((f) => (*) => CopyFileContent(f))(filePath)
        MainGui.Add("Button", "w180 h50 +Theme Left", "  " . fileName).OnEvent("Click", callback)

        maxRowsInCol := 9 * (Files.Count // (9 * 10) + 1)

        if (rowCounter == maxRowsInCol && index != Files.Count) {
            MainGui.Add("Text", "y-0 w150 h1", " ")
            rowCounter := 0
        }        
        
        if (index <= 9) {                               ; Hotkey - 1-9 & num1-num9
            try hotkeyNameNumpad := "Numpad" . index    
            try hotkeyNameNumeric := index

            try Hotkey(hotkeyNameNumpad, callback)
            try Hotkey(hotkeyNameNumpad,"On")
            activeHotkeys[hotkeyNameNumpad] := callback

            try Hotkey(hotkeyNameNumeric, callback)      
            try Hotkey(hotkeyNameNumeric,"On")  
            activeHotkeys[hotkeyNameNumeric] := callback
        }
        else if (index <= 18) {                         ; Hotkey - F1-F9
            hotkeyNameFunction := "F" . index - 9       

            try Hotkey(hotkeyNameFunction, callback)      
            try Hotkey(hotkeyNameFunction,"On")  
            activeHotkeys[hotkeyNameFunction] := callback
        }
    }
    MainGui.Show()
    isGuiShowed := true
}


CopyFileContent(filePath) {
    prevClipboardContent := A_Clipboard
    A_Clipboard := ""

    try {
        A_Clipboard := FileRead(filePath, "UTF-8")
        if !ClipWait(1){
            MsgBox "Clipboard copy timed out!"
            return
        }

        ;MsgBox A_Clipboard
    } catch as Err {
        MsgBox("Failed to read file:`n" filePath "`n`nError: " Err.Message, "Error", "Icon!")
    }
  
    if (insertSnippetIntoActiveWin == 1){
        try{
            WinActivate activeWinId
            Send "^v"
        }
    }

    if (copySnippetIntoClipboard != 1){
        Sleep 100
        A_Clipboard := prevClipboardContent
    }    

    CleanExit()
}


CleanExit(*) {
    global activeHotkeys, isGuiShowed
    
    ; Unbind hotkeys
    for hotkeyName, callback in activeHotkeys {
        try Hotkey(hotkeyName, "Off")
    }

    activeHotkeys.Clear()
    MainGui.Hide()
    isGuiShowed := false
    try SearchGui.Destroy() 
}


RefreshMenu(*) {
    CleanExit()
    ShowMenu()
}


ChangeFolderPath(option) {
    global folderPath
    CleanExit()
    
    if (option == "select") {
        selectedPath := DirSelect("*" A_ScriptDir, 3, "Select a folder")

        if (selectedPath != "")
            folderPath := selectedPath
    }
    else if (option == "default")
        folderPath := defaultFolderPath

    ShowMenu()
}


ShowSearchGui(*) {
    global SearchGui := Gui("AlwaysOnTop -MinimizeBox", "Insert snippet name")
    searchPhraseInput := SearchGui.Add("Edit", "w170 h20")
    SearchGui.Add("Button", "w50 h30 Default", "Search").OnEvent("Click", ((*) => SearchButtonClicked()))
    SearchGui.Add("Button", "w50 h30 x+10", "Clear").OnEvent("Click", ((f) => (*) => SearchForSnippets(f))(""))
    SearchGui.Add("Button", "w50 h30 x+10", "Cancel").OnEvent("Click", ((*) => SearchCancel()))
    SearchGui.Show()

    for hotkeyName, callback in activeHotkeys {
        try Hotkey(hotkeyName, "Off")
    }

    SearchButtonClicked(*) {
        SearchForSnippets(searchPhraseInput.Value)
    }

    SearchCancel(*){
        SearchGui.Destroy()
        for hotkeyName, callback in activeHotkeys {
            try Hotkey(hotkeyName, "On")
        }
    }
}


SearchForSnippets(phrase) {
    global searchPhrase
    searchPhrase := phrase
    RefreshMenu()
}

ToggleSetting(name){
    global insertSnippetIntoActiveWin, copySnippetIntoClipboard

    if (name == "insertSnippetIntoActiveWin"){
        if (insertSnippetIntoActiveWin == 1)
            insertSnippetIntoActiveWin := 0
        else
            insertSnippetIntoActiveWin := 1
    }

    if (name == "copySnippetIntoClipboard"){
        if (copySnippetIntoClipboard == 1)
            copySnippetIntoClipboard := 0
        else
            copySnippetIntoClipboard := 1
    }

    if (insertSnippetIntoActiveWin == 0 && copySnippetIntoClipboard == 0)
        ShowMsgBox("disabled")
}

ShowMsgBox(info){
    if (info == "disabled")
        MsgBox "Basic features disabled", "Warning", "Icon! " . 0x40000 	
    else if (info == "settings"){
        settingsMsg :=  "insertSnippetIntoActiveWin - " . insertSnippetIntoActiveWin .
                        "`ncopySnippetIntoClipboard - " . copySnippetIntoClipboard

        MsgBox settingsMsg, "Settings", "Iconi " . 0x40000 	
    }
}

GetConfigs(*) {
    path := A_ScriptDir . "\Files"
    global defaultFolderPath := IniRead("config.ini", "Settings", "DefaultFolderPath", path)
    if (defaultFolderPath == "")
        defaultFolderPath := path
    global folderPath := defaultFolderPath
    
    defaultToggleMenuHotkey := "+^q"
    global toggleMenuHotkey := IniRead("config.ini", "Settings", "ToggleMenuHotkey", defaultToggleMenuHotkey)
    if (toggleMenuHotkey == "")    
        toggleMenuHotkey := defaultToggleMenuHotkey

    global insertSnippetIntoActiveWin := IniRead("config.ini", "Settings", "InsertSnippetIntoActiveWin", 0)
    if (insertSnippetIntoActiveWin == "")    
        insertSnippetIntoActiveWin := 0

    global copySnippetIntoClipboard := IniRead("config.ini", "Settings", "CopySnippetIntoClipboard", 1)
    if (copySnippetIntoClipboard == "")    
        copySnippetIntoClipboard := 1


    global searchPhrase := ""
    global fileOrderingSeparator := "$"
    global isGuiShowed := false
    global scirptName := SubStr(A_ScriptName,1,InStr(A_ScriptName,'.')-1)
    global aboutContent :=  "Default folder path`n  " . defaultFolderPath . "`n`n" . 
                            "Default toggle menu hotkey`n  Shift + Ctrl + Q`n`n" . 
                            "To use MenuBar press`n  Alt + {underlined letter of menubar option}`n`n" .
                            "File ordering`n  For ordered files, use numbered prefixes with a dollar sign.`n  The prefix length must be the same for all files.`n  For example: '23$File1', '24$File2' "
}