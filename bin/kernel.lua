local logs = {}
local w, h = term.getSize()

local function log(text)
  table.insert(logs, os.epoch('utc') .. " " .. text)
end

local function dumpLogs()
  local f = fs.open("dump.log", "w")
  f.write(table.concat(logs, "\n"))
  f.close()
end

local function loadtable(path)
  local file = fs.open(path, "r")
  local content = textutils.unserialize(file.readAll())
  file.close()
  return content
end

term.clear()
term.setCursorPos(1, 1)

print("Bem Vindo ao NewOS!")
sleep(0.5)
print()
print("Caregando Lista de Pacotes...")
local packageDirs = loadtable("/boot/package.path")
for i, v in pairs(packageDirs) do
    package.path = package.path .. ";" .. v
end
_G.package = package
print(package.path)
sleep(1)

-- animation

term.setBackgroundColor(colors.black)
term.clear()
term.setBackgroundColor(colors.green)
for i = 1, h do
    term.setCursorPos(1, i)
    term.clearLine()
    sleep(0.05)
end
local opus = {
			'555ddd5ddddddddddddddddddd55555ddd555555',
			'5dd5dd5dddddddddddddddddd5ddddd5d5dddddd',
			'5dd5dd5d55555555d5ddddd5d5ddddd5d5dddddd',
			'5dd5dd5d5dddddd5d5ddddd5d5ddddd5dd55555d',
			'5dd5dd5d5dddddd5d5ddddd5d5ddddd5ddddddd5',
			'5dd5dd5d5d55555dd5dd5dd5d5ddddd5ddddddd5',
			'5dd5dd5d5dddddddd5d5d5d5d5ddddd5ddddddd5',
			'5ddd555d55555555dd5ddd5ddd55555dd555555d',
		}
