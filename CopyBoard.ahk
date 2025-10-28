#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

class ScriptManager {
    static scriptName  := SubStr(A_ScriptName,1,InStr(A_ScriptName,'.')-1)
    static Files := []
    static BarMenus := MenuBar()

    static State := {
        isGuiShowed: false,
        hActiveWnd: "",
        folderPath: "",
        searchPhrase: "",
        activeHotkeys: Map()
    }

    static Defaults := {
        defaultFolderPath: A_ScriptDir . "\Files",
        menuToggleHotkey: "+^q",
        insertSnippetIntoActiveWin: 0,
        copySnippetIntoClipboard: 1,
        disableSnippetHotkeys: 0,
        hideMenuAfterUse: 1,
        disableMenuToggleHotkey: 0
    }

    static Config := {
        defaultFolderPath: "",
        menuToggleHotkey: "",
        insertSnippetIntoActiveWin: "",
        copySnippetIntoClipboard: "",
        disableSnippetHotkeys: "",
        hideMenuAfterUse: "",
        disableMenuToggleHotkey: ""
    }

    static Init() {
        this.LoadConfig()
        this.SetupTrayMenu()
        this.SetupMenuBar()
        HotkeyManager.ToggleMenuHotkey()
    }

    static LoadConfig() {
        for key in this.Config.OwnProps() {
            try {
                this.Config.%key% := IniRead("config.ini", "Settings", key)
            }
        }

        for key in this.Config.OwnProps() {
            value := this.Config.%key%

            if (key == "defaultFolderPath" || key == "menuToggleHotkey"){
                if (value == ""){
                    this.Config.%key% := this.Defaults.%key% 
                }
            }else{
                if (!IsBoolean(value)){
                    this.Config.%key% := this.Defaults.%key%
                }
            }       
        }

        IsBoolean(value) => value == 1 || value == 0
        this.State.folderPath := this.Config.defaultFolderPath
    }

    static ToggleSetting(name) {
        try { 
            ScriptManager.Config.%name% := !ScriptManager.Config.%name%
            
            if (name == "disableSnippetHotkeys")
                GuiManager.RefreshMenu()
            else if (name == "disableMenuToggleHotkey")
                HotkeyManager.ToggleMenuHotkey()
        } catch Error as e {
            MsgBox("An error occurred while changing the setting: " . e.Message, "Error", "Icon! 0x40000")
        }
        this.SaveConfig()
    }

    static SetDefaultFolder() {
        this.Config.defaultFolderPath := this.State.folderPath
        this.SaveConfig()
    }


    static SaveConfig() {
        path := A_ScriptDir . "\config.ini"
        if(FileExist(path) == "")
            try FileAppend "", path, "UTF-8"

        IniWrite(this.GetSettingsString(), path, "Settings")
    }

    static GetSettingsString() {
        settingsString := ""

        for key in this.Config.OwnProps() 
            settingsString := settingsString . key . "=" . this.Config.%key% . "`n"  
            
        return settingsString       
    }

    static SetupTrayMenu() {
        A_IconTip := this.scriptName 
        Tray := A_TrayMenu
        Tray.Delete()
        Tray.Add("&Toggle menu",(*) => GuiManager.ToggleMenu())
        Tray.Default := ("1&")
        Tray.Add("E&xit app",(*) => (SetTimer(ExitApp.Bind(), -100)))
    }

    static SetupMenuBar() {
        FileMenu := Menu()
        FileMenu.Add("Reveal in &file explorer", (*) => Run(ScriptManager.State.folderPath)) 
        FileMenu.Add("&Change folder", ((f) => (*) => FileOperations.ChangeFolderPath(f))("select"))
        FileMenu.Add("&Default folder", ((f) => (*) => FileOperations.ChangeFolderPath(f))("default"))
        FileMenu.Add("P&arent folder", ((f) => (*) => FileOperations.ChangeFolderPath(f))("parent"))
        FileMenu.Add("----", ((*) => Sleep(1)))
        FileMenu.Add("&Quit menu", GuiManager.HideMenu)
        FileMenu.Add("Exit app", (*) => (SetTimer(ExitApp.Bind(), -100)))

        SearchMenu := Menu()
        SearchMenu.Add("&Serach for snippet",((*) => GuiManager.ShowSearchGui()))
        SearchMenu.Add("&Clear search input",((f) => (*) => FileOperations.SearchForSnippets(f))(""))

        SettingsMenu := Menu()
        SettingsMenu.Add("Show settings",((f) => (*) => GuiManager.ShowMsgBox(f))("Settings"))
        SettingsMenu.Add("About", ((f) => (*) => GuiManager.ShowMsgBox(f))("About"))
        SettingsMenu.Add("----", ((*) => Sleep(1)))
        SettingsMenu.Add("Toggle insertSnippetIntoActiveWin", ((f) => (*) => this.ToggleSetting(f))("insertSnippetIntoActiveWin"))
        SettingsMenu.Add("Toggle copySnippetIntoClipboard", ((f) => (*) => this.ToggleSetting(f))("copySnippetIntoClipboard"))
        SettingsMenu.Add("Toggle disableSnippetHotkeys", ((f) => (*) => this.ToggleSetting(f))("disableSnippetHotkeys"))
        SettingsMenu.Add("Toggle hideMenuAfterUse", ((f) => (*) => this.ToggleSetting(f))("hideMenuAfterUse"))
        SettingsMenu.Add("Toggle disableMenuToggleHotkey", ((f) => (*) => this.ToggleSetting(f))("disableMenuToggleHotkey"))
        SettingsMenu.Add("Set this folder as a default", (*) => this.SetDefaultFolder())

        this.BarMenus.Add("&File", FileMenu)
        this.BarMenus.Add("&Search", SearchMenu)
        this.BarMenus.Add("Settings", SettingsMenu)
    }
}

