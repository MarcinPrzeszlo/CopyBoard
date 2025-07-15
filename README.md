# CopyBoard

A lightweight text snippet manager for AutoHotkey v2 that provides quick access to frequently used text files.

Features
    Instant GUI access to all text files in a specified folder
    Support for hotkeys while displaying gui
    File list refresh after hide&show gui
    Automatic file content refersh
    Simple and clean user interface
    No file extension validation 
    
    // not yet - Supports multiple text formats including .txt, .ahk, .json, .csv, .sql


Configuration - Edit the config.ini file to customize behavior:
    AbsoluteFolderPath      - define default folder
    ToggleMenuHotkey = ^!1  - define menu toggling hotkey
        
        https://www.autohotkey.com/docs/v2/KeyList.htm
        Modifiers:
        Alt         -> !
        Control     -> ^
        Shift       -> +

        ToggleMenuHotkey setting can contain more than one modifier and one key ('1', 'm')
        Example: ^!1 -> Control & Alt & 1