for k,line in ipairs(opus) do
   term.setCursorPos((w - 38) / 2, k + (h - #opus) / 2)
   term.blit(string.rep(' ', #line), string.rep('a', #line), line)
end
sleep(1)

--

local function main()
  local processes = {}
  local selectedProcessID = 0
  local selectedProcess
  local lastProcID = 0
  local native = term.current()
  local wm = {}
  local w, h = term.getSize()
  local titlebarID = 0
  local keysDown = {}

  local resizeStartX
  local resizeStartY
  local resizeStartW
  local resizeStartH
  local mvmtX = nil

  local util = require("util")
  local file = util.loadModule("file")
  local theme = file.readTable("/etc/colors.cfg")
  local serviceWindow = window.create(native, 1, 1, 1, 1, false)

  local top = 0

  local function updateProcesses()
    for i, v in pairs(processes) do
      term.redirect(v.window)
      coroutine.resume(v.coroutine)
    end
  end

  local function drawProcess(proc)
    if proc.showTitlebar == false then
      term.redirect(proc.window)
      if proc.maximazed then
        proc.window.reposition(1, 2, w, h - 1)
      else
        proc.window.reposition(proc.x, proc.y, proc.width, proc.height)
      end
      proc.window.redraw()
    else
      term.redirect(native)
      
      if proc.maximazed then
        proc.window.reposition(1, 3, w, h - 2)
        if proc == selectedProcess then
          paintutils.drawLine(1, 2, w, 2, theme.window.titlebar.backgroundSelected)
        else
          paintutils.drawLine(1, 2, w, 2, theme.window.titlebar.background)
        end
        term.setCursorPos(math.floor((w - string.len(proc.title) / 2) / 2), 2)
        term.setTextColor(theme.window.titlebar.text)
        term.write(proc.title)

        if not proc.disableControls then
          term.setCursorPos(1, 2)
          if proc == selectedProcess then
            term.setTextColor(theme.window.close)
          else
            term.setTextColor(theme.window.titlebar.text)
          end
          term.write("\7")
          if proc == selectedProcess then
            term.setTextColor(theme.window.minimize) 
          else
            term.setTextColor(theme.window.titlebar.text)
          end
          term.write("\7")
          if proc == selectedProcess then
            term.setTextColor(theme.window.maximize)
          else
            term.setTextColor(theme.window.titlebar.text)
          end
          term.write("\7")
        end
      else
        proc.window.reposition(proc.x, proc.y + 1, proc.width, proc.height)
        if proc == selectedProcess then
          paintutils.drawLine(proc.x, proc.y, proc.x + proc.width - 1, proc.y, theme.window.titlebar.backgroundSelected)
        else
          paintutils.drawLine(proc.x, proc.y, proc.x + proc.width - 1, proc.y, theme.window.titlebar.background)
        end
        term.setCursorPos(proc.x + math.floor((proc.width - string.len(proc.title)) / 2), proc.y)
        term.setTextColor(theme.window.titlebar.text)
        term.write(proc.title)

        if not proc.disableControls then
          term.setCursorPos(proc.x, proc.y)
          if proc == selectedProcess then
            term.setTextColor(theme.window.close)
          else
            term.setTextColor(theme.window.titlebar.text)
          end
          term.write("\7")
          if proc == selectedProcess then
            term.setTextColor(theme.window.minimize) 
          else
            term.setTextColor(theme.window.titlebar.text)
          end
          term.write("\7")
          if proc == selectedProcess then
            term.setTextColor(theme.window.maximize)
          else
            term.setTextColor(theme.window.titlebar.text)
          end
          term.write("\7")
        end
      end

      term.redirect(proc.window)
      proc.window.redraw()
    end
  end

  local function drawProcesses()
    term.redirect(native)
    term.setBackgroundColor(theme.desktop.background)
    term.clear()
    term.setCursorPos(33,19)
    term.setTextColor(colors.lime)
    term.write("Versão para testes\19")
    term.setCursorPos(1,5)
    
    if selectedProcess.minimized then
      wm.selectProcess(titlebarID or 1)
    else
      drawProcess(selectedProcess)
    end

    if selectedProcess.minimized == true then
      selectedProcessID = 1
      selectedProcess = processes[1]
    end

    for i, v in pairs(processes) do
      if i ~= selectedProcessID then
        if v.minimized then
          v.window.setVisible(false)
        else
          drawProcess(v)
        end
      end
    end
    drawProcess(selectedProcess)
    updateProcesses()
  end

  function wm.selectProcess(pid)
    if processes[pid] then
      selectedProcessID = pid
      selectedProcess = processes[pid]
      selectedProcess.window.setVisible(true)
      selectedProcess.window.redraw()
      drawProcesses()
    end
  end

  function wm.selectProcessAfter(pid, time)
    sleep(time)
    wm.selectProcess(pid)
  end

  function wm.unminimizeProcess(pid)
    processes[pid].minimized = false
  end

  function wm.listProcesses()
    return processes
  end

  function wm.getSelectedProcess()
    return selectedProcess
  end

  function wm.getSelectedProcessID()
    return selectedProcessID
  end

  function wm.endProcess(pid)
    local proc = processes[pid]
    if proc then
      if pid == selectedProcessID then
        wm.selectProcess(titlebarID)
      end
      proc.window.setVisible(false)
      processes[pid] = nil
      drawProcesses()
    end
  end

  local function removeDeadProcesses()
    for i, v in pairs(processes) do
      if coroutine.status(v.coroutine) == "dead" then
        wm.endProcess(i)
      end
    end
  end

  local function contains(tbl, elem)
    for i, v in pairs(tbl) do
      if elem == v then
        return true 
      end
    end
    return false
  end

  local function isKeyDown(id)
    for i, v in pairs(keysDown) do
      if v == id then
        return i
      end
    end
  end

  function wm.getSize()
    return native.getSize()
  end

  function wm.changeSettings(pid, newSettings)
    if not newSettings.title and type(path) == "string" then
      newSettings.title = fs.getName(path)
      if newSettings.title:sub(-4) == ".lua" then
        newSettings.title = newSettings.title:sub(1, -5)
      end
    elseif type(path) ~= "string" then
      newSettings.title = "Untitled"
    end

    if newSettings.showTitlebar == nil or newSettings.showTitlebar == true then
      newSettings.showTitlebar = true
    end

    if not newSettings.width then
      newSettings.width = 20
    end
    if not newSettings.height then
      newSettings.height = 10
    end

    if not newSettings.x then
      newSettings.x = math.ceil(w / 2 - (newSettings.width / 2))
    end
    if not newSettings.y then
      if (newSettings.height % 2) == 0 then
        newSettings.y = math.ceil(h / 2 - (newSettings.height / 2))
      else
        newSettings.y = math.ceil(h / 2 - (newSettings.height / 2)) + 1
      end
    end
    local process = processes[pid]
    newSettings.path = process.path
    newSettings.window = process.window
    newSettings.coroutine = process.coroutine
    
    processes[pid] = newSettings
  end

  function wm.createProcess(path, settings)
    lastProcID  = lastProcID + 1
    if not settings.title and type(path) == "string" then
      settings.title = fs.getName(path)
      if settings.title:sub(-4) == ".lua" then
        settings.title = settings.title:sub(1, -5)
      end
    elseif type(path) ~= "string" then
      settings.title = "Untitled"
    end

    if settings.showTitlebar == nil or settings.showTitlebar == true then
      settings.showTitlebar = true
    end

    if not settings.width then
      settings.width = 20
    end
    if not settings.height then
      settings.height = 10
    end

    if not settings.x then
      settings.x = math.ceil(w / 2 - (settings.width / 2))
    end
    if not settings.y then
      if (settings.height % 2) == 0 then
        settings.y = math.ceil(h / 2 - (settings.height / 2))
      else
        settings.y = math.ceil(h / 2 - (settings.height / 2)) + 1
      end
    end

    settings.path = path

    local newTable = table
    newTable["contains"] = contains

    local function run()
    end

    log(type(path))

    local req = _G.require

    if type(path) == "string" then
      run = function()
        _G.require = require
        _G.wm = wm
        _G.id = lastProcID
        _G.table = newTable
        _G.shell = shell

        os.run({
          _G = _G,
          package = package
        }, path)
        sleep(1000)
      end
    elseif type(path) == "function" then
      log("running as func")
      run = function()
        local wm = wm
        local id = lastProcID
        local table = newTable
        local textbox = textbox

        path(textbox)
      end
    end

    settings.window = window.create(native, settings.x, settings.y, settings.width, settings.height)
    term.redirect(settings.window)
    settings.coroutine = coroutine.create(run)
    coroutine.resume(settings.coroutine)
    settings.window.redraw()

    table.insert(processes, lastProcID, settings)
    return lastProcID
  end

  function wm.createService(path)
    lastProcID  = lastProcID + 1
    local function run() end
    local ins = {}
    if type(path) == "string" then
      run = function()
        _G.require = require
        _G.wm = wm
        _G.id = lastProcID
        _G.table = newTable
        _G.shell = shell

        os.run({
          _G = _G,
          package = package
        }, path)
        sleep(1000)
      end
    elseif type(path) == "function" then
      log("running as func")
      run = function()
        local wm = wm
        local id = lastProcID
        local table = newTable
        local textbox = textbox

        path(textbox)
      end
    end

    ins.coroutine = coroutine.create(run)
    ins.window = serviceWindow
    return lastProcID
  end

  local loginID = wm.createProcess("/bin/ui/login.lua", {
    showTitlebar = true,
    dontShowInTitlebar = true,
    disableControls = true,
    title = "Login",
    height = 7,
    y =  (h / 2) - 4
  })
  wm.selectProcess(loginID)
  wm.createService(function()
    sleep(5)
    os.reboot()
  end)

  drawProcesses()

  while true do
    local e = {os.pullEvent()}

    if string.sub(e[1], 1, 6) == "mouse_" and not selectedProcess.minimized then
      local m, x, y = e[2], e[3], e[4]
      -- Resize checking
      if resizeStartX ~= nil and m == 2 then
        log(e[1])
        if e[1] == "mouse_up" then 
          resizeStartX = nil
          resizeStartY = nil
          resizeStartW = nil
          resizeStartH = nil
          drawProcesses()
        elseif e[1] == "mouse_drag" then
          selectedProcess.width = (resizeStartW + (x - resizeStartX))
          selectedProcess.height = (resizeStartH + (y - resizeStartY))
          term.redirect(selectedProcess.window)
          coroutine.resume(selectedProcess.coroutine, "term_resize")
          drawProcesses()
        end
      -- Moving windows & x and max / min buttons
      elseif not selectedProcess.minimized and not selectedProcess.maximazed and selectedProcess.showTitlebar and x >= selectedProcess.x and x <= selectedProcess.x + selectedProcess.width - 1 and y == selectedProcess.y and e[1] == "mouse_click" and mvmtX == nil then
        if not selectedProcess.disableControls and x == selectedProcess.x and e[1] == "mouse_click" then
          wm.endProcess(selectedProcessID)
          drawProcesses()
        elseif not selectedProcess.disableControls and x == selectedProcess.x + 1 and e[1] == "mouse_click" then
          selectedProcess.minimized = true
          drawProcesses()
        elseif not selectedProcess.disableControls and x == selectedProcess.x + 2 and e[1] == "mouse_click" then
          selectedProcess.maximazed = true
          term.redirect(selectedProcess.window)
          coroutine.resume(selectedProcess.coroutine, "term_resize")
          drawProcesses()
        else
          mvmtX = x - selectedProcess.x
          drawProcesses()
        end
      -- Max window controls
      elseif selectedProcess.maximazed == true and y == 2 then 
        if not selectedProcess.disableControls and x == 1 and e[1] == "mouse_click" then
          wm.endProcess(selectedProcessID)
          drawProcesses()
        elseif not selectedProcess.disableControls and x == 2 and e[1] == "mouse_click" then
          selectedProcess.minimized = true
          drawProcesses()
        elseif not selectedProcess.disableControls and x == 3 then
          selectedProcess.maximazed = false
          term.redirect(selectedProcess.window)
          coroutine.resume(selectedProcess.coroutine, "term_resize")
          drawProcesses()
        end
      -- Window movement 
      elseif not selectedProcess.maximazed and selectedProcess.showTitlebar and x >= selectedProcess.x - 1 and x <= selectedProcess.x + selectedProcess.width and y >= selectedProcess.y - 1  and y <= selectedProcess.y + 1 and e[1] == "mouse_drag" or e[1] == "mouse_up" and mvmtX ~= nil then
        if e[1] == "mouse_drag" and mvmtX then
          selectedProcess.x = x - mvmtX + 1
          selectedProcess.y = y
          drawProcesses()
        else
          mvmtX = nil
        end
      elseif not selectedProcess.disallowResizing and x == selectedProcess.x + selectedProcess.width - 1 and y == selectedProcess.y + selectedProcess.height and m == 2 then
        if e[1] == "mouse_click" then
          resizeStartX = x
          resizeStartY = y
          resizeStartW = selectedProcess.width
          resizeStartH = selectedProcess.height
          log("resize start")
        end
      -- Passing events (not maximazed)
      elseif not selectedProcess.maximazed and x >= selectedProcess.x and x <= selectedProcess.x + selectedProcess.width - 1 and y >= selectedProcess.y and y <= selectedProcess.y + selectedProcess.height - 1 then
        term.redirect(selectedProcess.window)
        local pass = {}
        if selectedProcess.showTitlebar == true then
          pass = {
            e[1],
            m,
            x - selectedProcess.x + 1,
            y - selectedProcess.y
          }
        else
          pass = {
            e[1],
            m,
            x - selectedProcess.x + 1,
            y - selectedProcess.y + 1
          }
        end
        coroutine.resume(selectedProcess.coroutine, table.unpack(pass))
      -- Passing events (maximazed)
      elseif selectedProcess.maximazed and y > 2 then
        term.redirect(selectedProcess.window)
        local pass = {}
        if selectedProcess.showTitlebar == true then
          pass = {
            e[1],
            m,
            x,
            y - 2
          }
        else
          pass = {
            e[1],
            m,
            x,
            y - 1
          }
        end
        coroutine.resume(selectedProcess.coroutine, table.unpack(pass))
      elseif e[1] == "mouse_click" then
        for i, v in pairs(processes) do
          if x >= v.x and x <= v.x + v.width - 1 and y >= v.y and y <= v.y + v.height - 1 then
            wm.selectProcess(i)
            local pass = {}
            if selectedProcess.showTitlebar == true then
              pass = {
                e[1],
                m,
                x - selectedProcess.x + 1,
                y - selectedProcess.y
              }
            else
              pass = {
                e[1],
                m,
                x - selectedProcess.x + 1,
                y - selectedProcess.y + 1
              }
            end
            term.redirect(selectedProcess.window)
            coroutine.resume(selectedProcess.coroutine, table.unpack(pass))
            break
          end
        end
      end
    elseif e[1] == "char" or string.sub(e[1], 1, 3) == "key" or e[1] == "paste" then
      if e[1] == "key" then
        table.insert(keysDown, e[2])
      elseif e[1] == "key_up" then
        if isKeyDown(e[2]) then
          table.remove(keysDown, isKeyDown(e[2]))
        end
      end

      if isKeyDown(keys.leftCtrl) and isKeyDown(keys.leftShift) and isKeyDown(keys.delete) then
        wm.selectProcess(wm.createProcess("/bin/ui/tskmgr.lua", {
          width = 30,
          height = 15,
          title = "Task Manager"
        }))
        drawProcesses()
      end
      term.redirect(selectedProcess.window)
      coroutine.resume(selectedProcess.coroutine, table.unpack(e))
    elseif e[1] == "wm_fancyshutdown" then
      term.redirect(native)
      shell.run("/bin/ui/fancyshutdown.lua", e[2])
    elseif e[1] == "wm_login" then
      titlebarID = wm.createProcess("/bin/ui/titlebar.lua", {
        x = 1,
        y = 1,
        width = w,
        height = 1,
        showTitlebar = false,
        dontShowInTitlebar = true
      })
      wm.selectProcess(titlebarID)
    else
      for i, v in pairs(processes) do
        term.redirect(v.window)
        coroutine.resume(v.coroutine, table.unpack(e))
        v.window.redraw()
      end
      drawProcesses()
    end

    -- Update windows
    term.redirect(selectedProcess.window)
    removeDeadProcesses()
    for i, v in pairs(processes) do
      if i ~= selectedProcessID then
        term.redirect(v.window)
        coroutine.resume(v.coroutine, "keepalive")
      end
    end
    if selectedProcess.minimized then
      wm.selectProcess(titlebarID or 1)
    else
      drawProcess(selectedProcess)
    end
    log(tostring(selectedProcess.minimized))
  end
end

local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local ok, err = xpcall(main, function(err)
  term.redirect(term.native())
  term.setCursorPos(1, 3)
  term.setTextColor(colors.white)
  term.clear()
  print("Fatal System Error:", err)
  local w, h = term.getSize()
  local tb = split(debug.traceback(), "\n")
  for i, v in pairs(tb) do
    if i >= 13 then
      print("...")
      return
    else
      print(v)
    end
  end
  term.setCursorPos(1, 19)
  read()

  dumpLogs()
end)
