class GameEntity {
  final int id;
  final String assetName; // The filename without extension in assets/ folder
  final String en;
  final String ru;
  final String category;
  final int tier;
  final int? blessingId;

  const GameEntity({
    required this.id,
    required this.assetName,
    required this.en,
    required this.ru,
    this.category = 'hero',
    this.tier = 3,
    this.blessingId,
  });
}

class GameData {
  // === SPELLS (IDs from mlbb_history_parser.py) ===
  static const List<GameEntity> spells = [
    GameEntity(id: 20150, assetName: 'execute', en: 'Execute', ru: 'Кара'),
    GameEntity(id: 20020, assetName: 'retribution', en: 'Retribution', ru: 'Возмездие'),
    GameEntity(id: 20030, assetName: 'inspire', en: 'Inspire', ru: 'Вдохновение'),
    GameEntity(id: 20040, assetName: 'sprint', en: 'Sprint', ru: 'Спринт'),
    GameEntity(id: 20050, assetName: 'revitalize', en: 'Revitalize', ru: 'Исцеление'),
    GameEntity(id: 20060, assetName: 'aegis', en: 'Aegis', ru: 'Щит'),
    GameEntity(id: 20070, assetName: 'petrify', en: 'Petrify', ru: 'Оцепенение'),
    GameEntity(id: 20080, assetName: 'purify', en: 'Purify', ru: 'Очищение'),
    GameEntity(id: 20100, assetName: 'flicker', en: 'Flicker', ru: 'Вспышка'),
    GameEntity(id: 20110, assetName: 'arrival', en: 'Arrival', ru: 'Прибытие'),
    GameEntity(id: 20140, assetName: 'flameshot', en: 'Flameshot', ru: 'Огненный выстрел'),
    GameEntity(id: 20190, assetName: 'vengeance', en: 'Vengeance', ru: 'Отомщение'),
  ];

