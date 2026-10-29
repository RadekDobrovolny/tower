# Tower

2D hra v Godotu 4.7 (GDScript) s pohledem shora: hráč provozuje vesmírnou čerpací stanici, jeho personál tankuje přilétající lodě a stanici brání proti pirátům. Cílová platforma je web (HTML5 export).

Návrh hry, otevřené otázky a plán vývoje jsou v [docs/design.md](docs/design.md). Když se změní rozhodnutí o hře, aktualizuj i tento dokument.

## Technické volby
- Renderer **Compatibility** (`gl_compatibility`), protože ho vyžaduje web export.
- Rozlišení 1280×720, stretch `canvas_items` + aspect `keep`.
- Hlavní scéna: `res://main.tscn`.

## Konvence
- Soubory a složky v snake_case. Scéna a její skript leží vedle sebe, seskupené podle funkce (`station/`, `ships/`, `space/`, `ui/`). Grafika a zvuky v `assets/`.
- Globální stav hry (kredity) drží autoload `Game` v `game.gd`.
- Dokud není hra hratelná, grafika jsou jen jednoduché tvary (`Polygon2D`, `Line2D`).
- GDScript se statickými typy (`var hp: int`, `func foo() -> void`).
- Soubory `*.uid`, které Godot generuje ke skriptům, patří do gitu.
- `.godot/` je cache: needitovat, necommitovat.

## Ověření z příkazové řádky
- `godot --headless --path . --import`: naimportuje assety a vygeneruje `.uid` soubory.
- `godot --headless --path . --quit-after 60`: spustí hlavní scénu na 60 snímků a vypíše případné chyby.
- Přidej `--fixed-fps 60`, aby hra běžela rychleji než v reálném čase a s pevným `delta` (např. `--fixed-fps 60 --quit-after 3600` je minuta herního času).

## Web export
- Preset „Web“ v `export_presets.cfg` je bez vláken (`thread_support=false`), takže hra funguje i na itch.io bez hlaviček COOP/COEP.
- Export: `godot --headless --path . --export-release "Web" build/web/index.html` (složka `build/` je v `.gitignore`).
- Lokální test: konfigurace `web` v `.claude/launch.json` spustí server na portu 8060 nad `build/web`.
- Nainstalované jsou jen webové šablony Godotu 4.7.2. Pro jiné platformy je doinstaluj přes Editor → Manage Export Templates.
