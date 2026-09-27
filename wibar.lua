local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local widgets = require("widgets")
local dpi = require("beautiful.xresources").apply_dpi

return function(s)
  local brand = wibox.widget({
    text = "FORGE",
    font = beautiful.font_size(12, "Bold"),
    align = "center",
    widget = wibox.widget.textbox,
  })
  brand:add_button(awful.button({}, 1, function()
    require("launcher").toggle()
  end))
  brand.tooltip = awful.tooltip({ objects = { brand }, text = "Applications" })

  -- The right-hand section is assembled rather than written as one literal,
  -- because the systray is only on one screen. Building the array with
  -- table.insert keeps it free of holes: a nil sitting in the middle of a
  -- declarative table makes the layout's child count undefined.
  local right = {
    spacing = beautiful.widget_group_spacing,
    layout = wibox.layout.fixed.horizontal,
  }

  -- The status readouts, spaced as a group of their own. The systray chip
  -- (when present) lives inside this same group rather than as its own
  -- top-level entry in `right`: a wibox.layout.fixed reserves spacing for
  -- every child it holds regardless of that child's `.visible`, so hiding
  -- the chip via `.visible` while it sat directly in `right` left a phantom
  -- gap-sized hole at the very end of the bar (nothing after it to absorb
  -- the reserved spacing). Nesting it here confines that phantom gap to the
  -- inside of this group, ahead of the volume readout, where it's invisible.
  local status_group = {
    spacing = beautiful.widget_spacing,
    layout = wibox.layout.fixed.horizontal,
  }

  -- The systray is a single system-wide widget: it can only live in one bar,
  -- so on a multi-monitor setup only the primary screen gets one. A
  -- margin-background-margin sandwich gives it an inset chip look. The chip
  -- must stay hidden when there are no tray icons: the inner systray widget
  -- correctly reports zero size then, but the margin/bg/shape wrapper around
  -- it doesn't, so left uncontrolled it draws as an empty colored square.
  if s == screen.primary then
    local systray_chip = wibox.widget({
      {
        {
          wibox.widget.systray(),
          margins = dpi(4),
          widget = wibox.container.margin,
        },
        bg = beautiful.bg_focus,
        shape = beautiful.shape_small,
        widget = wibox.container.background,
      },
      left = dpi(8),
      right = dpi(8),
      top = dpi(4),
      bottom = dpi(4),
      widget = wibox.container.margin,
    })

    local function update_systray_chip_visibility()
      systray_chip.visible = awesome.systray() > 0
    end
    awesome.connect_signal("systray::update", update_systray_chip_visibility)
    update_systray_chip_visibility()

    table.insert(status_group, systray_chip)
  end

  table.insert(status_group, widgets.volume)
  table.insert(status_group, widgets.wifi)
  table.insert(status_group, widgets.battery.widget)

  table.insert(right, status_group)

  table.insert(right, {
    {
      s.mylayoutbox,
      forced_height = beautiful.wibar_height * 0.6,
      forced_width = beautiful.wibar_height * 0.6,
      widget = wibox.container.constraint,
    },
    halign = "center",
    valign = "center",
    widget = wibox.container.place,
  })

  table.insert(right, widgets.power)

  local left_group = {
    {
      brand,
      widgets.taglist(s),
      -- The prompt for Mod+R (run) and Mod+X (Lua): without a home in the
      -- bar, prompts still run but type into an invisible textbox
      s.mypromptbox,
      -- Each tag already carries its own leading/trailing inset
      -- (widget_icon_margins, baked into its widget_template), which is what
      -- makes tag-to-tag gaps even. Joining brand to that with the same
      -- constant reproduces one full gap (inset + spacing + inset); the
      -- wider widget_group_spacing used to double up with the tag's own
      -- inset and make the brand-to-first-tag gap visibly bigger than the
      -- rest.
      spacing = beautiful.widget_icon_margins,
      layout = wibox.layout.fixed.horizontal,
    },
    left = dpi(8),
    widget = wibox.container.margin,
  }

  local wibar = awful.wibar({
    position = "top",
    screen = s,
    widget = {
      {
        -- Left/right anchored row, no middle occupant: wibox.layout.align
        -- only centers its middle widget within the leftover space between
        -- the other two, not the bar's actual width, so a clock placed here
        -- directly would drift toward whichever side is narrower. Centering
        -- it in a separate full-width stack layer below fixes that
        -- regardless of how wide `left_group` or `right` end up being.
        left_group,
        nil,
        right,
        layout = wibox.layout.align.horizontal,
      },
      {
        nil,
        widgets.clock,
        nil,
        expand = "none",
        layout = wibox.layout.align.horizontal,
      },
      layout = wibox.layout.stack,
    },
  })
  return wibar
end
