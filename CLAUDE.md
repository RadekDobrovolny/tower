# Tower

2D hra v Godotu 4.7 (GDScript) s pohledem shora: hráč provozuje vesmírnou čerpací stanici, jeho personál tankuje přilétající lodě a stanici brání proti pirátům. Cílová platforma je web (HTML5 export).

Návrh hry, otevřené otázky a plán vývoje jsou v [docs/design.md](docs/design.md). Když se změní rozhodnutí o hře, aktualizuj i tento dokument.

## Technické volby
- Renderer **Compatibility** (`gl_compatibility`), protože ho vyžaduje web export.
- Rozlišení 1280×720, stretch `canvas_items` + aspect `keep`.
- Hra je kontinuální: jedna scéna světa `res://game/world.tscn` se skriptem `game/campaign.gd` (`Campaign`) a mise za sebou. Mise jsou zdroje `missions/mission_*.tres` (třída `Mission`: pravidla, cíle, startovní stav), jejich pořadí určuje `missions/missions.gd`. Novou misi přidej tam.
- Hlavní scéna je menu (`res://ui/main_menu.tscn`), kde se vybírá, od které mise začít (`Game.start_mission`). Startovní stav mise se použije jen tehdy, když hra začne od ní. Při plynulé hře se stav stanice přenáší a nová mise jen zapne svá pravidla (`Campaign._begin_mission`).
- Ovládání je klikáním: `Station._unhandled_input` vybere objekt (android, zásobník, stavební dron, budova, prázdná parcela) a HUD otevře info panel. Každý vybratelný objekt má `info_title()`, `info_lines()` a `info_actions() -> Array[ShopItem]` (text, cena nebo -1, akce). Akce s cenou -1 (teď nejde koupit) HUD vůbec nezobrazí, na co hráč nemá, ukáže šedě. Nové vylepšení přidáš do `info_actions()` daného objektu.
- Budovy (`station/building.gd`, potomci `FuelSlot` a `EntertainmentSystem`) stojí na parcelách (`station/plot.gd`). Staví se po částech (`build_phases()`: název, cena, doba). Každou část hráč platí zvlášť (`Building.start_next_phase()`) a stavební dron Bzučák (`construction/`) ji postaví. Vylepšení zadává `Station.queue_job()`. Novou budovu přidej do `Station.BUILDING_SCENES` a do `Station.build_options()`.
- Stavební dron se jmenuje **Bzučák** (4. pád „Bzučáka“).
- `Campaign.get_shop_items()` sbírá všechny akce ze všech objektů. Používá ho robotický hráč v simulaci.
- Ekonomika galaxínu (zásobník `economy/galaxin_tank.gd`, dodavatelé a cisterny `economy/supply.gd`, prodejní cena ve `Station`) se zapíná pravidlem mise `galaxin_economy` (`Station.enable_galaxin_economy`). Bez ní je zásobník neomezený a cena pevná 6 kr/j. Parametry dodavatelů jsou v `Supply.SUPPLIERS`.

