﻿#Include utils.ahk

; id - onExitHandlers
wndHandlers := Map()

; 上一个活跃的非唤起窗口
lastUserWnd := 0

; 活跃的已唤起窗口
activatedWnds := []

; 暂时禁用了，对性能的影响待观察
updateLastActive() {
  global activatedWnds
  global lastUserWnd
  if (activatedWnds) {
    try {
      currentWnd := WinGetID("A")
      if (!hasVal(activatedWnds, currentWnd)) {
        lastUserWnd := currentWnd
      }
    }
  }
}
startTimer() {
  ; SetTimer(updateLastActive, 500)
}
stopTimer() {
  ; SetTimer(updateLastActive, 0)
}


; Toggle between hidden and shown
toggleWnd(id, entry := unset) {
  static pending := false
  if (pending) {
    return
  }
  pending := true
  global wndHandlers
  global activatedWnds
  global lastUserWnd

  ; 存在id，且窗口存在
  if (id && WinExist(id)) {
    if (!config["misc"]["minimizeInstead"]) {
      ; 隐藏
      isVisible := WinGetStyle(id) & 0x10000000
      if (isVisible && WinActive(id)) {
        _hide(id)
      } else {
        _show(id)
      }
    } else {
      ; 最小化
      if (WinActive(id)) {
        _minimize(id)
      } else {
        _restore(id)
      }
    }
  }
  ; 不存在id，且entry存在
  else if (IsSet(entry)) {
    if (config["misc"]["singleActiveWindow"] && activatedWnds.Length > 0) {
      if (!config["misc"]["minimizeInstead"])
        _hide(activatedWnds[1], false)
      else
        _minimize(activatedWnds[1])
    }
    _run()
  }

  _run() {
    Run(entry["run"])
    if (entry["wnd_title"] !== "") {
      id := WinWait(entry["wnd_title"])
    } else {
      currentWnd := WinGetLatest()
      while (WinGetLatest() == currentWnd) {
        Sleep(50)
      }
      id := WinGetLatest()
    }
    activatedWnds.push(id)
  }

  _hide(id, restoreLastActive := true) {
    try {
      deleteVal(activatedWnds, id)
      WinHide(id)
      try {
        if (restoreLastActive) {
          if (activatedWnds.Length > 0) {
            WinActivate(lastOf(activatedWnds))
          }
          else if (lastUserWnd)
            WinActivate(lastUserWnd)
        }
      }

      ; Handle exit, try to reuse handler
      if (wndHandlers.Get(String(id), false)) {
        exitHandler := wndHandlers[String(id)]
      } else {
        ; id is remembered in closure
        exitHandler := (e, c) {
          try {
            isVisible := WinGetStyle(id) & 0x10000000
            if (!isVisible) {
              WinShow(id)
            }
          }
        }
        ; Keep a record of bound exitHandlers
        wndHandlers.Set(String(id), exitHandler)
      }
      OnExit(exitHandler, 1)
      OnError(exitHandler, 1)
    }
  }
  _show(id) {
    try {
      try {
        currentWnd := WinGetID("A")
        if (!hasVal(activatedWnds, currentWnd)) {
          lastUserWnd := currentWnd
        }
      }
      if (config["misc"]["singleActiveWindow"] && activatedWnds.Length > 0 && activatedWnds[1] !== id) {
        _hide(activatedWnds[1], false)
      }
      WinShow(id)
      WinActivate(id)
      ; Remove exit handler
      if (wndHandlers.Get(String(id), false)) {
        OnExit(wndHandlers[String(id)], 0)
        OnError(wndHandlers[String(id)], 0)
      }
      deleteVal(activatedWnds, id)
      activatedWnds.Push(id)
    }
  }
  _minimize(id) {
    try {
      deleteVal(activatedWnds, id)
      WinMinimize(id)
    }
  }
  _restore(id) {
    try {
      ; lastActive := WinGetID("A")
      if (config["misc"]["singleActiveWindow"]) {
        if (activatedWnds.Has(1) && activatedWnds[1] !== id) {
          _minimize(activatedWnds[1])
        }
      }
    }
    try {
      if (WinGetMinMax(id) == -1)
        WinRestore(id)
      WinActivate(id)
      activatedWnds := [id]
    }
  }
  pending := false
  return id
}
clearWndHandlers() {
  global wndHandlers
  global activatedWnds
  global lastUserWnd
  activatedWnds := []
  lastUserWnd := 0
  for id, handler in wndHandlers {
    try {
      handler("", "")
      OnExit(handler, 0)
      OnError(handler, 0)
    }
  }
  wndHandlers := Map()
}