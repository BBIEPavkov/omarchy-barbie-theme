-- Barbie extras: rounded corners, a pink glow on the focused window, see-through
-- unfocused windows, and bouncy windows.
-- Installed by the Barbie theme's extras/install.sh.

hl.config({
  decoration = {
    rounding = 10,
    -- Multiplies Omarchy's per-window opacity, so unfocused windows end up around 80%.
    inactive_opacity = 0.83,

    -- Soft pink glow around the focused window only.
    shadow = {
      enabled = true,
      range = 10,
      render_power = 3,
      offset = "0 0",
      color = "rgba(ff149399)",
      color_inactive = "rgba(00000000)",
    },
  },
})

-- Overshoot on open and move, soft shrink-and-fade on close.
hl.curve("bounce", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "bounce" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.5, bezier = "bounce", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "popin 80%" })

-- No glow on full-screen or maximized windows, where it only shows at the screen edge.
o.window({ fullscreen = true }, { no_shadow = true })
