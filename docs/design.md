# Návrh hry

Pracovní název: **Tower**

## Koncept

Sci-fi fantasy z budoucnosti, odehrává se ve vesmíru. Hráč vlastní **vesmírnou čerpací stanici**, ke které přilétají malé lodě natankovat **galaxín**, vesmírné palivo. Za vydělané peníze stanici rozšiřuje: přidává čerpací sloty, staví obranné systémy a vylepšuje personál. Občas na stanici zaútočí **vesmírní piráti**.

## Základní rozhodnutí

| Oblast | Rozhodnutí |
|---|---|
| Platforma | 2D, hraje se v prohlížeči, ovládání myší |
| Pohled | Shora. Stanice je plošina, lodě přilétají z okolního vesmíru. |
| Tankování | Lodě obsluhuje **personál**: zaměstnanec dojde k zakotvené lodi a natankuje ji. |
| Boj | **Nepřímý**: věže a ochranka bojují samy, hráč staví a vylepšuje obranu předem i během útoku. |
| Struktura | Level běží nepřetržitě a má cíl (např. vydělat určitou částku). Level 1 je krátký úvod na pár minut, další levely by měly trvat **aspoň 20 minut**. |

## Herní smyčka

1. Loď přiletí a zakotví u volného čerpacího slotu. Když je všechno obsazené, čeká ve frontě.
2. Volný zaměstnanec k ní dojde a natankuje ji. Doba tankování závisí na velikosti lodi a dovednosti zaměstnance.
3. Loď zaplatí a odletí. Když čeká příliš dlouho, odletí bez placení.
4. Za vydělané peníze hráč kupuje sloty, personál, obranu a upgrady.
5. Čas od času zaútočí piráti a s postupem levelu jsou útoky silnější.

## Svět a postavy

- **Galaxín:** vesmírné palivo, které stanice prodává. Píše se s malým g jako běžné palivo (natankovat galaxín, plná nádrž galaxínu), velké G jen na začátku věty. Do budoucna se nabízí víc druhů, např. *galaxín Natural* a *galaxín Super*.
- **Pumpík:** první android na stanici, tankuje lodě. Lodě ho znají a oslovují ho („Ahoj, Pumpíku!“).
- **Hlášky:** lodě i Pumpík mluví v bublinách. Lodě zdraví, objednávají, stěžují si ve frontě, naštvaně odlétají a děkují, Pumpík odpovídá a raduje se z vylepšení. Všechny hlášky jsou v `dialogue/lines.gd`.

## Systémy

### Lodě (zákazníci)
- Různé typy lodí se liší velikostí nádrže, trpělivostí a platbou. Na začátek stačí jeden typ.
- Loď chce buď plnou nádrž, nebo galaxín jen za určitou částku („Chci galaxínu za 100 kreditů“).
- S postupem levelu přilétá víc lodí a přibývají náročnější zákazníci.

### Čerpací sloty
- Hráč přidává další sloty.
- Upgrady zvyšují rychlost čerpadla a případně umožní obsluhovat větší lodě.

### Personál
- **Androidi** (tankovači) obsluhují lodě. Vylepšuje se jim rychlost chůze a rychlost tankování.
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

## Level 1

Úvodní level, ve kterém se hráč naučí obsluhu lodí a vylepšování personálu. Pokrývá kroky 3 a 4 plánu vývoje.

**Výchozí stav:** 1 čerpací slot, android Pumpík na levelu 1, 0 kr.

**Cíle** (musí platit oba zároveň):
- Mít na účtu **2 000 kr**. Počítá se zůstatek, peníze utracené za vylepšení se tedy do cíle nezapočítávají.
- Mít Pumpíka na **levelu 3**.

**Piráti:** v levelu 1 nejsou, přijdou až s krokem 5 plánu.

### Pumpík
- Čeká u čerpadla. Když loď přistane, dojde k ní a natankuje ji.
- Vylepšení zrychlí chůzi i tankování:

| Level | Chůze | Tankování | Cena vylepšení | Barva |
|---|---|---|---|---|
| 1 | 80 px/s | 8 j/s | výchozí | šedá |
| 2 | 110 px/s | 12 j/s | 1 000 kr | tyrkysová |
| 3 | 140 px/s | 18 j/s | 2 500 kr | zlatá |

### Lodě
- Přilétají každé 3–7 s, v průměru tedy každých 5 s.
- Když je slot obsazený, čekají ve frontě (max. 4 lodě). Po 20 s čekání odletí bez placení.
- Galaxín stojí 6 kr za jednotku.
- 65 % lodí chce plnou nádrž, v průměru asi 58 jednotek za zhruba 350 kr.
- 35 % lodí chce galaxín jen za 100, 150, 200 nebo 250 kr (vždy méně, než by stála plná nádrž).
- 10 % lodí nechá Pumpíkovi dýško ve výši 10–20 % ceny (v průměru 15 %). Dýško se přičte ke kreditům stanice.

### Hlášky
| Kdy | Kdo | Jak často |
|---|---|---|
| Přistání: pozdrav Pumpíka | loď | 50 % |
| Přistání: objednávka (plná nádrž nebo částka) | loď | vždy |
| Pumpík začíná tankovat | Pumpík | 50 % |
| Ve frontě po polovině trpělivosti | loď | 60 % |
| Odlet bez placení (červená bublina) | loď | vždy |
| Odlet po zaplacení: dýško | loď, Pumpík poděkuje | 10 % |
| Odlet po zaplacení: poděkování (když nebylo dýško) | loď | 50 % |
| Vylepšení | Pumpík | vždy |

### Tempo
- Simulací (`tools/balance_sim.gd`) změřeno ještě pro cíl 10 000 kr: „robotický hráč“, který vylepšuje hned, jak na to má, dostane Pumpíka na level 2 kolem 0:40 a na level 3 kolem 1:45.
- S cílem 2 000 kr pak stačí zhruba další půlminuta, level by tedy měl trvat kolem 2,5 minuty. Jde o odhad, simulací ověřený není.

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
2. ~~**Stanice a lodě:** stanice se sloty, lodě přilétají, kotví, natankují se automaticky a odletí. Hned potom první test web exportu.~~ ✅
3. ~~**Personál:** tankovač chodí k lodím a tankuje je, lodě čekají ve frontě a mají omezenou trpělivost.~~ ✅ (level 1)
4. **Ekonomika a HUD:** kredity, cíle levelu a vylepšení androida jsou hotové (level 1). Zbývá nákup slotů a zaměstnanců.
5. **Piráti, výsadek:** piráti vystoupí z lodi a útočí na stanici, brání ji ochranka a věže. Podmínka prohry.
6. **Upgrady:** personál, sloty, obrana.
7. **Piráti, útok lodí:** pirátské lodě útočí na obranné systémy.
8. **Vyladění:** vyvážení na 20+ minut hraní, grafika, zvuky, export na itch.io.
