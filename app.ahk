﻿#SingleInstance Force
DetectHiddenWindows(true)
SetTitleMatchMode("RegEx")
SetTitleMatchMode("Fast")
A_FileEncoding := "UTF-16"
VERSION_NUMBER := FileRead(A_ScriptDir "\data\version.txt", "utf-8")

#Include scripts\configuration.ahk
#Include scripts\utils.ahk
#Include scripts\main.ahk

config := readConfig()

class Configurator {
  __New() {
    global config
    this.config := config
  }
  createGui() {
    this._skeleton()
    this._menu()
    this._dynamicTab()
    this._miscTab()
    this._shortcutTab()
    this.gui.Show()
    this.gui.OnEvent("Close", (*) {
      this.gui.Destroy()
      this.gui := unset
      for gui in this.subGuis {
        gui.Destroy()
      }
      this.subGuis := []
      if (!this.isMainRunning) {
        ExitApp()
      }
    })
  }
  _skeleton() {
    this.guiWidth := 450
    this.guiHeight := 300
    guiSizeOpt := "MinSize" . this.guiWidth + 10 . "x" . this.guiHeight + 5
      . " MaxSize" . this.guiWidth + 10 . "x" . 9999
    ; Set gui Icon
    WS_MAXIMIZEBOX := 0x00010000
    WS_VSCROLL := 0x00200000
    this.gui := Gui("+Resize "
      "-" WS_MAXIMIZEBOX
      " " WS_VSCROLL
      " " guiSizeOpt
      ; " +Scroll",
      , "呼来唤去",)
    this.gui.MarginX := 2
    this.gui.MarginY := 5

    this.subGuis := []

    TCS_BUTTONS := 0x0100
    TCS_OWNERDRAWFIXED := 0x2000
    TCS_HOTTRACK := 0x0040
    TCS_FLATBUTTONS := 0x0008
    this.tab := this.gui.AddTab2(s({
      w: this.guiWidth,
      h: 19, %TCS_HOTTRACK%: "", %TCS_BUTTONS%: "", %TCS_FLATBUTTONS%: "",
      ; "Bottom": "",
      ; "Background": "White",
    }), ["热键", "绑定", "其它"])

    this.tab.UseTab(0)
    BS_FLAT := 0x8000
    btn := this.gui.AddButton(s({ x: this.guiWidth - 35, y: "s-5", }), "应用")
    btn.OnEvent(
      "Click", (gui, info) {
        ; writeConfig(this.config)
        if (this.isMainRunning) {
          this._stopMainScript()
            ; Sleep(100)
          writeConfig(this.config)
          this._startMainScript()
        }
        MsgBox("已应用新配置")
      }
    )
    ; this.gui.AddButton(s({ y: "p" }), "取消").OnEvent(
    ;   "Click", (gui, info) {
    ;     this.gui.Destroy()
    ;   }
    ; )
    this.gui.AddText("section y+-30", "")
    this.gui.MarginY := 0
  }
  _menu() {
    global VERSION_NUMBER
    aboutMenu := Menu()
    aboutMenu.Add("版本：" VERSION_NUMBER, (name, pos, menu) {
      Run("https://github.com/john-walks-slow/window-summoner")
    },)

    scriptMenu := Menu()
    scriptMenu.Add("运行", (name, pos, menu) {
    })
    scriptMenu.Add("重启", (name, pos, menu) {
    })
    scriptMenu.Add("停止", (name, pos, menu) {
    })
    this.gui.MenuBar := MenuBar()
    this.STATE_RUNNING := "⏹ 停止"
    this.STATE_IDLE := "▶️  启动"
    this.gui.MenuBar.Add(this.isMainRunning ? this.STATE_RUNNING : this.STATE_IDLE,
      (name, pos, menu) {
        try {
          if (this.isMainRunning) {
            this._stopMainScript()
          } else {
            writeConfig(this.config)
            this._startMainScript()
          }
        }
      }
    )
    this.gui.MenuBar.Add("关于", aboutMenu)
  }
  _dynamicTab() {
    this.tab.UseTab(2)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    dynamicConfig := this.config["dynamic"]
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, '启用动态绑定', dynamicConfig, "enable", "section xs ys")
    this._addComponent(this.COMPONENT_CLASS.LINK, '?', , , "ys").OnEvent("Click", (*) {
      MsgBox(
        "即时绑定需要控制的窗口。`n"
        "例：在浏览文档时按 Win + Shift + 7，之后 Win + 7 就会显示/隐藏文档。`n"
        , "帮助")
    })
    this.gui.AddText("section xs y+10", "修饰键（绑定）  ")
    this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, false, dynamicConfig, "mod_bind")
    this.gui.AddText("section xs y+10", "修饰键（切换）  ")
    this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, false, dynamicConfig, "mod_main")
    this._addComponent(this.COMPONENT_CLASS.SUFFIX_INPUT, "后缀键", dynamicConfig, "suffixs")
    this.gui.AddLink(s({ x: "+5", y: "s" }), '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "可以用作后缀键的字符。`n"
          , "帮助")
      }
    )
    this.gui.AddGroupBox(s({ section: "", w: this.guiWidth - 20, r: 2.5, x: 10, y: "+1" }))
    this.gui.AddText("section xs+5 ys+15 w270 c444444", "[绑定+后缀]: 绑定该后缀到当前活动窗口。`n[切换+后缀]: 显示/隐藏绑定的窗口。")
  }
  _shortcutTab() {
    this.tab.UseTab(1)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    shortcutConfig := this.config["shortcuts"]
    c1 := 10
    c2 := this.guiWidth * 0.3
    c3 := this.guiWidth * 0.65
    c4 := this.guiWidth - 20
    w1 := c2 - c1 - 7
    w2 := c3 - c2 - 7
    w3 := c4 - c3 - 7
    w4 := 20
    /** Headers */
    this.gui.SetFont("c787878")
    this.gui.AddLink(s({ section: "", x: c1, y: "s" }), "程序 " '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "要启动的程序、文件或快捷方式`n"
          , "帮助")
      }
    )
    this.gui.AddLink(s({ x: c2, y: "s" }), "热键 " '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "为程序设置热键。`n"
          "# 代表 Win，! 代表 Alt，^ 代表 Ctrl, + 代表 Shift。`n`n"
          "例：" "^!+q 表示 Ctrl + Alt + Shift + Q"
          , "帮助")
      }
    )

    this.gui.AddLink(s({ x: c3, y: "s" }), "窗口标题正则 (可选) " '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox("若省略，『呼来唤去』会自动捕捉启动程序后出现的第一个新窗口`n`n"
          "在以下情况下本选项会有帮助：`n"
          "- 该程序有启动画面或需要忽略的弹窗`n"
          "- 希望捕捉并非由『呼来唤去』启动的程序窗口`n"
          "- 需要提高稳定性`n"
          , "帮助")
      }
    )
    this.gui.SetFont("")

    ; this.gui.AddProgress(s({ Background: "AAAAAA", h: 1, w: this.guiWidth - 50, x: "s", y: "+5" }))

    this.gui.AddButton(s({ x: c4, y: "s-7", }), "+").OnEvent(
      "Click", (gui, info) {
        this.tab.UseTab(1)
        shortcutConfig.Push(UMap("hotkey", "", "run", "", "wnd_title", ""))
        shortcutRow(shortcutConfig.Length, shortcutConfig[shortcutConfig.Length], false)
      }
    )

    isFirst := false
    for index, entry in shortcutConfig {
      shortcutRow(index, entry, isFirst)
      isFirst := false
    }
    shortcutRow(index, entry, isFirst) {
      appSelectTxt() {
        RegExMatch(entry["run"], "([^\\]+?)(\.[^.]*)?$", &match)
        ; this.gui.AddText(s({ section: "", x: "s", y: isFirst ? "s" : "+10" }), match[1])
        return match ? match[1] : false
      }
      appSelect := this.gui.AddButton(s({ section: "", x: "s", y: isFirst ? "s" : "+-1", w: w1, r: 1, "-wrap -VScroll": "" }), appSelectTxt() || "选择")
      appSelect.OnEvent(
        "Click", (gui, info) {
          fileChoice := FileSelect(32)
          if (fileChoice) {
            entry["run"] := fileChoice
            gui.Text := appSelectTxt() || "选择"
          }
        }
      )
      hotkeyButton := this.gui.AddButton(s({ x: c2, y: "s", w: w2, r: 1, "-wrap -VScroll": "" }), FormatHotkeyShorthand(entry["hotkey"]))
      hotkeyButton.onEvent("Click", (target, info) {
        customHotkeyWnd := Gui("-MinimizeBox -MaximizeBox", appSelect.Text == "选择" ? "配置热键" : "配置 " appSelect.Text " 的热键")
        this.subGuis.Push(customHotkeyWnd)
        customHotkeyWnd.MarginX := 10
        customHotkeyWnd.MarginY := 10
        hotkeyObj := ParseHotkeyShorthand(entry["hotkey"])
        customHotkeyWnd.AddText("section y+10 w0 h0", "")
        this._addComponent(this.COMPONENT_CLASS.MOD_SELECT, "", hotkeyObj, "mods", false, customHotkeyWnd)
        customHotkeyWnd.AddEdit(s({ x: "+2", y: "s-3", w: 20 }), StrUpper(hotkeyObj.key)).OnEvent("Change", (target, info) {
          static oldVal := ""
          splited := StrSplit(target.Value)
          if (splited.Length > 0) {
            key := StrLower(splited.Get(splited.FindIndex(v => v != oldVal) || 1))
          } else {
            key := ""
          }
          hotkeyObj["key"] := key
          target.Value := StrUpper(key)
          oldVal := target.Value
        })
        customHotkeyWnd.AddButton(s({ x: "s" }), "应用").OnEvent("Click", (gui, info) {
          entry["hotkey"] := ToShorthand(hotkeyObj)
          hotkeyButton.Text := FormatHotkeyShorthand(entry["hotkey"])
          customHotkeyWnd.Destroy()
        })
        customHotkeyWnd.AddButton(s({ x: "+5" }), "取消").OnEvent("Click", (gui, info) {
          customHotkeyWnd.Destroy()
        })
        customHotkeyWnd.Show()
      })
      titleInput := this.gui.AddEdit(s({ y: "s+2", x: c3, w: w3, r: 1, "-wrap -VScroll": "" }), entry["wnd_title"])
      titleInput.onEvent("Change", (gui, info) {
        entry["wnd_title"] := gui.Value
      })
      removeBtn := this.gui.AddButton(s({ x: c4, y: "s" }), "-")
      removeBtn.OnEvent(
        "Click", (gui, info) {
          this.config["shortcuts"].RemoveAt(index)
          this._refreshGui()
        })
    }

  }
  COMPONENT_CLASS := {
    "CHECKBOX": "checkbox",
    "MOD_SELECT": "mod_select",
    "SUFFIX_INPUT": "suffix_input",
    "LINK": "link",
  }
  ; Create a component of a given type, and bind it to the data
  _addComponent(guiType, payload := "", data := 0, dataKey := 0, styleOpt := false, gui := this.gui) {
    if (IsObject(styleOpt)) {
      styleOpt := s(styleOpt)
    }
    if (data && dataKey) {
      dataValue := data[dataKey]
    }
    switch guiType {
      case this.COMPONENT_CLASS.LINK:
        return gui.AddLink(styleOpt || "ys", "<a>" payload "</a>")
      case this.COMPONENT_CLASS.CHECKBOX:
        checkbox := gui.AddCheckbox(styleOpt || "section xs y+10", payload)
        checkbox.Value := dataValue
        checkbox.OnEvent("Click", (gui, info) {
          data[dataKey] := gui.Value
        })
        return checkbox
      case this.COMPONENT_CLASS.MOD_SELECT:
        modDict := UMap("#", "Win", "^", "Ctrl", "!", "Alt", "+", "Shift")
        isFirst := true
        for modKey, modText in modDict {
          addMod(modKey, modText, isFirst)
          isFirst := false
        }
        addMod(modKey, modText, isFirst) {
          option := isFirst ? "ys x+0" : "ys x+0"
          checkbox := gui.AddCheckbox(option, modText)
          checkbox.Value := hasVal(dataValue, modKey)
          checkbox.OnEvent("Click", (gui, info) {
            if (gui.Value) {
              pushDedupe(dataValue, modKey)
            } else {
              deleteVal(dataValue, modKey)
            }
          })
        }
      case this.COMPONENT_CLASS.SUFFIX_INPUT:
        gui.AddText(styleOpt || "section xs y+15", payload)
        edit := gui.AddEdit("ys-5 x+5 w200", joinStrs(dataValue))
        edit.onEvent("Change", (gui, info) {
          data[dataKey] := dedupe(StrSplit(gui.Value))
            ; gui.Value := joinStrs(config[dataKey])
        })
      default:
    }
  }
  _miscTab() {
    this.tab.UseTab(3)
    this.gui.AddText("section x+10 y+10 w0 h0", "")
    miscConfig := this.config["misc"]
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "开机自启动", miscConfig, "autoStart", "section xs ys")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "捕获从别处启动的程序实例", miscConfig, "reuseExistingWindow")
    this.gui.AddLink(s({ x: "+0", y: "s" }), '<a href="/">?</a>').OnEvent(
      "Click", (*) {
        MsgBox(
          "根据『窗口标题正则』，尝试在现有窗口中捕获目标程序。`n"
          "若取消勾选，『呼来唤去』只会捕获由自己启动的程序窗口。`n"
          , "帮助")
      }
    )
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "唤起新窗口时隐藏当前唤起的窗口", miscConfig, "singleActiveWindow")
    this._addComponent(this.COMPONENT_CLASS.CHECKBOX, "最小化而不是隐藏", miscConfig, "minimizeInstead")
  }
  _refreshGui(opt?) {
    oldGui := this.gui
    ; oldGui.Visible := false
    ; oldGui.GetClientPos(&oldX, &oldY)
    ; oldGui.GetPos(&oldX, &oldY, &oldWidth, &oldHeight)
    this.createGui()
    this.gui.Show(
      ; "X" . oldX " Y" . oldY " W" . oldWidth " H" . oldHeight
    )
    oldGui.Destroy()
  }
  isMainRunning := false
  _startMainScript() {
    if (!this.isMainRunning) {
      main()
      this.isMainRunning := true
      if (this.HasProp("gui")) {
        this.gui.MenuBar.Rename(this.STATE_IDLE, this.STATE_RUNNING)
      }
    }
  }
  _stopMainScript() {
    if (this.isMainRunning) {
      stopMain()
      this.isMainRunning := false
      if (this.HasProp("gui")) {
        this.gui.MenuBar.Rename(this.STATE_RUNNING, this.STATE_IDLE)
      }
    }
  }
}

setupTray()
instance := Configurator()
if (!hasVal(A_Args, "--no-gui")) {
  instance.createGui()
} else {
}
instance._startMainScript()


setupTray() {
  global ICON_PATH
  TraySetIcon(ICON_PATH)
  A_TrayMenu.Delete()
  openGui(*) {
    if (instance.HasProp("gui")) {
      instance._refreshGui()
    } else {
      instance.createGui()
    }
  }

  A_TrayMenu.Add("配置", openGui)
  A_TrayMenu.Add("退出", (*) {
    ExitApp()
  })
  OnMessage(0x404, (wParam, lParam, *) {
    ; user left-clicked tray icon
    if (lParam = 0x202) {
      return
    }
    ; user double left-clicked tray icon
    else if (lParam = 0x203) {
      openGui()
      return
    }
    ; user right-clicked tray icon
    if (lParam = 0x204) {
      return
    }
    ; user middle-clicked tray icon
    if (lParam = 0x208) {
      return
    }
  })
}