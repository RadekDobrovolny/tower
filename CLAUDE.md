# Tower

2D hra v Godotu 4.7 (GDScript) s pohledem shora: hráč provozuje vesmírnou čerpací stanici, jeho personál tankuje přilétající lodě a stanici brání proti pirátům. Cílová platforma je web (HTML5 export).

Návrh hry, otevřené otázky a plán vývoje jsou v [docs/design.md](docs/design.md). Když se změní rozhodnutí o hře, aktualizuj i tento dokument.

## Technické volby
- Renderer **Compatibility** (`gl_compatibility`), protože ho vyžaduje web export.
- Rozlišení 1280×720, stretch `canvas_items` + aspect `keep`.
- Hlavní scéna: `res://main.tscn`.

## Konvence
- Soubory a složky v snake_case. Scéna a její skript leží vedle sebe, seskupené podle funkce (`enemies/`, `towers/`, `ui/`). Grafika a zvuky v `assets/`.
- GDScript se statickými typy (`var hp: int`, `func foo() -> void`).
- Soubory `*.uid`, které Godot generuje ke skriptům, patří do gitu.
- `.godot/` je cache: needitovat, necommitovat.

## Ověření z příkazové řádky
- `godot --headless --path . --import`: naimportuje assety a vygeneruje `.uid` soubory.
- `godot --headless --path . --quit-after 60`: spustí hlavní scénu na 60 snímků a vypíše případné chyby.
