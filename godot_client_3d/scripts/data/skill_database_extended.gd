extends Node
class_name SkillDatabaseExtended

## Расширенная база данных навыков - дополнение к основной
## Здесь детальное описание всех навыков для реализации

## Полный список активных навыков по категориям

# МЕЛЕЕ (15 навыков)
const MELEE_SKILLS = [
	{"id": "slash", "name": "Рез", "rarity": "COMMON"},
	{"id": "heavy_strike", "name": "Тяжёлый удар", "rarity": "COMMON"},
	{"id": "shield_bash", "name": "Удар щитом", "rarity": "COMMON"},
	{"id": "quick_attack", "name": "Быстрая атака", "rarity": "COMMON"},
	{"id": "cleave", "name": "Рассечение", "rarity": "COMMON"},
	{"id": "whirlwind", "name": "Вихрь", "rarity": "RARE"},
	{"id": "leap_strike", "name": "Прыжок-удар", "rarity": "RARE"},
	{"id": "tidal_slash", "name": "Приливный рез", "rarity": "RARE"},
	{"id": "combo_finisher", "name": "Завершающий удар", "rarity": "RARE"},
	{"id": "armor_breaker", "name": "Ломатель брони", "rarity": "RARE"},
	{"id": "bloodthirst", "name": "Кровожадность", "rarity": "LEGENDARY"},
	{"id": "berserker_rage", "name": "Ярость берсерка", "rarity": "LEGENDARY"},
	{"id": "earthquake_stomp", "name": "Землетрясение", "rarity": "LEGENDARY"},
	{"id": "void_cleave", "name": "Рассечение бездны", "rarity": "MYTHIC"},
	{"id": "titan_strike", "name": "Удар титана", "rarity": "MYTHIC"}
]

# ДАЛЬНИЙ БОЙ (15 навыков)
const RANGED_SKILLS = [
	{"id": "quick_shot", "name": "Быстрый выстрел", "rarity": "COMMON"},
	{"id": "power_shot", "name": "Мощный выстрел", "rarity": "COMMON"},
	{"id": "rapid_fire", "name": "Быстрая стрельба", "rarity": "COMMON"},
	{"id": "charged_shot", "name": "Заряженный выстрел", "rarity": "COMMON"},
	{"id": "aimed_shot", "name": "Прицельный выстрел", "rarity": "COMMON"},
	{"id": "multi_shot", "name": "Залп стрел", "rarity": "RARE"},
	{"id": "piercing_arrow", "name": "Пронзающая стрела", "rarity": "RARE"},
	{"id": "hunter_mark", "name": "Метка охотника", "rarity": "RARE"},
	{"id": "poison_arrow", "name": "Ядовитая стрела", "rarity": "RARE"},
	{"id": "trap_arrow", "name": "Ловчая стрела", "rarity": "RARE"},
	{"id": "explosive_arrow", "name": "Взрывная стрела", "rarity": "LEGENDARY"},
	{"id": "sniper_shot", "name": "Выстрел снайпера", "rarity": "LEGENDARY"},
	{"id": "storm_arrow", "name": "Штормовая стрела", "rarity": "LEGENDARY"},
	{"id": "void_arrow", "name": "Стрела бездны", "rarity": "MYTHIC"},
	{"id": "death_mark", "name": "Печать смерти", "rarity": "MYTHIC"}
]

# МАГИЯ (20 навыков)
const MAGIC_SKILLS = [
	{"id": "water_bolt", "name": "Водный болт", "rarity": "COMMON"},
	{"id": "water_sphere", "name": "Водная сфера", "rarity": "COMMON"},
	{"id": "heal", "name": "Лечение", "rarity": "COMMON"},
	{"id": "mana_shield", "name": "Магический щит", "rarity": "COMMON"},
	{"id": "water_wave", "name": "Волна воды", "rarity": "RARE"},
	{"id": "water_shield", "name": "Водный щит", "rarity": "RARE"},
	{"id": "ice_spike", "name": "Ледяной шип", "rarity": "RARE"},
	{"id": "tidal_vortex", "name": "Водоворот", "rarity": "LEGENDARY"},
	{"id": "void_blast", "name": "Взрыв пустоты", "rarity": "MYTHIC"},
	{"id": "chain_lightning", "name": "Цепная молния", "rarity": "RARE"},
	{"id": "elemental_storm", "name": "Стихийный шторм", "rarity": "LEGENDARY"},
	{"id": "summon_water_elemental", "name": "Призыв водного элементаля", "rarity": "LEGENDARY"},
	{"id": "teleport", "name": "Телепорт", "rarity": "LEGENDARY"},
	{"id": "phase_shift", "name": "Сдвиг фазы", "rarity": "MYTHIC"},
	{"id": "time_dilation", "name": "Замедление времени", "rarity": "MYTHIC"}
]