class GuiManager {
    static InterfaceSettings := {
        fontStyle: " w500 ",
        maxRowsInCol: 9,
        maxLineLen : 25,
        maxFileNameLines: 3
    }

    static ToggleMenu() {
        if (ScriptManager.State.isGuiShowed)
            this.HideMenu()
        else{
            ScriptManager.State.hActiveWnd := WinExist("A")
            this.ShowMenu()
        }
    }

    static ShowMenu() {
        global MainGui := Gui("+AlwaysOnTop -MinimizeBox", ScriptManager.scriptName)
        MainGui.SetFont(this.InterfaceSettings.fontStyle)
        MainGui.OnEvent("Close", GuiManager.HideMenu)
        MainGui.OnEvent("Escape", GuiManager.HideMenu)
        MainGui.MenuBar := ScriptManager.BarMenus
        
        GuiManager.ButtonCreate()
        MainGui.Show()
        ScriptManager.State.isGuiShowed := true
    }

    static HideMenu(*) {      
        HotkeyManager.ClearSnippetHotkeys()
        try SearchGui.Destroy() 
        MainGui.Hide()

        ScriptManager.State.isGuiShowed := false
        ScriptManager.State.hActiveWnd := ""
    }

    static RefreshMenu() {
        this.HideMenu()
        this.ShowMenu()
    }