## Konvence
- Soubory a složky v snake_case. Scéna a její skript leží vedle sebe, seskupené podle funkce (`game/`, `missions/`, `station/`, `construction/`, `ships/`, `staff/`, `economy/`, `space/`, `ui/`). Vývojářské nástroje jsou v `tools/` a do exportu se nedostanou. Grafika a zvuky v `assets/`.
- Globální stav rozehrané hry (kredity, statistiky lodí, mise, od které se začíná) drží autoload `Game` v `game.gd`. Kampaň ho na začátku hry vynuluje přes `Game.reset()`, mezi misemi se nenuluje.
- Grafika se postupně generuje přes plugin SpriteCook podle sekce Vizuální styl v `docs/design.md`. Hotové obrázky jsou v `assets/sprites/` a jejich SpriteCook ID v `spritecook-assets.json` (u každého `asset_id`, `sha12` a popisek). Co ještě není vygenerované, zůstává jako jednoduché tvary (`Polygon2D`, `Line2D`).
- Archy 2×2 ze SpriteCooku rozstříhej `godot --headless --path . -s res://tools/slice_sheet.gd -- arch.png 4 max_px cíl1.png …` (objekty hledá jako souvislé oblasti viditelných pixelů, pojmenuje je zleva doprava a shora dolů).
- Sprity ve hře zmenšuj lokálně na zhruba dvojnásobek největší velikosti, v jaké se ve hře zobrazí (kvůli velikosti web buildu), a importuj je s mipmapami (`mipmaps/generate=true` v `.import`). Výchozí filtr textur v projektu je lineární s mipmapami.
- Animace postav jsou vodorovné pásy po 8 snímcích (`Sprite2D.hframes`), všechny animace jedné postavy oříznuté stejným rámečkem. Větší pásy importuj ztrátově (`compress/mode=1`, `compress/lossy_quality=0.9`).
- UI používá projektové téma `ui/theme/game_theme.tres` (písmo Chakra Petch, styly tlačítek a panelů). Varianty: `HudTitle` (nadpis), `HudKicker` (malý prostrkaný popisek), `HudDim` (tlumený text), `HudValue` (velké číslo), `HudThinBar` (tenký ukazatel postupu), `PrimaryButton` (hlavní akce), `FlatButton` (ikonka bez rámečku). Panel HUD je `PanelContainer` se skriptem `ui/hud_panel.gd` (shader se scanlines, svítícími rohy a odkrytím).
- Ceny v HUD: texty dál píšou „1 200 kr“ a HUD je převede přes `UiIcons.money_bbcode()` na číslo s ikonkou mince (pro `RichTextLabel` s BBCode). Tlačítka akcí jsou `ActionButton` (ikonka podle `ShopItem.kind`, popisek, cena s mincí).
- Texty ve hře jsou česky. Palivo se jmenuje **galaxín** (s malým g jako benzín, velké G jen na začátku věty), android **Pumpík**. Hlášky postav patří do `dialogue/lines.gd`, ne přímo do skriptů. Oslovení používají 5. pád (`{android}` = „Pumpíku“).
- GDScript se statickými typy (`var hp: int`, `func foo() -> void`).
- Soubory `*.uid`, které Godot generuje ke skriptům, patří do gitu.
- `.godot/` je cache: needitovat, necommitovat.

## Ověření z příkazové řádky
- `godot --headless --path . --import`: naimportuje assety a vygeneruje `.uid` soubory.
- `godot --headless --path . --quit-after 60`: spustí hlavní scénu na 60 snímků a vypíše případné chyby. Rovnou do hry (mise 1) se dostaneš přidáním `res://game/world.tscn`.
- Přidej `--fixed-fps 60`, aby hra běžela rychleji než v reálném čase a s pevným `delta` (např. `--fixed-fps 60 --quit-after 3600` je minuta herního času).
- `godot --headless --path . --fixed-fps 60 -s res://tools/balance_sim.gd -- [mise] [all]`: odehraje hru „robotickým hráčem“, který koupí a postaví cokoli, na co má, a vypíše časovou osu a časy splnění misí. `mise` = od které mise začít (výchozí 1), `all` = pokračovat přes všechny mise. Spouštěj ji jen tehdy, když o vyvážení tempa požádá uživatel.
- Skripty spouštěné přes `-s` se kompilují dřív, než existují autoloady. Nesmí proto staticky odkazovat na herní třídy (`Campaign`, `Android`…) ani na `Game`. Autoload si vezmou přes `root.get_node("Game")`.

## Web export
- Preset „Web“ v `export_presets.cfg` je bez vláken (`thread_support=false`), takže hra funguje i na itch.io bez hlaviček COOP/COEP.
- Export: `godot --headless --path . --export-release "Web" build/web/index.html` (složka `build/` je v `.gitignore`).
- Lokální test: konfigurace `web` v `.claude/launch.json` spustí server na portu 8060 nad `build/web`.
- Nainstalované jsou jen webové šablony Godotu 4.7.2. Pro jiné platformy je doinstaluj přes Editor → Manage Export Templates.
