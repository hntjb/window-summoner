﻿#Include utils.ahk
#Include ../app.ahk

; id - onExitHandlers
wndHandlers := Map()

; 活跃的已唤起窗口
activatedWnd := false

; Toggle between hidden and shown
toggleWnd(id, entry := unset) {
  if (!IsSet(entry)) {
    return false
  }
  static pending := false
  ; Prevent concurrent actions only if singleActiveWindow is on
  ; * Every hotkey is running on a separate thread, so we need to use a static variable to keep track of the state
  if (config["misc"]["singleActiveWindow"] && pending) {
    return id
  }
  pending := true
  global wndHandlers
  global activatedWnd
  global config

  ; Try to capture window
  if (!id || !WinExist(id)) {
    id := _capture()
  }
  if (!id) {
    ; If still not found, run the program
    _hideActive()
    id := _run()
  } else {
    ; Otherwise, toggle it
    if (!config["misc"]["minimizeInstead"]) {
      ; Hide / Show
      isVisible := WinGetStyle(id) & 0x10000000
      if (isVisible && WinActive(id)) {
        _hide(id, true)
      } else {
        _hideActive()
        _show(id)
      }
    } else {
      ; Minimize / Restore
      if (WinActive(id)) {
        _minimize(id)
      } else {
        _hideActive()
        _restore(id)
      }
    }
  }
  pending := false
  return id

  _capture() {
    ; Try to match existing window
    if (config["misc"]["reuseExistingWindow"] && entry["wnd_title"] && WinExist(entry["wnd_title"])) {
      return WinGetID(entry["wnd_title"])
    }
  }
  _run() {
    if (entry["run"] == "") {
      return
    }
    Run(entry["run"])
    TIMEOUT := entry["wnd_title"] ? 30000 : 5000
    INTERVAL := 50
    ; If not found, wait for a new window
    currentWnd := WinGetActiveID()
    currentTime := A_TickCount
    while (A_TickCount - currentTime < TIMEOUT) {
      newWnd := WinGetActiveID()
      ; We only care about new windows
      if (newWnd != currentWnd) {
        ; If wnd_title is provided, match it
        if (!entry["wnd_title"] || WinGetTitle(newWnd) ~= entry["wnd_title"]) {
          activatedWnd := newWnd
          return newWnd
        }
      }
      Sleep(INTERVAL)
    }
  }

  _hide(id, restoreLastFocus := false) {
    try {
      ; (config["misc"]["transitionAnim"]) && WinHide(id)
      if (restoreLastFocus) {
        (config["misc"]["transitionAnim"]) && WinMinimize(id)
        (!config["misc"]["transitionAnim"]) && Send("!{Esc}")
      }
      WinHide(id)
      activatedWnd := false
    }
    ; Handle exit, try to reuse handler
    if (!wndHandlers.Has(String(id))) {
      ; id is remembered in closure
      exitHandler := (e, c) {
        try {
          isVisible := WinGetStyle(id) & 0x10000000
          if (!isVisible) {
            WinMinimize(id)
          }
        }
      }
      ; Keep a record of bound exitHandlers
      wndHandlers.Set(String(id), exitHandler)
      OnExit(exitHandler, 1)
      OnError(exitHandler, 1)
    }
  }

  _show(id) {
    try {
      WinShow(id)
      (!config["misc"]["transitionAnim"]) && WinActivate(id)
      (config["misc"]["transitionAnim"]) && WinActivate(id)
      activatedWnd := id
    }
  }
  _minimize(id) {
    try {
      WinMinimize(id)
      activatedWnd := false
    }
  }
  _restore(id) {
    try {
      if (WinGetMinMax(id) == -1)
        WinRestore(id)
      WinActivate(id)
      activatedWnd := id
    }
  }
  _hideActive() {
    if (config["misc"]["singleActiveWindow"] && activatedWnd) {
      if (!config["misc"]["minimizeInstead"])
        _hide(activatedWnd)
      else
        _minimize(activatedWnd)
    }
  }
}
clearWndHandlers() {
  global wndHandlers
  global activatedWnd
  activatedWnd := false
  for id, handler in wndHandlers {
    try {
      OnExit(handler, 0)
      OnError(handler, 0)
      handler("", "")
    }
  }
  wndHandlers := Map()
}