# АЛХИМИЯ (15 навыков)
const ALCHEMY_SKILLS = [
	{"id": "healing_potion", "name": "Зелье лечения", "rarity": "COMMON"},
	{"id": "stamina_potion", "name": "Зелье выносливости", "rarity": "COMMON"},
	{"id": "mana_potion", "name": "Зелье маны", "rarity": "COMMON"},
	{"id": "poison_bomb", "name": "Ядовитая бомба", "rarity": "RARE"},
	{"id": "fire_bomb", "name": "Огненная бомба", "rarity": "RARE"},
	{"id": "frost_bomb", "name": "Ледяная бомба", "rarity": "RARE"},
	{"id": "smoke_bomb", "name": "Дымовая бомба", "rarity": "RARE"},
	{"id": "flash_bomb", "name": "Ослепляющая бомба", "rarity": "RARE"},
	{"id": "explosive_potion", "name": "Взрывное зелье", "rarity": "LEGENDARY"},
	{"id": "void_bomb", "name": "Бомба бездны", "rarity": "MYTHIC"}
]

# МОРЕПЛАВАНИЕ (15 навыков)
const SAILING_SKILLS = [
	{"id": "wind_boost", "name": "Порыв ветра", "rarity": "COMMON"},
	{"id": "emergency_repair", "name": "Экстренный ремонт", "rarity": "RARE"},
	{"id": "ship_shield", "name": "Щит корабля", "rarity": "RARE"},
	{"id": "ram_boost", "name": "Таранный удар", "rarity": "RARE"},
	{"id": "cannon_overload", "name": "Перегрузка пушек", "rarity": "LEGENDARY"},
	{"id": "storm_navigation", "name": "Штормовая навигация", "rarity": "LEGENDARY"}
]

# СОБИРАТЕЛЬСТВО (10 навыков)
const GATHERING_SKILLS = [
	{"id": "quick_gather", "name": "Быстрый сбор", "rarity": "COMMON"},
	{"id": "lucky_find", "name": "Счастливая находка", "rarity": "RARE"},
	{"id": "detect_resources", "name": "Обнаружение ресурсов", "rarity": "RARE"}
]

# ЗАЩИТА (5 навыков)
const DEFENSE_SKILLS = [
	{"id": "block", "name": "Блок", "rarity": "COMMON"},
	{"id": "parry", "name": "Парирование", "rarity": "RARE"},
	{"id": "defensive_stance", "name": "Защитная стойка", "rarity": "RARE"}
]

# ДВИЖЕНИЕ (5 навыков)
const MOVEMENT_SKILLS = [
	{"id": "dash", "name": "Рывок", "rarity": "COMMON"},
	{"id": "roll", "name": "Кувырок", "rarity": "COMMON"},
	{"id": "wave_dash", "name": "Рывок волны", "rarity": "RARE"}
]

## Пассивные навыки (50)

# ОБЫЧНЫЕ (20)
const PASSIVE_COMMON = [
	{"id": "vitality_boost", "name": "Усиление живучести"},
	{"id": "stamina_boost", "name": "Усиление выносливости"},
	{"id": "luck_boost", "name": "Усиление удачи"},
	{"id": "strength_boost", "name": "Усиление силы"},
	{"id": "agility_boost", "name": "Усиление ловкости"},
	{"id": "focus_boost", "name": "Усиление фокуса"},
	{"id": "intelligence_boost", "name": "Усиление интеллекта"},
	{"id": "perception_boost", "name": "Усиление восприятия"},
	{"id": "movement_speed", "name": "Скорость движения"},
	{"id": "carry_capacity", "name": "Грузоподъёмность"}
]

# РЕДКИЕ (15)
const PASSIVE_RARE = [
	{"id": "regeneration", "name": "Регенерация"},
	{"id": "critical_strike", "name": "Критический удар"},
	{"id": "dodge_chance", "name": "Шанс уклонения"},
	{"id": "damage_reduction", "name": "Снижение урона"},
	{"id": "mana_regen", "name": "Регенерация маны"},
	{"id": "resource_mastery", "name": "Мастерство ресурсов"}
]

# ЛЕГЕНДАРНЫЕ (10)
const PASSIVE_LEGENDARY = [
	{"id": "ocean_sense", "name": "Чувство океана"},
	{"id": "second_wind", "name": "Второе дыхание"},
	{"id": "battle_trance", "name": "Боевой транс"}
]

# МИФИЧЕСКИЕ (5)
const PASSIVE_MYTHIC = [
	{"id": "immortal_soul", "name": "Бессмертная душа"},
	{"id": "ocean_mastery", "name": "Мастерство океана"}
]

