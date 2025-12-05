extends Resource
class_name Packets

## Packet type definitions for future strongly-typed networking.
## Current server still uses simple JSON with field `t`, but this
## enum mirrors the high-level design from the GDD and can be adopted gradually.

enum PacketType {
	# Auth
	AUTH_REQUEST,
	AUTH_RESPONSE,

	# Player
	PLAYER_SPAWN,
	PLAYER_MOVE,
	PLAYER_ACTION,
	PLAYER_STATS_UPDATE,

	# Ship
	SHIP_SPAWN,
	SHIP_MOVE,
	SHIP_FIRE,
	SHIP_DAMAGE,
	SHIP_BOARD,

	# Island
	ISLAND_UPDATE,
	BUILDING_PLACE,
	BUILDING_UPGRADE,
	BUILDING_DESTROY,

	# Combat
	COMBAT_START,
	COMBAT_ATTACK,
	COMBAT_DAMAGE,
	COMBAT_END,

	# Monsters
	MONSTER_SPAWN,
	MONSTER_UPDATE,
	MONSTER_DEATH,

	# Economy
	INVENTORY_UPDATE,
	TRADE_REQUEST,
	TRADE_COMPLETE,
	MARKET_ORDER,

	# Guilds
	GUILD_UPDATE,
	GUILD_INVITE,
	GUILD_WAR,

	# World
	WEATHER_UPDATE,
	WORLD_EVENT,
	ZONE_TRANSFER,
}


class Packet:
	var type: int
	var timestamp: int
	var data: Dictionary


