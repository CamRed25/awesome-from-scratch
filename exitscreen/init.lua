local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local modal = require("modal")

-- somewm and AwesomeWM both run on LuaJIT, which is Lua 5.1, where `unpack` is a global
-- and `table.unpack` does not exist. Write it this way round so the config also works
-- on a 5.2+ interpreter.
local unpack = unpack or table.unpack

local exitscreen = {}

-- State
local selected_index = 1

-- Button widgets by index, for set_selected() below.
local button_widgets = {}
local set_selected -- assigned below, after create_button

-- Power options
local options = {
  {
    name = "Lock",
    icon = "■",
    key = "l",
    command = function()
      awesome.lock()
    end,
  },
  {
    name = "Logout",
    icon = "➜",
    key = "e",
    command = function()
      awesome.quit()
    end,
  },
  {
    name = "Suspend",
    icon = "⏾",
    key = "s",
    command = function()
      awful.spawn("systemctl suspend")
    end,
  },
  {
    name = "Reboot",
    icon = "⏼",
    key = "r",
    command = function()
      awful.spawn("systemctl reboot")
    end,
  },
  {
    name = "Shutdown",
    icon = "⏻",
    key = "p",
    command = function()
      awful.spawn("systemctl poweroff")
    end,
  },
}

-- Configuration
local config = {
  button_size = 120,
  icon_size = 36,
  spacing = 40,
}

--- Create a power button widget
local function create_button(option, index)
  local is_selected = index == selected_index

  local button = wibox.widget({
    {
      {
        {
          text = option.icon,
          font = beautiful.font_size(config.icon_size),
          halign = "center",
          valign = "center",
          widget = wibox.widget.textbox,
        },
        {
          text = option.name,
          font = beautiful.font_size(12),
          halign = "center",
          widget = wibox.widget.textbox,
        },
        {
          text = "[" .. option.key .. "]",
          font = beautiful.font_size(10),
          halign = "center",
          widget = wibox.widget.textbox,
        },
        spacing = 8,
        layout = wibox.layout.fixed.vertical,
      },
      margins = 16,
      widget = wibox.container.margin,
    },
    bg = is_selected and beautiful.primary_color or beautiful.bg_focus,
    fg = is_selected and beautiful.bg_normal or beautiful.fg_normal,
    shape = beautiful.shape,
    forced_width = config.button_size,
    forced_height = config.button_size + 30,
    widget = wibox.container.background,
  })

  button_widgets[index] = button

  -- Click handler
  button:add_button(awful.button({}, 1, function()
    exitscreen.hide()
    option.command()
  end))

  -- Hover
  button:connect_signal("mouse::enter", function()
    set_selected(index)
  end)

  return button
end

-- Moves the highlight in place; refresh() rebuilds the whole (fullscreen) popup.
set_selected = function(new_index)
  if new_index == selected_index then
    return
  end

  local old_button = button_widgets[selected_index]
  if old_button then
    old_button.bg = beautiful.bg_focus
    old_button.fg = beautiful.fg_normal
  end

  selected_index = new_index

  local new_button = button_widgets[selected_index]
  if new_button then
    new_button.bg = beautiful.primary_color
    new_button.fg = beautiful.bg_normal
  end
end

--- Create the exit screen widget
local function create_exitscreen_widget()
  button_widgets = {}
  local buttons = {}
  for i, option in ipairs(options) do
    table.insert(buttons, create_button(option, i))
  end

  return wibox.widget({
    {
      {
        -- Title
        {
          text = "What would you like to do?",
          font = beautiful.font_size(18, "Bold"),
          halign = "center",
          widget = wibox.widget.textbox,
        },
        -- Buttons. unpack() must be the LAST field in the constructor: Lua
        -- adjusts a multi-value expression to a single value anywhere else,
        -- which would silently render only the first button.
        {
          layout = wibox.layout.fixed.horizontal,
          spacing = config.spacing,
          unpack(buttons),
        },
        -- Hint
        {
          text = "Press Escape to cancel",
          font = beautiful.font_size(11),
          halign = "center",
          widget = wibox.widget.textbox,
        },
        spacing = 32,
        layout = wibox.layout.fixed.vertical,
      },
      halign = "center",
      valign = "center",
      widget = wibox.container.place,
    },
    bg = beautiful.bg_normal .. "E8",
    fg = beautiful.fg_normal,
    widget = wibox.container.background,
  })
end

--- Execute the selected option
local function execute_selected()
  if options[selected_index] then
    exitscreen.hide()
    options[selected_index].command()
  end
end

-- The modal controller owns visibility, the keygrabber, Escape, and the
-- exitscreen::visible signal; this module only describes content and keys.
local controller = modal.new({
  name = "exitscreen",
  build_popup = function()
    return awful.popup({
      widget = create_exitscreen_widget(),
      screen = awful.screen.focused(),
      placement = awful.placement.maximize,
      ontop = true,
      visible = false,
      bg = "#00000000",
    })
  end,
  on_show = function(popup)
    selected_index = 1
    awful.placement.maximize(popup)
    popup.widget = create_exitscreen_widget()
  end,
  keypressed = function(_, key)
    -- The labeled shortcut keys are checked before vim navigation, so the
    -- key a button displays is the key that triggers it
    for i, option in ipairs(options) do
      if key == option.key then
        set_selected(i)
        -- Small delay for visual feedback
        gears.timer.start_new(0.15, function()
          execute_selected()
          return false
        end)
        return
      end
    end

    if key == "Return" then
      execute_selected()
    elseif key == "Left" or key == "h" then
      set_selected(math.max(1, selected_index - 1))
    elseif key == "Right" or key == "l" then
      set_selected(math.min(#options, selected_index + 1))
    end
  end,
})

--- Refresh the exit screen
function exitscreen.refresh()
  if controller.popup then
    controller.popup.widget = create_exitscreen_widget()
  end
end

exitscreen.show = controller.show
exitscreen.hide = controller.hide
exitscreen.toggle = controller.toggle
exitscreen.is_visible = controller.is_visible

return exitscreen
