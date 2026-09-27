local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local modal = require("modal")

local dashboard = {}

-- Load submodules
local profile = require("dashboard.profile")
local sliders = require("dashboard.sliders")
local toggles = require("dashboard.toggles")
local calendar = require("dashboard.calendar")
local notifications = require("notifications")

-- Configuration
-- Two columns, not one tall stack: the four original sections stacked in a
-- single column added up to ~850px, well past this screen's ~644px usable
-- height (the calendar's day grid was landing off the bottom of the
-- display). Side by side, the taller column is ~450px, leaving just enough
-- headroom for the notification panel below both columns - see its own
-- panel_height comment in notifications.lua for that budget.
local config = {
  column_width = 360,
  margin = 20,
  spacing = 16,
  bg = beautiful.bg_normal .. "F2", -- Slightly transparent
  border_width = beautiful.border_width or 1,
  border_color = beautiful.primary_color,
}
config.width = config.column_width * 2 + config.spacing + config.margin * 2

--- Create the main dashboard widget
local function create_dashboard_widget()
  return wibox.widget({
    {
      {
        {
          {
            {
              -- Left column: who/when + quick controls
              profile.create(),
              sliders.create(),
              spacing = config.spacing,
              layout = wibox.layout.fixed.vertical,
            },
            width = config.column_width,
            strategy = "exact",
            widget = wibox.container.constraint,
          },
          {
            {
              -- Right column: toggles + calendar
              toggles.create(),
              calendar.create(),
              spacing = config.spacing,
              layout = wibox.layout.fixed.vertical,
            },
            width = config.column_width,
            strategy = "exact",
            widget = wibox.container.constraint,
          },
          spacing = config.spacing,
          layout = wibox.layout.fixed.horizontal,
        },
        -- Notifications, full width, across the bottom of both columns
        notifications.create_panel(),
        spacing = config.spacing,
        layout = wibox.layout.fixed.vertical,
      },
      margins = config.margin,
      widget = wibox.container.margin,
    },
    bg = config.bg,
    shape = beautiful.shape,
    forced_width = config.width,
    widget = wibox.container.background,
  })
end

-- Centered under the bar (the clock sits dead-center there, see wibar.lua),
-- on whatever screen the popup is on. Used to be pinned top-right, which put
-- it under the far edge of the bar regardless of which widget opened it.
-- workarea.y already excludes the wibar's reserved strut, so it is the top
-- of the usable area, not the top of the screen - adding wibar_height on
-- top of it double-counts the bar and floats the panel too low.
local function place(d)
  local wa = d.screen.workarea
  d.x = wa.x + (wa.width - d.width) / 2
  d.y = wa.y + beautiful.useless_gap * 2
  awful.placement.no_offscreen(d, { honor_workarea = true, margins = beautiful.useless_gap * 2 })
end

-- The modal controller owns visibility, click-outside/tag-change dismissal,
-- Escape, and the dashboard::visible signal. The widget tree is built once
-- (build_popup runs on first show); rebuilding it per open would also
-- re-create each section's timers and signal connections - a leak.
local controller = modal.new({
  name = "dashboard",
  build_popup = function()
    return awful.popup({
      widget = create_dashboard_widget(),
      screen = awful.screen.focused(),
      ontop = true,
      visible = false,
      bg = "#00000000", -- Fully transparent (widget has its own bg)
      shape = beautiful.shape,
      border_width = config.border_width,
      border_color = config.border_color,
      -- Placement lives on the popup itself, not in on_show: awful.popup
      -- re-applies it whenever the popup's size changes, which covers the
      -- first show, when the widget has not been measured yet.
      placement = place,
    })
  end,
  on_show = function(popup)
    place(popup)

    -- Sync sections that mirror system state (volume, brightness, radios)
    sliders.refresh()
    toggles.refresh()
  end,
})

dashboard.show = controller.show
dashboard.hide = controller.hide
dashboard.toggle = controller.toggle
dashboard.is_visible = controller.is_visible

return dashboard
