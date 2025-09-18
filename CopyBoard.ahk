#Requires AutoHotkey v2.0
#SingleInstance Force               
GetConfigs()

;----------------
;--> GUIs section

ToggleMenu(){
    global hActiveWnd := ""

    if (isGuiShowed)
        CleanExit()
    else{
        hActiveWnd := WinExist("A")
        ShowMenu()

        if (insertSnippetIntoActiveWin == 0 && copySnippetIntoClipboard == 0)
            ShowMsgBox("InputWarning")
    }
}

CleanExit(*){
    global activeHotkeys, isGuiShowed, hActiveWnd
    
    for hotkeyName, callback in activeHotkeys {
        try Hotkey(hotkeyName, "Off")
    }

    activeHotkeys.Clear()
    MainGui.Hide()
    isGuiShowed := false
    try SearchGui.Destroy() 
    hActiveWnd := ""
}

RefreshMenu(){
    CleanExit()
    ShowMenu()
}

ShowMenu(){
    global isGuiShowed
    global activeHotkeys := Map() 

    global MainGui := Gui("+AlwaysOnTop -MinimizeBox", scirptName)
    MainGui.SetFont("w500")
    MainGui.OnEvent("Close", CleanExit)
    MainGui.OnEvent("Escape", CleanExit)
    MainGui.MenuBar := Menus


    files := GetFilesFromDirectory()
    if (files.Length == 0)
        MainGui.Add("Button","Default w150 h50","Default folder").OnEvent("Click", ((f) => (*) => ChangeFolderPath(f))("default"))

    
    rowCounter := 0

    ;--> Create buttons for each file
    for index, File in Files {
        index := A_Index
        rowCounter := rowCounter + 1

        fileName := File.Name
        filePath := File.FilePath
        isFolder := File.IsFolder

        if (index <= 9 && disableMainGuiHotkeys == 0){
            fileName := index . ". " . fileName
        }
        else if (index <= 18 && disableMainGuiHotkeys == 0){
            fileName := "F" . index - 9 . ". " . fileName
        }
        else {
            fileName := "   " . fileName
        }

        maxLineLen := 25
        lineCounter := 1
        tempNamePhrase := fileName
        fileName := ""

        while (StrLen(tempNamePhrase) > maxLineLen && lineCounter <= 3){
            phrasePart := SubStr(tempNamePhrase, 1, maxLineLen)

            phraseLen := InStr(phrasePart, " ", ,maxLineLen-4)
            if (phraseLen == 0)
                phraseLen := InStr(phrasePart, "_", ,maxLineLen-4)
            if (phraseLen == 0)
                phraseLen := maxLineLen-1
            
            fileName := fileName . SubStr(tempNamePhrase, 1, phraseLen) 
            
            if (lineCounter < 3)
                fileName := fileName . "`n      "
            tempNamePhrase := SubStr(tempNamePhrase, phraseLen + 1) 
            lineCounter := lineCounter + 1
        }
        if (lineCounter < 3)
            fileName := fileName . tempNamePhrase

        if (isFolder == "D")
            callback := ((f) => (*) => ChangeFolderPath(f))(filePath)
        else
            callback := ((f) => (*) => CopyFileContent(f))(filePath)


        MainGui.Add("Button", "w150 h50 +Theme Left", "  " . fileName).OnEvent("Click", callback)
        maxRowsInCol := 9 * (Files.Length // (9 * 10) + 1)

        if (rowCounter == maxRowsInCol && index != Files.Length){
            MainGui.Add("Text", "y-0 w150 h1", " ")
            rowCounter := 0
        }        
        
        if (disableMainGuiHotkeys == 0){
            if (index <= 9){                               ;--> Hotkey - 1-9 & num1-num9
                try hotkeyNameNumpad := "Numpad" . index    
                try hotkeyNameNumeric := index

                try Hotkey(hotkeyNameNumpad, callback)
                try Hotkey(hotkeyNameNumpad,"On")
                activeHotkeys[hotkeyNameNumpad] := callback

                try Hotkey(hotkeyNameNumeric, callback)      
                try Hotkey(hotkeyNameNumeric,"On")  
                activeHotkeys[hotkeyNameNumeric] := callback
            }
            else if (index <= 18){                         ;--> Hotkey - F1-F9
                hotkeyNameFunction := "F" . index - 9       

                try Hotkey(hotkeyNameFunction, callback)      
                try Hotkey(hotkeyNameFunction,"On")  
                activeHotkeys[hotkeyNameFunction] := callback
            }
        }
    }
    MainGui.Show()
    isGuiShowed := true
}

ShowSearchGui(){
    global SearchGui := Gui("AlwaysOnTop -MinimizeBox", "Insert snippet name")
    searchPhraseInput := SearchGui.Add("Edit", "w170 h20")
    SearchGui.Add("Button", "w50 h30 Default", "Search").OnEvent("Click", ((*) => SearchButtonClicked()))
    SearchGui.Add("Button", "w50 h30 x+10", "Clear").OnEvent("Click", ((f) => (*) => SearchForSnippets(f))(""))
    SearchGui.Add("Button", "w50 h30 x+10", "Cancel").OnEvent("Click", ((*) => SearchCancel()))
    SearchGui.Show()
    SearchGui.OnEvent("Escape",SearchCancel)

    for hotkeyName, callback in activeHotkeys {
        try Hotkey(hotkeyName, "Off")
    }

    SearchButtonClicked(){
        SearchForSnippets(searchPhraseInput.Value)
    }

    SearchCancel(*){
        SearchGui.Destroy()
        for hotkeyName, callback in activeHotkeys {
            try Hotkey(hotkeyName, "On")
        }
    }
}

ShowMsgBox(info){
    msg := ""
    if (info == "InputWarning"){
        msg := "No output method enabled. Snippets won't be inserted or copied"
    }
    else if (info == "FolderWarning"){
        msg := "Selected folder doesn't exist. " . scirptName . " redirected to the parent folder"
    }
    else if (info == "Settings"){
        msg :=  GetSettingsString()
    }
    else if (info == "About"){
        msg :=  "Toggle menu hotkey`n  Key combination: " . toggleMenuHotkey . "`n  Modifiers symbols: Alt -> !  Control -> ^  Shift -> +`n`n" .
                "Alternative way to use MenuBar`n  Alt + {underlined letter of menubar option}`n`n" .
                "File ordering`n  For ordered files, use numbered prefixes with a dollar sign.`n  The prefix length must be the same for all files.`n  For example: '23$File', '24$File2'" .
                "`n`nDocJnt©"
    }
    MsgBox msg, info, "OK 0x40000"
}

;-------------------------
;-> File retrieval section

CopyFileContent(filePath){
    prevClipboardContent := A_Clipboard
    A_Clipboard := ""
    fileContent := ""

    try {
        fileContent := FileRead(filePath, "UTF-8")

        if (fileContent == ""){
            ToolTip "File has no content"
            SetTimer () => ToolTip(), -750  
            return        
        }

        A_Clipboard := fileContent
        if (!ClipWait(1)){
            MsgBox("Clipboard copy timed out!", "Error", "Icon! 0x40000")
             return
        }
    } catch as Err {
        MsgBox("Failed to read file", "Error", "Icon! 0x40000")
    }

    if (insertSnippetIntoActiveWin == 1){
        try{
            WinActivate hActiveWnd
            Sleep 100
            Send "^v"
        }
    }

    if (copySnippetIntoClipboard == 0){
        Sleep 100
        A_Clipboard := prevClipboardContent
    }    

    if (hideMenuAfterUse == 1){
        CleanExit()
    }else{
        ToolTip "Done"
        SetTimer () => ToolTip(), -750  
        return   
    }

}

ChangeFolderPath(option){
    global folderPath, searchPhrase
    CleanExit()
    
    if (option == "select"){
        selectedPath := DirSelect("*" A_ScriptDir, 3, "Select a folder")

        if (selectedPath != "")
            folderPath := selectedPath
    }
    else if (option == "default"){
        folderPath := defaultFolderPath   
    }
    else if (option == "parent"){
        SplitPath folderPath, &filename, &parentDir
        folderPath := parentDir
    }
    else{
        folderPath := option
    }
    
    searchPhrase := ""
    ShowMenu()
}

SearchForSnippets(phrase){
    global searchPhrase
    searchPhrase := phrase
    RefreshMenu()
}

class Item{
    __New(name, filePath, extension, isFolder){
        this.Name := name
        this.FilePath := filePath
        this.Extension := extension
        this.IsFolder := isFolder
    }
}

GetFilesFromDirectory(){
    global searchPhrase

    if (DirExist(folderPath) != "D"){
        ShowMsgBox("FolderWarning")
        ChangeFolderPath("parent")
    }

    Items := []
    try {
        Loop Files, folderPath "\*.*", "DF" {
            SplitPath(A_LoopFilePath, &fileName)

            if (InStr(FileGetAttrib(A_LoopFilePath),"H") == 0)
            if (searchPhrase == "" || (InStr(fileName, searchPhrase) > 0)){
                isFolder := DirExist(A_LoopFilePath)
                extension := ""

                if (!isFolder && StrLen(fileName) > 4) && InStr(fileName,".") > 0{
                    fileName := SubStr(fileName, 1, -4)
                    extension := SubStr(fileName, -4, 4)
                }
                
                if (fileOrderingSeparator != ""){
                    fileOrderingEnd := InStr(fileName,  fileOrderingSeparator)
                
                    if (fileOrderingEnd > 0)
                        fileName := SubStr(fileName, fileOrderingEnd+StrLen( fileOrderingSeparator), StrLen(fileName))
                }

                if (isFolder)
                    fileName := fileName . " [dir]"

                Items.Push(Item(fileName, A_LoopFilePath, extension, isFolder))
            }
        }
    } catch as Err {
        MsgBox("Error reading files", "Error", "Icon! 0x40000")
    }

    if (Items.Length == 0){
        MsgBox("No files found!", "Info", "OK 0x40000")

        if (searchPhrase != ""){
            searchPhrase := ""
            RefreshMenu()
        }
    }

    return Items
}

;-------------------------
;--> Script config section

GetConfigs(){
    path := A_ScriptDir . "\Files"
    global defaultFolderPath := IniRead("config.ini", "Settings", "defaultFolderPath", path)
    if (defaultFolderPath == "")
        defaultFolderPath := path
    global folderPath := defaultFolderPath
    
    defaultToggleMenuHotkey := "+^q"
    global toggleMenuHotkey := IniRead("config.ini", "Settings", "toggleMenuHotkey", defaultToggleMenuHotkey)
    if (toggleMenuHotkey == "")    
        toggleMenuHotkey := defaultToggleMenuHotkey

    global insertSnippetIntoActiveWin := IniRead("config.ini", "Settings", "insertSnippetIntoActiveWin", 0)
    if (!IsBoolean(insertSnippetIntoActiveWin))   
        insertSnippetIntoActiveWin := 0

    global copySnippetIntoClipboard := IniRead("config.ini", "Settings", "copySnippetIntoClipboard", 1)
    if (!IsBoolean(copySnippetIntoClipboard)) 
        copySnippetIntoClipboard := 1

    global disableMainGuiHotkeys := IniRead("config.ini", "Settings", "disableMainGuiHotkeys", 0)
    if (!IsBoolean(disableMainGuiHotkeys)) 
        disableMainGuiHotkeys := 0

    global hideMenuAfterUse := IniRead("config.ini", "Settings", "hideMenuAfterUse", 1)
    if (!IsBoolean(hideMenuAfterUse))   
        hideMenuAfterUse := 1
    
    global disableMenuToggleHotkey := IniRead("config.ini", "Settings", "disableMenuToggleHotkey", 0)
    if (!IsBoolean(disableMenuToggleHotkey))   
        disableMenuToggleHotkey := 0
    
    if (disableMenuToggleHotkey == 0)
        Hotkey(toggleMenuHotkey, (*) => ToggleMenu())

    global searchPhrase := ""
    global fileOrderingSeparator := "$"
    global isGuiShowed := false
    global scirptName := SubStr(A_ScriptName,1,InStr(A_ScriptName,'.')-1)

    IsBoolean(value) => value == 1 || value == 0

    ;--> Tray configuration
    A_IconTip := scirptName
    Tray := A_TrayMenu
    Tray.Delete()
    Tray.Add("&Toggle menu",(*) => ToggleMenu())
    Tray.Default := ("1&")
    Tray.Add("E&xit app",(*) => (SetTimer(ExitApp.Bind(), -100)))

    ;--> Menu bar configuration
    FileMenu := Menu()
    FileMenu.Add("Reveal in &file explorer", (*) => Run(folderPath)) 
    FileMenu.Add("&Change folder", ((f) => (*) => ChangeFolderPath(f))("select"))
    FileMenu.Add("&Default folder", ((f) => (*) => ChangeFolderPath(f))("default"))
    FileMenu.Add("P&arent folder", ((f) => (*) => ChangeFolderPath(f))("parent"))
    FileMenu.Add("----", ((*) => Sleep(1)))
    FileMenu.Add("Hide menu", CleanExit)
    FileMenu.Add("Exit app", (*) => (SetTimer(ExitApp.Bind(), -100)))

    SearchMenu := Menu()
    SearchMenu.Add("&Serach for snippet",((*) => ShowSearchGui()))
    SearchMenu.Add("&Clear search input",((f) => (*) => SearchForSnippets(f))(""))

    SettingsMenu := Menu()
    SettingsMenu.Add("Show settings",((f) => (*) => ShowMsgBox(f))("Settings"))
    SettingsMenu.Add("About", ((f) => (*) => ShowMsgBox(f))("About"))
    SettingsMenu.Add("----", ((*) => Sleep(1)))
    SettingsMenu.Add("Toggle insertSnippetIntoActiveWin", ((f) => (*) => ToggleSetting(f))("insertSnippetIntoActiveWin"))
    SettingsMenu.Add("Toggle copySnippetIntoClipboard", ((f) => (*) => ToggleSetting(f))("copySnippetIntoClipboard"))
    SettingsMenu.Add("Toggle disableMainGuiHotkeys", ((f) => (*) => ToggleSetting(f))("disableMainGuiHotkeys"))
    SettingsMenu.Add("Toggle hideMenuAfterUse", ((f) => (*) => ToggleSetting(f))("hideMenuAfterUse"))
;   SettingsMenu.Add("Toggle disableMenuToggleHotkey", ((f) => (*) => ToggleSetting(f))("disableMenuToggleHotkey"))
;   SettingsMenu.Add("---- ", ((*) => Sleep(1)))
    SettingsMenu.Add("Set this folder as a default", (*) => SetDefaultFolder())


    global Menus := MenuBar()
    Menus.Add("&File", FileMenu)
    Menus.Add("&Search", SearchMenu)
    Menus.Add("Settings", SettingsMenu)
}

ToggleSetting(name) {
    global
    try { 
        %name% := !%name%
        
        if (name == "disableMainGuiHotkeys")
            RefreshMenu()
        else if ((name == "insertSnippetIntoActiveWin" || name == "copySnippetIntoClipboard") && insertSnippetIntoActiveWin == 0 && copySnippetIntoClipboard == 0)
            ShowMsgBox("InputWarning")
        ;else if (name == "disableMenuToggleHotkey")
        ;    SetToggleMenuHotkey()
    } catch as Err {
        MsgBox("An error occurred while changing the setting", "Error", "Icon! 0x40000")
    }
    SetConfig()
}

SetDefaultFolder(){
    global defaultFolderPath := folderPath
    SetConfig()
}

;SetToggleMenuHotkey(){
;   try {
;       try Hotkey(toggleMenuHotkey, "Off")
;       
;       if (disableMenuToggleHotkey == 0) {
;           Hotkey(toggleMenuHotkey, (*) => ToggleMenu())
;           Hotkey(toggleMenuHotkey, "On")
;       }
;   } catch Error as e {
;       MsgBox "Error setting toggle hotkey: " e.Message
;   }
;}

SetConfig(){
    path := A_ScriptDir . "\config.ini"
    if(FileExist(path) == "")
        try FileAppend "", path, "UTF-8"

    IniWrite(GetSettingsString(), path, "Settings")
}

GetSettingsString(){
    return          "defaultFolderPath=" . defaultFolderPath .
            "`n" .  "toggleMenuHotkey=" . toggleMenuHotkey .
            "`n" .  "insertSnippetIntoActiveWin=" . insertSnippetIntoActiveWin .
            "`n" .  "copySnippetIntoClipboard=" . copySnippetIntoClipboard .
            "`n" .  "disableMainGuiHotkeys=" . disableMainGuiHotkeys .
            "`n" .  "hideMenuAfterUse=" . hideMenuAfterUse 
;          ."`n" .  "disableMenuToggleHotkey=" . disableMenuToggleHotkey
}