    static ButtonCreate() {
        ScriptManager.Files := FileOperations.GetFilesFromDirectory()
        FilesCount := ScriptManager.Files.Length

        if (FilesCount == 0) {
            MainGui.Add("Button", "Default h50 w150", "Default folder")
                .OnEvent("Click", ((f) => (*) => FileOperations.ChangeFolderPath(f))("default"))
            return
        }

        maxRowsInCol := this.InterfaceSettings.maxRowsInCol * (FilesCount // (this.InterfaceSettings.maxRowsInCol * 10) + 1)
        rowCounter := 0

        for index, File in ScriptManager.Files {
            index := A_Index
            rowCounter := rowCounter + 1

            fileName := File.Name
            filePath := File.FilePath
            isFolder := File.IsFolder

            buttonLabel := this.GetButtonLabel(index, fileName)

            if (isFolder == "D")
                callback := ((f) => (*) => FileOperations.ChangeFolderPath(f))(filePath)
            else
                callback := ((f) => (*) => FileOperations.GetFileContent(f))(filePath)

            MainGui.Add("Button", "Left h50 w150", "  " . buttonLabel).OnEvent("Click", callback)

            if (index <= 18 && ScriptManager.Config.disableSnippetHotkeys == 0)
                HotkeyManager.SetupButtonHotkey(index, filePath, callback)

            if (index != FilesCount && rowCounter == maxRowsInCol) {
                MainGui.Add("Text", "y-0 h1 w150", " ")
                rowCounter := 0
            }        
        }
    }
    
    static GetButtonLabel(index, fileName) {
        if (index <= 9 && ScriptManager.Config.disableSnippetHotkeys == 0)
            fileName := index . ". " . fileName
        else if (index <= 18 && ScriptManager.Config.disableSnippetHotkeys == 0)
            fileName := "F" . index - 9 . ". " . fileName
        else
            fileName := "   " . fileName

        maxLineLen := this.InterfaceSettings.maxLineLen
        lineCounter := 1
        tempName := fileName
        name := ""

        while (StrLen(tempName) > maxLineLen && lineCounter <= this.InterfaceSettings.maxFileNameLines) {
            namePart := SubStr(tempName, 1, maxLineLen)

            if RegExMatch(namePart, ".*[ _]", &match)
                phraseLen := StrLen(match[0])  
            else
                phraseLen := maxLineLen 
            
            name := name . SubStr(tempName, 1, phraseLen) 
            
            if (lineCounter < this.InterfaceSettings.maxFileNameLines)
                name := name . "`n      "
            tempName := SubStr(tempName, phraseLen + 1) 
            lineCounter := lineCounter + 1
        }

        if (lineCounter < this.InterfaceSettings.maxFileNameLines)
            name := name . tempName

        return name
    }

    static ShowMsgBox(info) {
        msg := ""
        if (info == "FolderWarning") {
            msg := "Selected folder doesn't exist. " . ScriptManager.scriptName  . " redirected to the parent folder."
        }
        else if (info == "Settings") {
            msg :=  ScriptManager.GetSettingsString()
        }
        else if (info == "About") {
            msg :=  "Toggle menu hotkey`n  Key combination: " . ScriptManager.Config.menuToggleHotkey . "`n  Modifiers symbols: Alt -> !  Control -> ^  Shift -> +`n`n" .
                    "Alternative way to use MenuBar`n  Alt + {underlined letter of menubar option}`n`n" .
                    "File ordering`n  For ordered files, use numbered prefixes with a dollar sign.`n  The prefix length must be the same for all files.`n  For example: '23$File', '24$File2'`n`n" .
                    "DocJnt©"
        }
        MsgBox msg, info, "OK 0x40000"
    }

    static ShowSearchGui() {
        global SearchGui := Gui("AlwaysOnTop -MinimizeBox", "Insert snippet name")
        searchInput := SearchGui.Add("Edit", "h20 w170")
        SearchGui.Add("Button", "w50 h30 Default", "Search").OnEvent("Click", ((*) => SearchButtonClicked()))
        SearchGui.Add("Button", "w50 h30 x+10", "Clear").OnEvent("Click", ((f) => (*) => FileOperations.SearchForSnippets(f))(""))
        SearchGui.Add("Button", "w50 h30 x+10", "Cancel").OnEvent("Click", ((*) => SearchCancel()))
        SearchGui.Show()
        SearchGui.OnEvent("Escape",SearchCancel)

        HotkeyManager.DisableSnippetHotkeys()

        SearchButtonClicked() {
            FileOperations.SearchForSnippets(searchInput.Value)
        }

        SearchCancel(*) {
            SearchGui.Destroy()
            HotkeyManager.EnableSnippetHotkeys()
        }
    }
}

class HotkeyManager {

    static SetupButtonHotkey(index, filePath, callback) {
        if (index <= 9) {                               
            try hotkeyNameNumpad := "Numpad" . index    
            try hotkeyNameNumeric := index

            try Hotkey(hotkeyNameNumpad, callback)
            try Hotkey(hotkeyNameNumpad,"On")
            ScriptManager.State.activeHotkeys[hotkeyNameNumpad] := callback

            try Hotkey(hotkeyNameNumeric, callback)      
            try Hotkey(hotkeyNameNumeric,"On")  
            ScriptManager.State.activeHotkeys[hotkeyNameNumeric] := callback
        }
        else if (index <= 18) {                         
            hotkeyNameFunction := "F" . index - 9       

            try Hotkey(hotkeyNameFunction, callback)      
            try Hotkey(hotkeyNameFunction,"On")  
            ScriptManager.State.activeHotkeys[hotkeyNameFunction] := callback
        }
        else
            return
    }

    static EnableSnippetHotkeys() {
        for hotkeyName, callback in ScriptManager.State.activeHotkeys {
            try Hotkey(hotkeyName, "On")
        }
    }

    static DisableSnippetHotkeys() {
        for hotkeyName, callback in ScriptManager.State.activeHotkeys {
            try Hotkey(hotkeyName, "Off")
        }
    }

    static ClearSnippetHotkeys() {
        this.DisableSnippetHotkeys()
        ScriptManager.State.activeHotkeys.Clear()
    }

