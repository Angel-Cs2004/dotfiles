-- Hyprland Lua config (migrado desde hyprland.conf)
-- https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------

-- Regla general: cualquier monitor sin configurar usa su resolución nativa
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Monitores de cada PC: ~/.config/hypr/hosts/<hostname>.lua (ver README)
do
    local f = io.open("/etc/hostname", "r")
    local host = f and f:read("*l") or ""
    if f then f:close() end
    local ok, err = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/hosts/" .. host .. ".lua")
    if not ok and not tostring(err):find("No such file") then
        hl.exec_cmd("notify-send -u critical 'Hyprland' 'Error en hosts/" .. host .. ".lua (revisa el archivo)'")
    end
end

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show run"   -- antes hyprlauncher (no instalado)
local browser     = "google-chrome-stable"
local fileManager2 = terminal .. " -e yazi"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/start-wallpaper.sh")
    hl.exec_cmd("~/.config/hypr/start.sh")   -- genera colores si faltan y abre waybar
    hl.exec_cmd("eww daemon")
    hl.exec_cmd("~/.config/eww/scripts/hover.py")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Colores generados por matugen desde el fondo (ver ~/.config/hypr/theme.sh)
local ok, theme_colors = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/colors.lua")
if not ok then
    theme_colors = {
        active_border   = { colors = {"rgba(5a0f1cff)", "rgba(0a2a66ff)"}, angle = 45 },
        inactive_border = { colors = {"rgba(141418cc)", "rgba(1c1f26cc)"}, angle = 45 },
    }
end

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 8,

        border_size = 2,

        col = theme_colors,

        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        -- la redondez de los bordes
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.60,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 3,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("quart", { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 6, bezier = "quart", style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "fade",        enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6, bezier = "quart" })

-- Notificaciones (dunst): entran deslizándose hacia la izquierda y salen hacia la derecha
hl.layer_rule({
    name      = "dunst-slide",
    match     = { namespace = "^notifications$" },
    animation = "slide right",
})

-- Menú de energía (ver ~/.config/waybar/power/)
hl.layer_rule({   -- rofi: fondo de cristal desenfocado (diseños 1 y 2, y confirmación)
    name         = "rofi-glass",
    match        = { namespace = "^rofi$" },
    blur         = true,
    ignore_alpha = 0.05,
    animation    = "popin 90%",
})
hl.layer_rule({   -- diseño 3: el panel entra desde la derecha
    name         = "power-panel",
    match        = { namespace = "^eww-power$" },
    blur         = true,
    ignore_alpha = 0.05,
    animation    = "slide right",
})
hl.layer_rule({   -- diseño 3: velo detrás del panel
    name         = "power-backdrop",
    match        = { namespace = "^eww-power-backdrop$" },
    blur         = true,
    animation    = "fade",
})

-- Atajos mientras el panel de energía está abierto
hl.define_submap("power", function()
    local p = "~/.config/waybar/power/panel.sh "
    hl.bind("Escape",    hl.dsp.exec_cmd(p .. "close"))
    hl.bind("SUPER + P", hl.dsp.exec_cmd(p .. "close"))
    hl.bind("L",         hl.dsp.exec_cmd(p .. "act lock"))
    hl.bind("E",         hl.dsp.exec_cmd(p .. "act logout"))
    hl.bind("S",         hl.dsp.exec_cmd(p .. "act suspend"))
    hl.bind("R",         hl.dsp.exec_cmd(p .. "act reboot"))
    hl.bind("P",         hl.dsp.exec_cmd(p .. "act poweroff"))
end)

hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        repeat_delay = 260,
        repeat_rate  = 50,
        kb_layout    = "latam, us",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.device({
    name   = "wacom-intuos-s-pen",
    output = "HDMI-A-5",
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod  = "SUPER"
local mainMod1 = "TAB"
local mainMod2 = "ALT"
local ctrl     = "CTRL"

hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"))

-- TECLAS PUESTAS POR MI -> APRENDIENDO
hl.bind(mainMod  .. " + B",        hl.dsp.exec_cmd(browser))
hl.bind(mainMod  .. " + " .. mainMod1, hl.dsp.window.fullscreen({ mode = 1 })) -- pantalla completa
hl.bind(mainMod2 .. " + " .. mainMod1, hl.dsp.exec_cmd(terminal))
hl.bind(mainMod  .. " + Q",        hl.dsp.window.close()) -- pa poder cerrar
hl.bind(mainMod  .. " + E",        hl.dsp.exec_cmd(fileManager2))
hl.bind("SUPER + D",               hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("Print", hl.dsp.exec_cmd('mkdir -p ~/Pictures/screenshots && grim -g "$(slurp)" - | tee ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy'))
-- Control de brillo
hl.bind("SUPER + F5", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("SUPER + F6", hl.dsp.exec_cmd("brightnessctl set +5%"))
-- Modo cálido (luz nocturna) on/off
hl.bind("SUPER + F7", hl.dsp.exec_cmd("~/.local/bin/night-light-toggle.sh"))
-- Fondo de pantalla (también cambia la paleta de colores)
hl.bind("SUPER + W",         hl.dsp.exec_cmd("~/.config/hypr/wallpaper.sh next"))
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/wallpaper.sh random"))
hl.bind("SUPER + ALT + W",   hl.dsp.exec_cmd("env AWWW_TRANSITION_WAVE=45,28 AWWW_TRANSITION_BEZIER=0.45,0,0.25,1 waypaper"))
-- TERMINO HASTA AQUI

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty --title traductor-sioyek ~/.local/bin/sioyek-translate-watch.sh"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.local/bin/sioyek-toggle-voice.sh"))

hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.config/waybar/power_menu.sh"))
-- TEMPORAL: probar los 3 diseños del menú de energía (quitar al elegir uno)
hl.bind("SUPER + F1", hl.dsp.exec_cmd("~/.config/waybar/power_menu.sh icons"))
hl.bind("SUPER + F2", hl.dsp.exec_cmd("~/.config/waybar/power_menu.sh full"))
hl.bind("SUPER + F3", hl.dsp.exec_cmd("~/.config/waybar/power_menu.sh panel"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle

-- Mover el foco con las flechas
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Cambiar de workspace / mover ventana a workspace con mainMod + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 -> tecla 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind("MOD5 + P",                hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll entre workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mover/redimensionar ventanas con CTRL + ratón
hl.bind(ctrl .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(ctrl .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Teclas multimedia
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requiere playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Reproductor de Spotify (eww) en el centro de la pantalla
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/eww/scripts/center.sh"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    -- Ignorar peticiones de maximizar
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Arreglo de problemas de arrastre con XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name  = "sioyek-transparency",
    match = { class = "sioyek" },

    opacity = "1.0 1.0",
})

hl.window_rule({
    name  = "traductor-sioyek",
    match = { title = "^traductor-sioyek$" },

    float   = true,
    size    = "370 880",
    move    = "1218 50",
    pin     = true,
    opacity = "1.0 0.88",
})
