#include <amxmodx>
#include <amxmisc>
#include <zombie_thehero2>

#define TOTAL_ITEMS 18

new g_msgStatusIcon;

public plugin_init()
{
    register_plugin("[ZB3EX] Player Status Icon", "1.0", "")
    g_msgStatusIcon = get_user_msgid("StatusIcon")
}

public plugin_natives()
{
    register_native("zb3_show_user_statusicon", "native_show_user_statusicon", 1)
    register_native("zb3_hide_user_statusicon", "native_hide_user_statusicon", 1)
}

public native_show_user_statusicon(id, idspr)
{
    if(!is_user_connected(id))
        return

    ShowItemIcon(id, idspr)
}

public native_hide_user_statusicon(id)
{
    if(!is_user_connected(id))
        return

    HideItemIcon(id)
}

stock ShowItemIcon(id, idspr)
{
	StatusIcon(id, GetItemIconName(idspr), 1)
}

stock HideItemIcon(id)
{
	for (new i = 1; i <= TOTAL_ITEMS; i++)
	{
		StatusIcon(id, GetItemIconName(i), 0)
	}
}

StatusIcon(id, sprite_name[], run)
{
	message_begin(MSG_ONE, g_msgStatusIcon, {0,0,0}, id);
	write_byte(run); // status (0=hide, 1=show, 2=flash)
	write_string(sprite_name); // sprite name
	write_byte(255);
	write_byte(200);
	write_byte(200);
	message_end();
}

GetItemIconName(item)
{
    new item_name[16]
    switch (item)
    {
        case 1: item_name = "zombiACT"  // 1.5x Ammo
        case 2: item_name = "zombiATER" // health armor up
        case 3: item_name = "zombiBCT"  // boot
        case 4: item_name = "zombiBTER" // 70% infect
        case 5: item_name = "zombiCCT"  // voodoo ZB
        case 6: item_name = "zombiCTER" // smoke ZB
        case 7: item_name = "zombiDTER" // light ZB
        case 8: item_name = "zombiECT"  // trap
        case 9: item_name = "zombiETER" // heavy ZB
        case 10:item_name = "zombiFCT"  // boot KEY
        case 11:item_name = "zombiFTER" // smoke ZB
        case 12:item_name = "zombiGTER" // voodoo ZB
        case 13:item_name = "zombiHCT"  // 30% dmg
        case 14:item_name = "zombiHTER" // 0 respawn
        case 15:item_name = "zombiICT"  // deadly KEY
        case 16:item_name = "zombiITER" // deimos ZB
        case 17:item_name = "zombiJCT"  // bloody KEY
        case 18:item_name = "zombiJTER" // metus ZB
        default: item_name = ""
	}

	return item_name
}
