local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local function control(text, command)
  local w = wibox.widget({ text = text, align = "center", font = beautiful.font_size(11, "Bold"), forced_width = dpi(55), widget = wibox.widget.textbox })
  w:add_button(awful.button({}, 1, function() awful.spawn(command) end))
  return w
end

return function(s)
  local title = wibox.widget({ text = "Nothing playing", font = beautiful.font_size(11, "Bold"), widget = wibox.widget.textbox })
  local artist = wibox.widget({ text = "Open a media player", widget = wibox.widget.textbox })
  local progress = wibox.widget({ max_value = 100, value = 0, forced_height = dpi(3), color = beautiful.primary_color, background_color = beautiful.bg_focus, widget = wibox.widget.progressbar })
  local card = awful.popup({
    screen = s, visible = false, ontop = true, bg = beautiful.bg_normal, border_width = dpi(1), border_color = beautiful.primary_color,
    widget = { { title, artist, progress, { control("PREV", "playerctl previous"), control("PLAY", "playerctl play-pause"), control("NEXT", "playerctl next"), spacing = dpi(12), layout = wibox.layout.fixed.horizontal }, spacing = dpi(10), layout = wibox.layout.fixed.vertical }, margins = dpi(18), forced_width = dpi(320), widget = wibox.container.margin },
  })
  local toggle = wibox.widget({
    {
      image = beautiful.icon("play-circle.svg", beautiful.fg_normal),
      forced_width = dpi(20),
      forced_height = dpi(20),
      resize = true,
      widget = wibox.widget.imagebox,
    },
    margins = dpi(9),
    widget = wibox.container.margin,
  })
  toggle:add_button(awful.button({}, 1, function()
    card.visible = not card.visible
    if card.visible then awful.placement.bottom_right(card, { parent = s, margins = { right = dpi(12), bottom = dpi(58) } }) end
  end))
  toggle.tooltip = awful.tooltip({ objects = { toggle }, text = "Music" })
  gears.timer({ timeout = 3, autostart = true, call_now = true, callback = function()
    awful.spawn.easy_async_with_shell("playerctl metadata --format '{{title}}\\t{{artist}}\\t{{mpris:length}}' 2>/dev/null", function(output)
      local song, by, length = output:match("([^\\t\\n]*)\\t([^\\t\\n]*)\\t([^\\t\\n]*)")
      title.text = song and song ~= "" and song or "Nothing playing"
      artist.text = by and by ~= "" and by or "Open a media player"
      local duration = tonumber(length) or 0
      if duration > 0 then awful.spawn.easy_async_with_shell("playerctl position 2>/dev/null", function(pos) progress.value = math.min(100, 100 * (tonumber(pos) or 0) * 1000000 / duration) end) else progress.value = 0 end
    end)
  end })
  return toggle
end