  // === HEROES (IDs are placeholders, user will update) ===
  static const List<GameEntity> heroes = [
    // 2016
    GameEntity(id: 1, assetName: 'miya', en: 'Miya', ru: 'Мия'),
    GameEntity(id: 2, assetName: 'balmond', en: 'Balmond', ru: 'Бальмонд'),
    GameEntity(id: 3, assetName: 'saber', en: 'Saber', ru: 'Сабер'),
    GameEntity(id: 4, assetName: 'alice', en: 'Alice', ru: 'Алиса'),
    GameEntity(id: 5, assetName: 'nana', en: 'Nana', ru: 'Нана'),
    GameEntity(id: 6, assetName: 'tigreal', en: 'Tigreal', ru: 'Тигрил'),
    GameEntity(id: 7, assetName: 'alucard', en: 'Alucard', ru: 'Алукард'),
    GameEntity(id: 8, assetName: 'karina', en: 'Karina', ru: 'Карина'),
    GameEntity(id: 9, assetName: 'akai', en: 'Akai', ru: 'Акай'),
    GameEntity(id: 10, assetName: 'franco', en: 'Franco', ru: 'Франко'),
    GameEntity(id: 11, assetName: 'bane', en: 'Bane', ru: 'Бейн'),
    GameEntity(id: 12, assetName: 'bruno', en: 'Bruno', ru: 'Бруно'),
    GameEntity(id: 13, assetName: 'clint', en: 'Clint', ru: 'Клинт'),
    GameEntity(id: 14, assetName: 'rafaela', en: 'Rafaela', ru: 'Рафаэль'),
    GameEntity(id: 15, assetName: 'eudora', en: 'Eudora', ru: 'Эйдора'),
    GameEntity(id: 16, assetName: 'zilong', en: 'Zilong', ru: 'Зилонг'),
    GameEntity(id: 17, assetName: 'fanny', en: 'Fanny', ru: 'Фанни'),
    GameEntity(id: 18, assetName: 'layla', en: 'Layla', ru: 'Лейла'),
    GameEntity(id: 19, assetName: 'minotaur', en: 'Minotaur', ru: 'Минотавр'),
    GameEntity(id: 20, assetName: 'lolita', en: 'Lolita', ru: 'Лолита'),
    GameEntity(id: 21, assetName: 'hayabusa', en: 'Hayabusa', ru: 'Хаябуса'),
    GameEntity(id: 22, assetName: 'freya', en: 'Freya', ru: 'Фрейя'),
    GameEntity(id: 23, assetName: 'gord', en: 'Gord', ru: 'Горд'),
    GameEntity(id: 24, assetName: 'natalia', en: 'Natalia', ru: 'Наталья'),
    GameEntity(id: 25, assetName: 'kagura', en: 'Kagura', ru: 'Кагура'),
    GameEntity(id: 26, assetName: 'chou', en: 'Chou', ru: 'Чу'),
    GameEntity(id: 27, assetName: 'sun', en: 'Sun', ru: 'Сан'),
    // 2017
    GameEntity(id: 28, assetName: 'alpha', en: 'Alpha', ru: 'Альфа'),
    GameEntity(id: 29, assetName: 'ruby', en: 'Ruby', ru: 'Руби'),
    GameEntity(id: 30, assetName: 'yi_sun_shin', en: 'Yi Sun-shin', ru: 'Ли Сун-Син'),
    GameEntity(id: 31, assetName: 'moskov', en: 'Moskov', ru: 'Москов'),
    GameEntity(id: 32, assetName: 'johnson', en: 'Johnson', ru: 'Джонсон'),
    GameEntity(id: 33, assetName: 'cyclops', en: 'Cyclops', ru: 'Циклоп'),
    GameEntity(id: 34, assetName: 'estes', en: 'Estes', ru: 'Эстес'),
    GameEntity(id: 35, assetName: 'hilda', en: 'Hilda', ru: 'Хильда'),
    GameEntity(id: 36, assetName: 'aurora', en: 'Aurora', ru: 'Аврора'),
    GameEntity(id: 37, assetName: 'lapu_lapu', en: 'Lapu-Lapu', ru: 'Лапу-Лапу'),
    GameEntity(id: 38, assetName: 'vexana', en: 'Vexana', ru: 'Вексана'),
    GameEntity(id: 39, assetName: 'roger', en: 'Roger', ru: 'Роджер'),
    GameEntity(id: 40, assetName: 'karrie', en: 'Karrie', ru: 'Кэрри'),
    GameEntity(id: 41, assetName: 'gatotkaca', en: 'Gatotkaca', ru: 'Гатоткача'),
    GameEntity(id: 42, assetName: 'harley', en: 'Harley', ru: 'Харли'),
    GameEntity(id: 43, assetName: 'irithel', en: 'Irithel', ru: 'Иритель'),
    GameEntity(id: 44, assetName: 'grock', en: 'Grock', ru: 'Грок'),
    GameEntity(id: 45, assetName: 'argus', en: 'Argus', ru: 'Аргус'),
    GameEntity(id: 46, assetName: 'odette', en: 'Odette', ru: 'Одетта'),
    GameEntity(id: 47, assetName: 'lancelot', en: 'Lancelot', ru: 'Ланселот'),
    GameEntity(id: 48, assetName: 'diggie', en: 'Diggie', ru: 'Дигги'),
    GameEntity(id: 49, assetName: 'hylos', en: 'Hylos', ru: 'Хилос'),
    GameEntity(id: 50, assetName: 'zhask', en: 'Zhask', ru: 'Заск'),
    GameEntity(id: 51, assetName: 'helcurt', en: 'Helcurt', ru: 'Хелкарт'),
    GameEntity(id: 52, assetName: 'pharsa', en: 'Pharsa', ru: 'Фарса'),
    // 2018
    GameEntity(id: 53, assetName: 'lesley', en: 'Lesley', ru: 'Лесли'),
    GameEntity(id: 54, assetName: 'jawhead', en: 'Jawhead', ru: 'Кусака'),
    GameEntity(id: 55, assetName: 'angela', en: 'Angela', ru: 'Ангела'),
    GameEntity(id: 56, assetName: 'gusion', en: 'Gusion', ru: 'Госсен'),
    GameEntity(id: 57, assetName: 'valir', en: 'Valir', ru: 'Валир'),
    GameEntity(id: 58, assetName: 'martis', en: 'Martis', ru: 'Мартис'),
    GameEntity(id: 59, assetName: 'uranus', en: 'Uranus', ru: 'Уранус'),
    GameEntity(id: 60, assetName: 'hanabi', en: 'Hanabi', ru: 'Ханаби'),
    GameEntity(id: 61, assetName: 'change', en: 'Chang\'e', ru: 'Чан\'Э'),
    GameEntity(id: 62, assetName: 'kaja', en: 'Kaja', ru: 'Кайя'),
    GameEntity(id: 63, assetName: 'selena', en: 'Selena', ru: 'Селена'),
    GameEntity(id: 64, assetName: 'aldous', en: 'Aldous', ru: 'Алдос'),
    GameEntity(id: 65, assetName: 'claude', en: 'Claude', ru: 'Клауд'),
    GameEntity(id: 66, assetName: 'vale', en: 'Vale', ru: 'Вейл'),
    GameEntity(id: 67, assetName: 'leomord', en: 'Leomord', ru: 'Леоморд'),
    GameEntity(id: 68, assetName: 'lunox', en: 'Lunox', ru: 'Люнокс'),
    GameEntity(id: 69, assetName: 'hanzo', en: 'Hanzo', ru: 'Ханзо'),
    GameEntity(id: 70, assetName: 'belerick', en: 'Belerick', ru: 'Белерик'),
    GameEntity(id: 71, assetName: 'kimmy', en: 'Kimmy', ru: 'Кимми'),
    GameEntity(id: 72, assetName: 'thamuz', en: 'Thamuz', ru: 'Тамуз'),
    GameEntity(id: 73, assetName: 'harith', en: 'Harith', ru: 'Харит'),
    GameEntity(id: 74, assetName: 'minsitthar', en: 'Minsitthar', ru: 'Минситтар'),
    GameEntity(id: 75, assetName: 'kadita', en: 'Kadita', ru: 'Кадита'),
    // 2019
    GameEntity(id: 76, assetName: 'faramis', en: 'Faramis', ru: 'Фарамис'),
    GameEntity(id: 77, assetName: 'badang', en: 'Badang', ru: 'Баданг'),
    GameEntity(id: 78, assetName: 'khufra', en: 'Khufra', ru: 'Хуфра'),
    GameEntity(id: 79, assetName: 'granger', en: 'Granger', ru: 'Грейнджер'),
    GameEntity(id: 80, assetName: 'guinevere', en: 'Guinevere', ru: 'Гвиневра'),
    GameEntity(id: 81, assetName: 'esmeralda', en: 'Esmeralda', ru: 'Эсмеральда'),
    GameEntity(id: 82, assetName: 'terizla', en: 'Terizla', ru: 'Теризла'),
    GameEntity(id: 83, assetName: 'xborg', en: 'X.Borg', ru: 'Икс.Борг'),
    GameEntity(id: 84, assetName: 'ling', en: 'Ling', ru: 'Линг'),
    GameEntity(id: 85, assetName: 'dyrroth', en: 'Dyrroth', ru: 'Дайрот'),
    GameEntity(id: 86, assetName: 'lylia', en: 'Lylia', ru: 'Лилия'),
    GameEntity(id: 87, assetName: 'baxia', en: 'Baxia', ru: 'Баксий'),
    GameEntity(id: 88, assetName: 'masha', en: 'Masha', ru: 'Маша'),
    GameEntity(id: 89, assetName: 'wanwan', en: 'Wanwan', ru: 'Ванван'),
    GameEntity(id: 90, assetName: 'silvanna', en: 'Silvanna', ru: 'Сильвана'),
    // 2020
    GameEntity(id: 91, assetName: 'cecilion', en: 'Cecilion', ru: 'Сесилион'),
    GameEntity(id: 92, assetName: 'carmilla', en: 'Carmilla', ru: 'Кармилла'),
    GameEntity(id: 93, assetName: 'atlas', en: 'Atlas', ru: 'Атлас'),
    GameEntity(id: 94, assetName: 'popol_kupa', en: 'Popol and Kupa', ru: 'Пополь и Купа'),
    GameEntity(id: 95, assetName: 'yu_zhong', en: 'Yu Zhong', ru: 'Ю Чонг'),
    GameEntity(id: 96, assetName: 'luo_yi', en: 'Luo Yi', ru: 'Ло Йи'),
    GameEntity(id: 97, assetName: 'benedetta', en: 'Benedetta', ru: 'Бенедетта'),
    GameEntity(id: 98, assetName: 'khaleed', en: 'Khaleed', ru: 'Халид'),
    GameEntity(id: 99, assetName: 'barats', en: 'Barats', ru: 'Баратс'),
    GameEntity(id: 100, assetName: 'brody', en: 'Brody', ru: 'Броуди'),
    // 2021
    GameEntity(id: 101, assetName: 'yve', en: 'Yve', ru: 'Ив'),
    GameEntity(id: 102, assetName: 'mathilda', en: 'Mathilda', ru: 'Матильда'),
    GameEntity(id: 103, assetName: 'paquito', en: 'Paquito', ru: 'Пакито'),
    GameEntity(id: 104, assetName: 'gloo', en: 'Gloo', ru: 'Глу'),
    GameEntity(id: 105, assetName: 'beatrix', en: 'Beatrix', ru: 'Беатрис'),
    GameEntity(id: 106, assetName: 'phoveus', en: 'Phoveus', ru: 'Фовиус'),
    GameEntity(id: 107, assetName: 'natan', en: 'Natan', ru: 'Натан'),
    GameEntity(id: 108, assetName: 'aulus', en: 'Aulus', ru: 'Аулус'),
    GameEntity(id: 109, assetName: 'aamon', en: 'Aamon', ru: 'Эймон'),
    GameEntity(id: 110, assetName: 'valentina', en: 'Valentina', ru: 'Валентина'),
    GameEntity(id: 111, assetName: 'edith', en: 'Edith', ru: 'Эдит'),
    GameEntity(id: 112, assetName: 'floryn', en: 'Floryn', ru: 'Флорин'),
    // 2022
    GameEntity(id: 113, assetName: 'yin', en: 'Yin', ru: 'Инь'),
    GameEntity(id: 114, assetName: 'melissa', en: 'Melissa', ru: 'Мелисса'),
    GameEntity(id: 115, assetName: 'xavier', en: 'Xavier', ru: 'Ксавьер'),
    GameEntity(id: 116, assetName: 'julian', en: 'Julian', ru: 'Джулиан'),
    GameEntity(id: 117, assetName: 'fredrinn', en: 'Fredrinn', ru: 'Фредрин'),
    GameEntity(id: 118, assetName: 'joy', en: 'Joy', ru: 'Джой'),
    // 2023
    GameEntity(id: 119, assetName: 'novaria', en: 'Novaria', ru: 'Новария'),
    GameEntity(id: 120, assetName: 'arlott', en: 'Arlott', ru: 'Арлотт'),
    GameEntity(id: 121, assetName: 'ixia', en: 'Ixia', ru: 'Иксия'),
    GameEntity(id: 122, assetName: 'nolan', en: 'Nolan', ru: 'Нолан'),
    GameEntity(id: 123, assetName: 'cici', en: 'Cici', ru: 'Чичи'),
    // 2024
    GameEntity(id: 124, assetName: 'chip', en: 'Chip', ru: 'Чип'),
    GameEntity(id: 125, assetName: 'zhuxin', en: 'Zhuxin', ru: 'Чжу Синь'),
    GameEntity(id: 126, assetName: 'suyou', en: 'Suyou', ru: 'Су Е'),
    GameEntity(id: 127, assetName: 'lukas', en: 'Lukas', ru: 'Лукас'),
    // 2025
    GameEntity(id: 128, assetName: 'kalea', en: 'Kalea', ru: 'Калеа'),
    GameEntity(id: 129, assetName: 'zetian', en: 'Zetian', ru: 'Зетиан'),
    GameEntity(id: 130, assetName: 'obsidia', en: 'Obsidia', ru: 'Обсидия'),
    GameEntity(id: 131, assetName: 'sora', en: 'Sora', ru: 'Сора'),
  ];

