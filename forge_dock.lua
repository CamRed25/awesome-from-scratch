local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local function button(icon, label, command)
  local widget = wibox.widget({
    {
      {
        image = beautiful.icon(icon, beautiful.fg_normal),
        forced_width = dpi(20),
        forced_height = dpi(20),
        resize = true,
        widget = wibox.widget.imagebox,
      },
      margins = dpi(9),
      widget = wibox.container.margin,
    },
    widget = wibox.container.background,
  })
  widget:add_button(awful.button({}, 1, function() awful.spawn(command) end))
  widget.tooltip = awful.tooltip({ objects = { widget }, text = label })
  widget:connect_signal("mouse::enter", function(w) w.bg = beautiful.primary_color end)
  widget:connect_signal("mouse::leave", function(w) w.bg = nil end)
  return widget
end

return function(s)
  local tasks = awful.widget.tasklist({
    screen = s, filter = awful.widget.tasklist.filter.currenttags,
    buttons = {
      awful.button({}, 1, function(c)
        if c == client.focus then c.minimized = true else c.minimized = false; c:activate({ context = "tasklist", raise = true }) end
      end),
      awful.button({}, 4, function() awful.client.focus.byidx(1) end),
      awful.button({}, 5, function() awful.client.focus.byidx(-1) end),
    },
    layout = {
      spacing = dpi(3),
      layout = wibox.layout.fixed.horizontal,
    },
    widget_template = {
      {
        id = "icon_role",
        forced_width = dpi(20),
        forced_height = dpi(20),
        resize = true,
        widget = wibox.widget.imagebox,
      },
      margins = dpi(9),
      widget = wibox.container.margin,
      -- awful.widget.common only ever calls icon_role:set_image() when the
      -- client actually has an icon; a client with none (kitty, some
      -- xdg-toplevel apps under this compositor) is left with no image at
      -- all, so its slot renders as a blank gap instead of a same-sized icon
      -- and throws off the otherwise-even spacing between dock buttons.
      create_callback = function(self, c)
        local icon_role = self:get_children_by_id("icon_role")[1]
        if not icon_role.image then
          icon_role.image = c.icon or beautiful.awesome_icon
        end
      end,
    },
  })
  local favorites = {
    button("chrome.svg", "Web", "firefox"),
    button("folder.svg", "Files", "thunar"),
    button("terminal.svg", "Terminal", "kitty"),
    button("file-text.svg", "Code", "code"),
    spacing = dpi(3),
    layout = wibox.layout.fixed.horizontal,
  }
  local dock_items = {
    favorites,
    tasks,
    require("forge_music")(s),
    spacing = dpi(3),
    layout = wibox.layout.fixed.horizontal,
  }

  local dock = awful.wibar({
    position = "bottom",
    width = dpi(430),
    height = dpi(52),
    screen = s,
    bg = beautiful.bg_normal .. "EE",
    shape = beautiful.shape,
    border_width = dpi(1),
    border_color = beautiful.border_color_normal,
    widget = {
      dock_items,
      halign = "center",
      valign = "center",
      widget = wibox.container.place,
    },
  })
  awful.placement.bottom(dock, { parent = s, margins = { bottom = dpi(16) } })
  return dock
end
