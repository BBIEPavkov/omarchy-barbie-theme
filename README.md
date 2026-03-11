# Omarchy Barbie Theme

A Barbie-inspired dark theme for [Omarchy](https://omarchy.org/) with deep violet-purple backgrounds and bold hot pink accents.

## Colors

| Role | Color |
|------|-------|
| Background | `#2D0A22` (deep violet-pink) |
| Foreground | `#FF8EC8` (bold pink) |
| Accent | `#FF1493` (hot pink) |
| Cursor | `#FF69B4` (hot pink) |

## Install

```bash
omarchy-theme-install https://github.com/BBIEPavkov/omarchy-barbie-theme
```

Then apply it:

```bash
omarchy-theme-set barbie
```

## Fastfetch (Terminal ASCII Art)

This theme includes a Barbie ASCII art header that displays when you open a terminal.

To set it up, copy the fastfetch config files:

```bash
cp /path/to/omarchy-barbie-theme/fastfetch/barbie.txt ~/.config/fastfetch/barbie.txt
cp /path/to/omarchy-barbie-theme/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
```

Then add fastfetch to your `~/.bashrc`:

```bash
echo "fastfetch" >> ~/.bashrc
```

> **Note:** This will replace your existing fastfetch config. Back it up first if you want to keep it:
> ```bash
> cp ~/.config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc.bak
> ```

## VS Code Theme

Pair it with the matching [Omarchy Barbie VS Code theme](https://github.com/BBIEPavkov/vscode-omarchy-barbie-theme) for a fully coordinated Barbie setup across your desktop and editor.

## Wallpapers

Add your own Barbie-themed wallpapers to `~/.config/omarchy/themes/barbie/backgrounds/` and cycle through them with `Super + Ctrl + Space`.
