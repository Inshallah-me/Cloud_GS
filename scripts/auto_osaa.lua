local pui = require "gamesense/pui"
local weapondata = require "gamesense/csgo_weapons"
local vector = require("vector")

local exswitch = ui.new_checkbox("AA", "Other", "Auto exploit switch")
local add_weapon = ui.new_multiselect("AA", "Other", "Additional weapons", { "Pistols", "Desert Eagle" })

pui_ref = {
    double_tap = { pui.reference("RAGE", "Aimbot", "Double tap") },
    peek = pui.reference("RAGE", "Other", "Quick peek assist"),
    osaa = pui.reference("AA", "Other", "On shot anti-aim"),
}

contains = function(z, x)
    for _, v in next, z do
        if v == x then
            return true
        end
    end
    return false
end

local ovr = false

client.set_event_callback("setup_command", function(cmd)
    if ui.get(exswitch) then
        local is_dt = pui_ref.double_tap[1].hotkey:get()
        local is_peeking = pui_ref.peek.value and pui_ref.peek.hotkey:get()
        local lp = entity.get_local_player()
        local flags = entity.get_prop(lp, "m_fFlags")
        local velocity = vector(entity.get_prop(lp, "m_vecVelocity"))
        velocity = velocity:length2d()

        local crouch = bit.band(flags, bit.lshift(1, 1)) > 0.9
        local walk = velocity > 5 and (cmd.in_speed == 1)

        local on_ground = bit.band(flags, bit.lshift(1, 0)) == 1

        local can_teleport = not ((walk or velocity < 5) and not is_peeking or crouch)
        local can_dt = false

        local player_valid = (lp and entity.is_alive(lp)) and true or false
        local player_weapon = player_valid and entity.get_player_weapon(lp) or nil
        local weapon_t = player_valid and weapondata(player_weapon)

        if weapon_t then
            local weapon_id = entity.get_prop(player_weapon, "m_iItemDefinitionIndex")
            local weapon_auto = weapon_t.is_full_auto
            local is_deagle = weapon_id == 1

            can_dt = weapon_auto

            if ((weapon_t.weapon_type_int == 1 and not is_deagle) and not contains(ui.get(add_weapon), "Pistols"))
                or (is_deagle and not contains(ui.get(add_weapon), "Desert Eagle")) then
                can_dt = true
            end
        end

        local allow = on_ground and is_dt and not (can_dt or can_teleport)

        if allow then
            pui_ref.double_tap[1]:override(false)
            pui_ref.osaa.hotkey:override({ "Always on", 0 })
            ovr = true
        else
            if ovr then
                pui_ref.double_tap[1]:override(true)
                pui_ref.osaa.hotkey:override()
                ovr = false
            end
        end
    end
end)

ui.set_callback(exswitch, function(this)
    if not ui.get(this) then
        pui_ref.double_tap[1]:override()
        pui_ref.osaa.hotkey:override()
    end
end)

defer(function()
    pui_ref.double_tap[1]:override()
    pui_ref.osaa.hotkey:override()
end)
