-- Barbie extras: rounded corners and bouncy windows.
-- Installed by the Barbie theme's extras/install.sh.

hl.config({
  decoration = {
    rounding = 10,
  },
})

-- Overshoot on open and move, soft shrink-and-fade on close.
hl.curve("bounce", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "bounce" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.5, bezier = "bounce", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "popin 80%" })
