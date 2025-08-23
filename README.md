# CopyBoard

A lightweight text snippet manager for AutoHotkey v2 that provides quick access to frequently used text files.

Features
- Instant GUI access to all text files in a specified folder
- Hotkey suport for the first 18 files while the GUI is displayed
- Search functionality for files by name
- Simple and clean user interface
- No file extension validation
    

Configuration - Edit the config.ini file to customize behavior:
- ToggleMenuHotkey  	<- define menu toggling hotkey
- DefaultFolderPath     <- define default folder

        
        https://www.autohotkey.com/docs/v2/KeyList.htm
        Modifiers:
        Alt         -> !
        Control     -> ^
        Shift       -> +

        ToggleMenuHotkey setting can contain more than one modifier and one key
        Example: ^!1 -> Control & Alt & 1