    static ToggleMenuHotkey() {
        try {
            try Hotkey(ScriptManager.Config.menuToggleHotkey, "Off")
            
            if (ScriptManager.Config.disableMenuToggleHotkey == 0) {
                Hotkey(ScriptManager.Config.menuToggleHotkey, (*) => GuiManager.ToggleMenu())
                Hotkey(ScriptManager.Config.menuToggleHotkey, "On")
            }
        } catch Error as e {
            MsgBox("An error occurred while setting toggle hotkey: " . e.Message, "Error", "Icon! 0x40000")
        }
    }
}

class FileOperations {
    static GetFilesFromDirectory() {
        if (DirExist(ScriptManager.State.folderPath) != "D") {
            GuiManager.ShowMsgBox("FolderWarning")
            this.ChangeFolderPath("parent")
            return []
        }

        Items := []
        try {
            Loop Files, ScriptManager.State.folderPath "\*.*", "DF" {
                SplitPath(A_LoopFilePath, &fileName)

                ;if (InStr(FileGetAttrib(A_LoopFilePath),"H") == 0)
                if (ScriptManager.State.searchPhrase == "" || (InStr(fileName, ScriptManager.State.searchPhrase) > 0)) {
                    isFolder := DirExist(A_LoopFilePath)
                    extension := ""

                    if (!isFolder && StrLen(fileName) > 4) && InStr(fileName,".") > 0{
                        fileName := SubStr(fileName, 1, -4)
                        extension := SubStr(fileName, -4, 4)
                    }
                    
                    fileOrderingSeparator := "$"
                    if (fileOrderingSeparator != "") {
                        fileOrderingEnd := InStr(fileName,  fileOrderingSeparator)
                    
                        if (fileOrderingEnd > 0)
                            fileName := SubStr(fileName, fileOrderingEnd+StrLen( fileOrderingSeparator), StrLen(fileName))
                    }

                    if (isFolder)
                        fileName := fileName . " [dir]"

                    Items.Push(Item(fileName, A_LoopFilePath, extension, isFolder))
                }
            }
        } catch Error as e {
            MsgBox("An error occurred while reading files: " . e.Message, "Error", "Icon! 0x40000")
        }

        if (Items.Length == 0) {
            MsgBox("No files found!", "Info", "OK 0x40000")

            if (ScriptManager.State.searchPhrase != "") {
                ScriptManager.State.searchPhrase := ""
                GuiManager.RefreshMenu()
            }
        }

        return Items
    }
    

    static GetFileContent(filePath) {
        prevClipboardContent := A_Clipboard
        A_Clipboard := ""
        fileContent := ""

        if (ScriptManager.Config.insertSnippetIntoActiveWin == 0 && ScriptManager.Config.copySnippetIntoClipboard == 0) {
            ToolTip "No output method enabled."
            SetTimer () => ToolTip(), -1200 
            return
        }

        try {
            fileContent := FileRead(filePath, "UTF-8")

            if (fileContent == "") {
                ToolTip "File has no content"
                SetTimer () => ToolTip(), -750  
                return        
            }

            A_Clipboard := fileContent
            if (!ClipWait(1)) {
                MsgBox("Clipboard copy timed out", "Error", "Icon! 0x40000")
                return
            }
        } catch Error as e {
            MsgBox("An error occurred while reading file: " . e.Message, "Error", "Icon! 0x40000")
        }

        if (ScriptManager.Config.insertSnippetIntoActiveWin == 1)
            this.InsertIntoWindow()
        
        if (ScriptManager.Config.copySnippetIntoClipboard == 0) {
            Sleep 100
            A_Clipboard := prevClipboardContent
        }    

        if (ScriptManager.Config.hideMenuAfterUse == 1) {
            GuiManager.HideMenu()
        }else{
            ToolTip "Done"
            SetTimer () => ToolTip(), -750  
        }
    }
   
    static InsertIntoWindow() {
        try{
            WinActivate ScriptManager.State.hActiveWnd
            Sleep 100
            Send "^v"
        }
    }

    static SearchForSnippets(phrase) {
        ScriptManager.State.searchPhrase := phrase
        GuiManager.RefreshMenu()
    }

    static ChangeFolderPath(option) {
        GuiManager.HideMenu()
        
        if (option == "select") {
            selectedPath := DirSelect("*" A_ScriptDir, 3, "Select a folder")

            if (selectedPath != "")
                ScriptManager.State.folderPath := selectedPath
        }
        else if (option == "default") {
            ScriptManager.State.folderPath := ScriptManager.Config.defaultFolderPath   
        }
        else if (option == "parent") {
            SplitPath ScriptManager.State.folderPath, &filename, &parentDir
            ScriptManager.State.folderPath := parentDir
        }
        else{
            ScriptManager.State.folderPath := option
        }
        
        ScriptManager.State.searchPhrase := ""
        GuiManager.ShowMenu()
    }
}

class Item{
    __New(name, filePath, extension, isFolder) {
        this.Name := name
        this.FilePath := filePath
        this.Extension := extension
        this.IsFolder := isFolder
    }
}

ScriptManager.Init()



