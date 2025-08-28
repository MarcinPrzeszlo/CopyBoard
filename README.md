# CopyBoard

A lightweight text snippet manager for AutoHotkey v2 that provides quick access to frequently used text files.

Features:
- Instant GUI access to all text files in a specified folder
- Direct snippet insertion into active window 
- Copy snippet to clipboard
- Hotkey support (1-9, F1-F9) for selecting the first 18 snippets while menu is open
- Search functionality for files by name
- Simple and clean user interface
- Configurable script behavior


Technical details:
- No file extension validation


Configuration file:
- Behaviour can be customized by editing the config.ini file.


Settings description:
 - ToggleMenuHotkey - hotkey definiton which is used to toggle menu visibility
      - Modifiers symbols: Alt -> !  Control -> ^  Shift -> +
     - This settings can contain multiple modifiers and one key. See the <a href="https://www.autohotkey.com/docs/v2/KeyList.htm">Key List</a> for options. 
     - Example: ^!1 -> Control & Alt & 1
       
- DefaultFolderPath - absolute path to the folder where text snippets are stored.
- InsertSnippetIntoActiveWin [0,1] - If 1, the selected snippet is inserted into the window that was active before the GUI was displayed.
- CopySnippetIntoClipboard [0,1] - If 1, the selected snippet is inserted into clipboard.
- DisableMainGuiHotkeys [0,1] - If 1, the keys 1-9 and F1-F9 will not be bound to snippet selection .
- HideMenuAfterUse [0,1] - If 1, the menu will automatically hide after a snippet is selected.


Requirements: 
 - AutoHotkey v2: <a href="https://www.autohotkey.com/download/ahk-v2.exe">Download here</a>
 - OS: Windows 7 or later
