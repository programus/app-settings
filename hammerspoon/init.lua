function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

-- -- Switch hosts
-- hs.network.reachability.forHostName('home.pi'):setCallback(function(self, flags)
--   if (flags & hs.network.reachability.flags.reachable) > 0 then
--     -- in home LAN
--     print('switch to home LAN hosts')
--     hs.execute("sudo sed -i '' 's/#*192\\.168\\.1/192.168.1/' /etc/hosts")
--   else
--     print('switch to external hosts')
--     hs.execute("sudo sed -i '' 's/192\\.168\\.1/#192.168.1/' /etc/hosts")
--   end
-- end):start()

-- QuickRef
hs.loadSpoon('QuickRef')
spoon.QuickRef:bindHotKeys({
    show_blank = {{'ctrl', 'cmd'}, 'N'},
    show_frontmost_window_capture = {{'ctrl', 'cmd'}, 'W'},
    show_pasteboard = {{'ctrl', 'cmd'}, 'P'}
  })

-- Switch kitty
hs.hotkey.bind({'alt'}, 'space', function ()
  local APP_NAME = 'kitty'

  function moveWindow(app, space, mainScreen)
    -- move to main space
    print('move window')
    local win = nil
    while win == nil do
      win = app:mainWindow()
    end
    winFrame = win:frame()
    scrFrame = mainScreen:fullFrame()
    winFrame.w = scrFrame.w
    winFrame.y = scrFrame.y
    winFrame.x = scrFrame.x
    win:setFrame(winFrame, 0)
    app:hide()
    hs.spaces.moveWindowToSpace(win, space)
    app:activate()
    win:focus()
  end

  function findScreenSpace()
    local space = hs.spaces.focusedSpace()
    local screenUUID = hs.spaces.spaceDisplay(space)
    if hs.spaces.spaceType(space) == 'fullscreen' then
      -- focused space is fullscreen, find others to jump
      local activeSpaces = hs.spaces.activeSpaces()
      local foundSpace = false
      -- try all active spaces in other screens
      for scrUUID, spaceId in pairs(activeSpaces) do
        if hs.spaces.spaceType(spaceId) == 'user' then
          space = spaceId
          screenUUID = scrUUID
          foundSpace = true
          break
        end
      end

      if not foundSpace then
        -- try all user spaces in other screens
        local allSpaces = hs.spaces.allSpaces()
        for scrUUID, spaces in pairs(allSpaces) do
          if scrUUID ~= screenUUID then
            for _, spaceId in ipairs(spaces) do
              if hs.spaces.spaceType(spaceId) == 'user' then
                space = spaceId
                screenUUID = scrUUID
                foundSpace = true
                break
              end
            end
          end
          if foundSpace then
            break
          end
        end
      end

      if not foundSpace then
        -- try all user spaces in current screen
        local spacesInCurrentScreen = hs.spaces.spacesForScreen(screenUUID)
        for _, spaceId in ipairs(spacesInCurrentScreen) do
          if hs.spaces.spaceType(spaceId) == 'user' then
            space = spaceId
            screenUUID = scrUUID
            foundSpace = true
            break
          end
        end
      end
    end

    local mainScreen = hs.screen.find(screenUUID)
    return mainScreen, space
  end

  local app = hs.application.get(APP_NAME)
  local mainScreen, space = findScreenSpace()
  print(space)
  print(mainScreen)
  if app ~= nil then
    if not app:mainWindow() then
      app:selectMenuItem({'kitty', 'New OS window'})
      moveWindow(app, space, mainScreen)
    elseif app:isFrontmost() then
      print('app is front most, so hide it')
      app:hide()
    else
      moveWindow(app, space, mainScreen)
    end
  else
    if app == nil and hs.application.launchOrFocus(APP_NAME) then
      local appWatcher = nil
      print('create app watcher')
      appWatcher = hs.application.watcher.new(function(name, event, app)
        print(name)
        print(event)
        if event == hs.application.watcher.launched and name == APP_NAME then
          app:hide()
          moveWindow(app, space, mainScreen)
          appWatcher:stop()
        end
      end)
      print('start watcher')
      appWatcher:start()
    end
  end
end)