  // === BLESSINGS (Boot Modifiers) - Needed for UI/Icons ===
  static const List<GameEntity> blessings = [
     // Jungle
     GameEntity(id: 20001, assetName: 'flame_retribution', en: 'Flame Retribution', ru: 'Пламенное Возмездие', category: 'jungle'),
     GameEntity(id: 20002, assetName: 'ice_retribution', en: 'Ice Retribution', ru: 'Ледяное Возмездие', category: 'jungle'),
     GameEntity(id: 20003, assetName: 'bloody_retribution', en: 'Bloody Retribution', ru: 'Кровавое Возмездие', category: 'jungle'),
     // Roam
     GameEntity(id: 20004, assetName: 'conceal', en: 'Conceal', ru: 'Маскировка', category: 'roam'),
     GameEntity(id: 20005, assetName: 'encourage', en: 'Encourage', ru: 'Поощрение', category: 'roam'),
     GameEntity(id: 20006, assetName: 'favor', en: 'Favor', ru: 'Благосклонность', category: 'roam'),
     GameEntity(id: 20007, assetName: 'dire_hit', en: 'Dire Hit', ru: 'Острый Удар', category: 'roam'),
  ];

  // === ITEMS (IDs are placeholders) ===
  static const List<GameEntity> items = [
    // === PHYSICAL ===
    GameEntity(id: 2032, assetName: 'expert_gloves', en: 'Expert Gloves', ru: 'Экспертные Перчатки', category: 'physical', tier: 1),
    GameEntity(id: 2025, assetName: 'dagger', en: 'Dagger', ru: 'Кинжал', category: 'physical', tier: 1),
    GameEntity(id: 2026, assetName: 'knife', en: 'Knife', ru: 'Нож', category: 'physical', tier: 1),
    GameEntity(id: 2028, assetName: 'vampire_mallet', en: 'Vampire Mallet', ru: 'Вампирская Колотушка', category: 'physical', tier: 2),
    GameEntity(id: 2027, assetName: 'javelin', en: 'Javelin', ru: 'Копье', category: 'physical', tier: 1),

    GameEntity(id: 2029, assetName: 'iron_hunting_bow', en: 'Iron Hunting Bow', ru: 'Железный Охотничий Лук', category: 'physical', tier: 2), 
    GameEntity(id: 4050, assetName: 'ogre_tomahawk', en: 'Ogre Tomahawk', ru: 'Томагавк Огра', category: 'physical', tier: 2),
    GameEntity(id: 4049, assetName: 'legion_sword', en: 'Legion Sword', ru: 'Меч Легиона', category: 'physical', tier: 2),
    GameEntity(id: 4051, assetName: 'swift_crossbow', en: 'Swift Crossbow', ru: 'Арбалет Охотника', category: 'physical', tier: 2), 
    GameEntity(id: 2030, assetName: 'regular_spear', en: 'Regular Spear', ru: 'Обычное Копье', category: 'physical', tier: 2),
    GameEntity(id: 4052, assetName: 'fury_hammer', en: 'Fury Hammer', ru: 'Молот Гнева', category: 'physical', tier: 2),
    GameEntity(id: 4053, assetName: 'rogue_meteor', en: 'Rogue Meteor', ru: 'Метеор Бродяги', category: 'physical', tier: 2),

    GameEntity(id: 6085, assetName: 'sea_halberd', en: 'Sea Halberd', ru: 'Трезубец', category: 'physical'),
    GameEntity(id: 6084, assetName: 'rose_gold_meteor', en: 'Rose Gold Meteor', ru: 'Золотой Метеор', category: 'physical'),
    GameEntity(id: 6081, assetName: 'hunter_strike', en: 'Hunter Strike', ru: 'Удар Охотника', category: 'physical'),
    GameEntity(id: 6080, assetName: 'blade_of_despair', en: 'Blade of Despair', ru: 'Клинок Отчаяния', category: 'physical'),
    GameEntity(id: 6079, assetName: 'blade_of_heptaseas', en: 'Blade of the Heptaseas', ru: 'Клинок Семи Морей', category: 'physical'),
    GameEntity(id: 4059, assetName: 'wind_of_nature', en: 'Wind of Nature', ru: 'Ветер Природы', category: 'physical'),
    GameEntity(id: 6073, assetName: 'malefic_roar', en: 'Malefic Roar', ru: 'Злобный Рык', category: 'physical'),
    GameEntity(id: 6075, assetName: 'berserkers_fury', en: 'Berserker\'s Fury', ru: 'Ярость Берсерка', category: 'physical'),
    GameEntity(id: 6076, assetName: 'endless_battle', en: 'Endless Battle', ru: 'Бесконечная Битва', category: 'physical'),
    GameEntity(id: 6077, assetName: 'windtalker', en: 'Windtalker', ru: 'Говорящий с Ветром', category: 'physical'),
    GameEntity(id: 6074, assetName: 'haass_claws', en: 'Haas\'s Claws', ru: 'Когти Хааса', category: 'physical'),
    GameEntity(id: 4056, assetName: 'corrosion_scythe', en: 'Corrosion Scythe', ru: 'Коса Коррозии', category: 'physical'),
    GameEntity(id: 4054, assetName: 'demon_hunter_sword', en: 'Demon Hunter Sword', ru: 'Меч Охотника на Демонов', category: 'physical'),
    GameEntity(id: 4057, assetName: 'golden_staff', en: 'Golden Staff', ru: 'Золотой Посох', category: 'physical'),
    GameEntity(id: 4061, assetName: 'war_axe', en: 'War Axe', ru: 'Топор Войны', category: 'physical'),
    GameEntity(id: 6086, assetName: 'great_dragon_spear', en: 'Great Dragon Spear', ru: 'Копье Великого Дракона', category: 'physical'),
    GameEntity(id: 4062, assetName: 'sky_piercer', en: 'Sky Piercer', ru: 'Небесный Пронзатель', category: 'physical'),
    GameEntity(id: 6087, assetName: 'malefic_gun', en: 'Malefic Gun', ru: 'Злобный Пистолет', category: 'physical'),

    // === MAGIC ===
    GameEntity(id: 2253, assetName: 'mystery_codex', en: 'Mystery Codex', ru: 'Книга Тайн', category: 'magic', tier: 1),
    GameEntity(id: 2254, assetName: 'power_crystal', en: 'Power Crystal', ru: 'Кристалл Силы', category: 'magic', tier: 1), 
    GameEntity(id: 2255, assetName: 'magic_necklace', en: 'Magic Necklace', ru: 'Магическая Ожерелье', category: 'magic', tier: 1),

    GameEntity(id: 2257, assetName: 'mystic_container', en: 'Mystic Container', ru: 'Мистический Контейнер', category: 'magic', tier: 2),
    GameEntity(id: 4277, assetName: 'magic_wand', en: 'Magic Wand', ru: 'Магическая Палочка', category: 'magic', tier: 2),
    GameEntity(id: 4278, assetName: 'tome_of_evil', en: 'Tome of Evil', ru: 'Книга Зла', category: 'magic', tier: 2),
    GameEntity(id: 2256, assetName: 'book_of_sages', en: 'Book of Sages', ru: 'Книга Мудрецов', category: 'magic', tier: 2),
    GameEntity(id: 4280, assetName: 'exotic_veil', en: 'Exotic Veil', ru: 'Вуаль Странника', category: 'magic', tier: 2),
    GameEntity(id: 4281, assetName: 'elegant_gem', en: 'Elegant Gem', ru: 'Элегантный Самоцвет', category: 'magic', tier: 2),
    GameEntity(id: 4279, assetName: 'azure_blade', en: 'Azure Blade', ru: 'Лазурный Клинок', category: 'magic', tier: 2),

    GameEntity(id: 6311, assetName: 'genius_wand', en: 'Genius Wand', ru: 'Палочка Гения', category: 'magic'),
    GameEntity(id: 6310, assetName: 'lightning_truncheon', en: 'Lightning Truncheon', ru: 'Жезл Молний', category: 'magic'),
    GameEntity(id: 6309, assetName: 'fleeting_time', en: 'Fleeting Time', ru: 'Мимолетное Время', category: 'magic'),
    GameEntity(id: 6308, assetName: 'blood_wings', en: 'Blood Wings', ru: 'Кровавые Крылья', category: 'magic'),
    GameEntity(id: 6313, assetName: 'clock_of_destiny', en: 'Clock of Destiny', ru: 'Часы Судьбы', category: 'magic'),
    GameEntity(id: 6306, assetName: 'starlium_scythe', en: 'Starlium Scythe', ru: 'Коса Звезд', category: 'magic'),
    GameEntity(id: 6305, assetName: 'glowing_wand', en: 'Glowing Wand', ru: 'Пылающий Жезл', category: 'magic'),
    GameEntity(id: 6304, assetName: 'ice_queen_wand', en: 'Ice Queen Wand', ru: 'Жезл Снежной Королевы', category: 'magic'),
    GameEntity(id: 6303, assetName: 'concentrated_energy', en: 'Concentrated Energy', ru: 'Концентрированная Энергия', category: 'magic'),
    GameEntity(id: 6302, assetName: 'holy_crystal', en: 'Holy Crystal', ru: 'Священный Кристалл', category: 'magic'),
    GameEntity(id: 6301, assetName: 'divine_glaive', en: 'Divine Glaive', ru: 'Божественный Меч', category: 'magic'),
    GameEntity(id: 4283, assetName: 'winter_crown', en: 'Winter Crown', ru: 'Зимняя Корона', category: 'magic'), 
    GameEntity(id: 4282, assetName: 'enchanted_talisman', en: 'Enchanted Talisman', ru: 'Зачарованный Талисман', category: 'magic'),
    GameEntity(id: 4284, assetName: 'feather_of_heaven', en: 'Feather of Heaven', ru: 'Райское Перо', category: 'magic'),
    GameEntity(id: 4288, assetName: 'wishing_lantern', en: 'Wishing Lantern', ru: 'Фонарь Желаний', category: 'magic'),
    GameEntity(id: 6312, assetName: 'flask_of_the_oasis', en: 'Flask of the Oasis', ru: 'Фляга Оазиса', category: 'magic'),

    // === DEFENSE ===
    GameEntity(id: 2481, assetName: 'vitality_crystal', en: 'Vitality Crystal', ru: 'Кристалл Живучести', category: 'defense', tier: 1),
    GameEntity(id: 2482, assetName: 'leather_jerkin', en: 'Leather Jerkin', ru: 'Кожаная Куртка', category: 'defense', tier: 1),
    GameEntity(id: 2483, assetName: 'magic_resist_cloak', en: 'Magic Resist Cloak', ru: 'Плащ Магической Защиты', category: 'defense', tier: 1),
    
    GameEntity(id: 4505, assetName: 'ares_belt', en: 'Ares Belt', ru: 'Пояс Ареса', category: 'defense', tier: 2),
    GameEntity(id: 4506, assetName: 'molten_essence', en: 'Molten Essence', ru: 'Расплавленная Эссенция', category: 'defense', tier: 2),
    GameEntity(id: 4508, assetName: 'black_ice_shield', en: 'Black Ice Shield', ru: 'Щит Черного Льда', category: 'defense', tier: 2),
    GameEntity(id: 4509, assetName: 'dreadnaught_armor', en: 'Dreadnaught Armor', ru: 'Броня Устрашения', category: 'defense', tier: 2),
    GameEntity(id: 4507, assetName: 'silence_robe', en: 'Silence Robe', ru: 'Мантия Тишины', category: 'defense', tier: 2),
    GameEntity(id: 4510, assetName: 'steel_legplates', en: 'Steel Legplates', ru: 'Стальные Поножи', category: 'defense', tier: 2),
    GameEntity(id: 2485, assetName: 'heros_ring', en: 'Hero\'s Ring', ru: 'Кольцо Героя', category: 'defense', tier: 2),

    GameEntity(id: 6540, assetName: 'chastise_pauldron', en: 'Chastise Pauldron', ru: 'Плащ Наказания', category: 'defense', tier: 3),
    GameEntity(id: 6538, assetName: 'radiant_armor', en: 'Radiant Armor', ru: 'Сияющая Броня', category: 'defense'),
    GameEntity(id: 6536, assetName: 'brute_force_breastplate', en: 'Brute Force Breastplate', ru: 'Кираса Грубой Силы', category: 'defense'),
    GameEntity(id: 6535, assetName: 'immortality', en: 'Immortality', ru: 'Бессмертие', category: 'defense'),
    GameEntity(id: 6534, assetName: 'dominance_ice', en: 'Dominance Ice', ru: 'Господство Льда', category: 'defense'),
    GameEntity(id: 6533, assetName: 'athenas_shield', en: 'Athena\'s Shield', ru: 'Щит Афины', category: 'defense'),
    GameEntity(id: 6532, assetName: 'oracle', en: 'Oracle', ru: 'Оракул', category: 'defense'),
    GameEntity(id: 6531, assetName: 'antique_cuirass', en: 'Antique Cuirass', ru: 'Древняя Кираса', category: 'defense'),
    GameEntity(id: 6530, assetName: 'guardian_helmet', en: 'Guardian Helmet', ru: 'Шлем Небесного Стража', category: 'defense'),
    GameEntity(id: 6529, assetName: 'cursed_helmet', en: 'Cursed Helmet', ru: 'Проклятый Шлем', category: 'defense'),
    GameEntity(id: 4516, assetName: 'thunder_belt', en: 'Thunder Belt', ru: 'Громовой Пояс', category: 'defense'),
    GameEntity(id: 4512, assetName: 'queens_wings', en: 'Queen\'s Wings', ru: 'Крылья Королевы', category: 'defense'),
    GameEntity(id: 4511, assetName: 'blade_armor', en: 'Blade Armor', ru: 'Шипованная Броня', category: 'defense'),

    // === MOVEMENT (Standard) ===
    GameEntity(id: 2709, assetName: 'boots', en: 'Boots', ru: 'Сапоги', category: 'movement', tier: 1),
    GameEntity(id: 4605, assetName: 'warrior_boots', en: 'Warrior Boots', ru: 'Сапоги Воина', category: 'movement'),
    GameEntity(id: 4606, assetName: 'tough_boots', en: 'Tough Boots', ru: 'Прочные Сапоги', category: 'movement'),
    GameEntity(id: 4607, assetName: 'magic_shoes', en: 'Magic Shoes', ru: 'Магические Сапоги', category: 'movement'),
    GameEntity(id: 4736, assetName: 'arcane_boots', en: 'Arcane Boots', ru: 'Сапоги Заклинателя', category: 'movement'),
    GameEntity(id: 4737, assetName: 'swift_boots', en: 'Swift Boots', ru: 'Сапоги Спешки', category: 'movement'),
    GameEntity(id: 4738, assetName: 'rapid_boots', en: 'Rapid Boots', ru: 'Сапоги-Скороходы', category: 'movement', tier: 3), 
    GameEntity(id: 4740, assetName: 'demon_shoes', en: 'Demon Shoes', ru: 'Обувь Демона', category: 'movement'),
    
    // === BLESSED BOOTS (Generated Combinations) ===
    // Boots (4001) - Basic Tier 1
    GameEntity(id: 2948, assetName: 'boots', en: 'Boots (Flame)', ru: 'Сапоги (Пламя)', category: 'movement', blessingId: 20001, tier: 1),
    GameEntity(id: 2947, assetName: 'boots', en: 'Boots (Ice)', ru: 'Сапоги (Лед)', category: 'movement', blessingId: 20002, tier: 1),
    GameEntity(id: 2949, assetName: 'boots', en: 'Boots (Bloody)', ru: 'Сапоги (Кровь)', category: 'movement', blessingId: 20003, tier: 1),
    GameEntity(id: 3045, assetName: 'boots', en: 'Boots (Conceal)', ru: 'Сапоги (Маскировка)', category: 'movement', blessingId: 20004, tier: 1),
    GameEntity(id: 3046, assetName: 'boots', en: 'Boots (Encourage)', ru: 'Сапоги (Поощрение)', category: 'movement', blessingId: 20005, tier: 1),
    GameEntity(id: 3047, assetName: 'boots', en: 'Boots (Favor)', ru: 'Сапоги (Благосклонность)', category: 'movement', blessingId: 20006, tier: 1),
    GameEntity(id: 3048, assetName: 'boots', en: 'Boots (Dire Hit)', ru: 'Сапоги (Острый Удар)', category: 'movement', blessingId: 20007, tier: 1),

    // Warrior Boots (4002)
    GameEntity(id: 6868, assetName: 'warrior_boots', en: 'Warrior Boots (Flame)', ru: 'Сапоги Воина (Пламя)', category: 'movement', blessingId: 20001),
    GameEntity(id: 6867, assetName: 'warrior_boots', en: 'Warrior Boots (Ice)', ru: 'Сапоги Воина (Лед)', category: 'movement', blessingId: 20002),
    GameEntity(id: 6869, assetName: 'warrior_boots', en: 'Warrior Boots (Bloody)', ru: 'Сапоги Воина (Кровь)', category: 'movement', blessingId: 20003),
    GameEntity(id: 7095, assetName: 'warrior_boots', en: 'Warrior Boots (Conceal)', ru: 'Сапоги Воина (Маскировка)', category: 'movement', blessingId: 20004),
    GameEntity(id: 7096, assetName: 'warrior_boots', en: 'Warrior Boots (Encourage)', ru: 'Сапоги Воина (Поощрение)', category: 'movement', blessingId: 20005),
    GameEntity(id: 7097, assetName: 'warrior_boots', en: 'Warrior Boots (Favor)', ru: 'Сапоги Воина (Благосклонность)', category: 'movement', blessingId: 20006),
    GameEntity(id: 7098, assetName: 'warrior_boots', en: 'Warrior Boots (Dire Hit)', ru: 'Сапоги Воина (Острый Удар)', category: 'movement', blessingId: 20007),
    // Tough Boots (4003)
    GameEntity(id: 6878, assetName: 'tough_boots', en: 'Tough Boots (Flame)', ru: 'Прочные Сапоги (Пламя)', category: 'movement', blessingId: 20001),
    GameEntity(id: 6877, assetName: 'tough_boots', en: 'Tough Boots (Ice)', ru: 'Прочные Сапоги (Лед)', category: 'movement', blessingId: 20002),
    GameEntity(id: 6879, assetName: 'tough_boots', en: 'Tough Boots (Bloody)', ru: 'Прочные Сапоги (Кровь)', category: 'movement', blessingId: 20003),
    GameEntity(id: 7105, assetName: 'tough_boots', en: 'Tough Boots (Conceal)', ru: 'Прочные Сапоги (Маскировка)', category: 'movement', blessingId: 20004),
    GameEntity(id: 7106, assetName: 'tough_boots', en: 'Tough Boots (Encourage)', ru: 'Прочные Сапоги (Поощрение)', category: 'movement', blessingId: 20005),
    GameEntity(id: 7107, assetName: 'tough_boots', en: 'Tough Boots (Favor)', ru: 'Прочные Сапоги (Благосклонность)', category: 'movement', blessingId: 20006),
    GameEntity(id: 7108, assetName: 'tough_boots', en: 'Tough Boots (Dire Hit)', ru: 'Прочные Сапоги (Острый Удар)', category: 'movement', blessingId: 20007),
    // Magic Shoes (4004)
    GameEntity(id: 6888, assetName: 'magic_shoes', en: 'Magic Shoes (Flame)', ru: 'Магические Сапоги (Пламя)', category: 'movement', blessingId: 20001),
    GameEntity(id: 6887, assetName: 'magic_shoes', en: 'Magic Shoes (Ice)', ru: 'Магические Сапоги (Лед)', category: 'movement', blessingId: 20002),
    GameEntity(id: 6889, assetName: 'magic_shoes', en: 'Magic Shoes (Bloody)', ru: 'Магические Сапоги (Кровь)', category: 'movement', blessingId: 20003),
    GameEntity(id: 7115, assetName: 'magic_shoes', en: 'Magic Shoes (Conceal)', ru: 'Магические Сапоги (Маскировка)', category: 'movement', blessingId: 20004),
    GameEntity(id: 7116, assetName: 'magic_shoes', en: 'Magic Shoes (Encourage)', ru: 'Магические Сапоги (Поощрение)', category: 'movement', blessingId: 20005),
    GameEntity(id: 7117, assetName: 'magic_shoes', en: 'Magic Shoes (Favor)', ru: 'Магические Сапоги (Благосклонность)', category: 'movement', blessingId: 20006),
    GameEntity(id: 7118, assetName: 'magic_shoes', en: 'Magic Shoes (Dire Hit)', ru: 'Магические Сапоги (Острый Удар)', category: 'movement', blessingId: 20007),
    // Arcane Boots (4005)
    GameEntity(id: 6898, assetName: 'arcane_boots', en: 'Arcane Boots (Flame)', ru: 'Сапоги Заклинателя (Пламя)', category: 'movement', blessingId: 20001),
    GameEntity(id: 6897, assetName: 'arcane_boots', en: 'Arcane Boots (Ice)', ru: 'Сапоги Заклинателя (Лед)', category: 'movement', blessingId: 20002),
    GameEntity(id: 6899, assetName: 'arcane_boots', en: 'Arcane Boots (Bloody)', ru: 'Сапоги Заклинателя (Кровь)', category: 'movement', blessingId: 20003),
    GameEntity(id: 7125, assetName: 'arcane_boots', en: 'Arcane Boots (Conceal)', ru: 'Сапоги Заклинателя (Маскировка)', category: 'movement', blessingId: 20004),
    GameEntity(id: 7126, assetName: 'arcane_boots', en: 'Arcane Boots (Encourage)', ru: 'Сапоги Заклинателя (Поощрение)', category: 'movement', blessingId: 20005),
    GameEntity(id: 7127, assetName: 'arcane_boots', en: 'Arcane Boots (Favor)', ru: 'Сапоги Заклинателя (Благосклонность)', category: 'movement', blessingId: 20006),
    GameEntity(id: 7128, assetName: 'arcane_boots', en: 'Arcane Boots (Dire Hit)', ru: 'Сапоги Заклинателя (Острый Удар)', category: 'movement', blessingId: 20007),
    // Swift Boots (4006)
    GameEntity(id: 6908, assetName: 'swift_boots', en: 'Swift Boots (Flame)', ru: 'Сапоги Спешки (Пламя)', category: 'movement', blessingId: 20001),
    GameEntity(id: 6907, assetName: 'swift_boots', en: 'Swift Boots (Ice)', ru: 'Сапоги Спешки (Лед)', category: 'movement', blessingId: 20002),
    GameEntity(id: 6909, assetName: 'swift_boots', en: 'Swift Boots (Bloody)', ru: 'Сапоги Спешки (Кровь)', category: 'movement', blessingId: 20003),
    GameEntity(id: 7135, assetName: 'swift_boots', en: 'Swift Boots (Conceal)', ru: 'Сапоги Спешки (Маскировка)', category: 'movement', blessingId: 20004),
    GameEntity(id: 7136, assetName: 'swift_boots', en: 'Swift Boots (Encourage)', ru: 'Сапоги Спешки (Поощрение)', category: 'movement', blessingId: 20005),
    GameEntity(id: 7137, assetName: 'swift_boots', en: 'Swift Boots (Favor)', ru: 'Сапоги Спешки (Благосклонность)', category: 'movement', blessingId: 20006),
    GameEntity(id: 7138, assetName: 'swift_boots', en: 'Swift Boots (Dire Hit)', ru: 'Сапоги Спешки (Острый Удар)', category: 'movement', blessingId: 20007),
    // Demon Shoes (4007)
    GameEntity(id: 6868, assetName: 'demon_shoes', en: 'Demon Shoes (Flame)', ru: 'Обувь Демона (Пламя)', category: 'movement', blessingId: 20001),
    GameEntity(id: 6867, assetName: 'demon_shoes', en: 'Demon Shoes (Ice)', ru: 'Обувь Демона (Лед)', category: 'movement', blessingId: 20002),
    GameEntity(id: 6869, assetName: 'demon_shoes', en: 'Demon Shoes (Bloody)', ru: 'Обувь Демона (Кровь)', category: 'movement', blessingId: 20003),
    GameEntity(id: 7155, assetName: 'demon_shoes', en: 'Demon Shoes (Conceal)', ru: 'Обувь Демона (Маскировка)', category: 'movement', blessingId: 20004),
    GameEntity(id: 7156, assetName: 'demon_shoes', en: 'Demon Shoes (Encourage)', ru: 'Обувь Демона (Поощрение)', category: 'movement', blessingId: 20005),
    GameEntity(id: 7157, assetName: 'demon_shoes', en: 'Demon Shoes (Favor)', ru: 'Обувь Демона (Благосклонность)', category: 'movement', blessingId: 20006),
    GameEntity(id: 7158, assetName: 'demon_shoes', en: 'Demon Shoes (Dire Hit)', ru: 'Обувь Демона (Острый Удар)', category: 'movement', blessingId: 20007),
    // Rapid Boots (4008)
    GameEntity(id: 6858, assetName: 'rapid_boots', en: 'Rapid Boots (Flame)', ru: 'Сапоги-Скороходы (Пламя)', category: 'movement', blessingId: 20001),
    GameEntity(id: 6857, assetName: 'rapid_boots', en: 'Rapid Boots (Ice)', ru: 'Сапоги-Скороходы (Лед)', category: 'movement', blessingId: 20002),
    GameEntity(id: 6859, assetName: 'rapid_boots', en: 'Rapid Boots (Bloody)', ru: 'Сапоги-Скороходы (Кровь)', category: 'movement', blessingId: 20003),
    GameEntity(id: 7145, assetName: 'rapid_boots', en: 'Rapid Boots (Conceal)', ru: 'Сапоги-Скороходы (Маскировка)', category: 'movement', blessingId: 20004),
    GameEntity(id: 7146, assetName: 'rapid_boots', en: 'Rapid Boots (Encourage)', ru: 'Сапоги-Скороходы (Поощрение)', category: 'movement', blessingId: 20005),
    GameEntity(id: 7147, assetName: 'rapid_boots', en: 'Rapid Boots (Favor)', ru: 'Сапоги-Скороходы (Благосклонность)', category: 'movement', blessingId: 20006),
    GameEntity(id: 7148, assetName: 'rapid_boots', en: 'Rapid Boots (Dire Hit)', ru: 'Сапоги-Скороходы (Острый Удар)', category: 'movement', blessingId: 20007),

    // Note: Blessings (Roam/Jungle) combined with boots will have different IDs.
    // The user will map these later. For now, we only list standard items.

    // === OTHER ===
    GameEntity(id: 20113, assetName: 'lantern_of_hope', en: 'Lantern of Hope', ru: 'Фонарь Надежды', category: 'other'),
    GameEntity(id: 20115, assetName: 'flower_of_hope', en: 'Flower of Hope', ru: 'Цветок Надежды', category: 'other'),
  ];
  
  static GameEntity? getHero(int id) {
    try { return heroes.firstWhere((e) => e.id == id); } catch (_) { return null; }
  }
  
  static GameEntity? getItem(int id) {
    try { return items.firstWhere((e) => e.id == id); } catch (_) { return null; }
  }
  
    static GameEntity? getSpell(int id) {
    try {
      return spells.firstWhere((e) => e.id == id);
    } catch (_) {
      try {
        return blessings.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }
  }
  
  
  
    static int getHeroIdByAssetName(String assetName) {
  
      try { return heroes.firstWhere((e) => e.assetName == assetName).id; } catch (_) { return 0; }
  
    }
  
  
  
    static int getItemIdByAssetName(String assetName) {
  
      try { return items.firstWhere((e) => e.assetName == assetName).id; } catch (_) { return 0; }
  
    }
  
    
  
    static int getSpellIdByAssetName(String assetName) {
  
      try { return spells.firstWhere((e) => e.assetName == assetName).id; } catch (_) { return 0; }
  
    }
  
  }
  
  