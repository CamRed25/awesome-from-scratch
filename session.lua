local awful = require("awful")
local naughty = require("naughty")

local M = {}

function M.init()
  awful.spawn.easy_async({
    "dbus-update-activation-environment", "--systemd",
    "DISPLAY", "WAYLAND_DISPLAY", "XDG_CURRENT_DESKTOP",
    "XDG_SESSION_TYPE", "XDG_SESSION_ID",
  }, function(_, stderr, _, code)
    if code ~= 0 then
      naughty.notification({
        urgency = "critical",
        title = "session.lua",
        message = "dbus-update-activation-environment failed: " .. tostring(stderr),
      })
      return
    end
    awful.spawn({ "systemctl", "--user", "start", "soteria.service" })
    awful.spawn({ "systemctl", "--user", "start", "cliphist.service" })
  end)
end

function M.lock()
  local locked = awesome.lock()
  if locked then
    awful.spawn({ "cliphist", "wipe" })
  end
  return locked
end

function M.setup_idle()
  -- awesome.set_idle_timeout("session-lock", 300, M.lock)
  -- awesome.set_idle_timeout("display-off", 360, function()
  --   awesome.dpms_off()
  -- end)

  -- awesome.connect_signal("logind::prepare_sleep", function(sleeping)
  --   if sleeping then
  --     M.lock()
  --   end
  -- end)
end

return M
