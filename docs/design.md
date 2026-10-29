# Návrh hry

Pracovní název: **Tower**

## Koncept

Sci-fi fantasy z budoucnosti, odehrává se ve vesmíru. Hráč vlastní **vesmírnou čerpací stanici**, ke které přilétají malé lodě doplnit palivo. Za vydělané peníze stanici rozšiřuje: přidává čerpací sloty, staví obranné systémy a vylepšuje personál. Občas na stanici zaútočí **vesmírní piráti**.

## Základní rozhodnutí

| Oblast | Rozhodnutí |
|---|---|
| Platforma | 2D, hraje se v prohlížeči, ovládání myší |
| Pohled | Shora. Stanice je plošina, lodě přilétají z okolního vesmíru. |
| Tankování | Lodě obsluhuje **personál**: zaměstnanec dojde k zakotvené lodi a natankuje ji. |
| Boj | **Nepřímý**: věže a ochranka bojují samy, hráč staví a vylepšuje obranu předem i během útoku. |
| Struktura | Level běží nepřetržitě a má cíl (např. vydělat určitou částku). Jeden level má trvat **aspoň 20 minut**. |

## Herní smyčka

1. Loď přiletí a zakotví u volného čerpacího slotu. Když je všechno obsazené, čeká ve frontě.
2. Volný zaměstnanec k ní dojde a natankuje ji. Doba tankování závisí na velikosti lodi a dovednosti zaměstnance.
3. Loď zaplatí a odletí. Když čeká příliš dlouho, odletí bez placení.
4. Za vydělané peníze hráč kupuje sloty, personál, obranu a upgrady.
5. Čas od času zaútočí piráti a s postupem levelu jsou útoky silnější.

## Systémy

### Lodě (zákazníci)
- Různé typy lodí se liší velikostí nádrže, trpělivostí a platbou. Na začátek stačí jeden typ.
- S postupem levelu přilétá víc lodí a přibývají náročnější zákazníci.

### Čerpací sloty
- Hráč přidává další sloty.
- Upgrady zvyšují rychlost čerpadla a případně umožní obsluhovat větší lodě.

### Personál
- **Tankovači** obsluhují lodě. Vylepšuje se jim rychlost chůze a rychlost tankování.
- **Ochranka** bojuje s piráty, kteří se vylodili na stanici.
- Personál se nabírá a trénuje.

### Obrana
- Obranné věže stojí na stanici.
- Typy věží se liší podle cíle: jedny míří na piráty pěšky, jiné na pirátské lodě.

### Piráti
- **Fáze 1, výsadek:** pirátská loď přiletí, piráti vystoupí a útočí na stanici. Bojují proti nim ochranka a věže.
- **Fáze 2, útok lodí:** pirátské lodě útočí z vesmíru přímo na obranné systémy.

### Cíl a prohra
- **Výhra:** splnění cíle levelu, například vydělat X kreditů.
- **Prohra:** zatím otevřené (viz níže).

## Otevřené otázky

- Co způsobí prohru? Zničení jádra nebo hlavní nádrže stanice? Bankrot?
- Co piráti chtějí? Krást palivo nebo peníze, ničit sloty, unášet personál?
- Jak se staví: na pevné pozice, nebo volně na mřížku?
- Je palivo neomezené, nebo se musí nakupovat do zásobníku (marže mezi nákupem a prodejem)?
- Bude stanice mít reputaci, která ovlivní počet zákazníků?
- Kolik bude levelů nebo stanic a čím se budou lišit?

## Plán vývoje

Do kroku 8 se používají jednoduché barevné tvary, grafika přijde na řadu, až bude hra hratelná.

1. ~~Kostra projektu~~ ✅
2. **Stanice a lodě:** stanice se sloty, lodě přilétají, kotví, natankují se automaticky a odletí. Hned potom první test web exportu.
3. **Personál:** tankovač chodí k lodím a tankuje je, lodě čekají ve frontě a mají omezenou trpělivost.
4. **Ekonomika a HUD:** kredity, cíl levelu, nákup slotů a zaměstnanců.
5. **Piráti, výsadek:** piráti vystoupí z lodi a útočí na stanici, brání ji ochranka a věže. Podmínka prohry.
6. **Upgrady:** personál, sloty, obrana.
7. **Piráti, útok lodí:** pirátské lodě útočí na obranné systémy.
8. **Vyladění:** vyvážení na 20+ minut hraní, grafika, zvuky, export na itch.io.
