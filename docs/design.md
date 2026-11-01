# Návrh hry

Pracovní název: **Tower**

## Koncept

Sci-fi fantasy z budoucnosti, odehrává se ve vesmíru. Hráč vlastní **vesmírnou čerpací stanici**, ke které přilétají malé lodě natankovat **galaxín**, vesmírné palivo. Za vydělané peníze stanici rozšiřuje: přidává čerpací sloty, staví obranné systémy a vylepšuje personál. Občas na stanici zaútočí **vesmírní piráti**.

## Základní rozhodnutí

| Oblast | Rozhodnutí |
|---|---|
| Platforma | 2D, hraje se v prohlížeči, ovládání myší nebo dotykem. Na telefonu se hraje na šířku přes celý displej (na výšku hra vyzve k otočení; na Androidu se po prvním dotyku přepne na celou obrazovku; jde přidat na plochu jako aplikace). Obraz se roztahuje podle poměru stran displeje. |
| Pohled | Shora. Stanice je plošina, lodě přilétají z okolního vesmíru. |
| Tankování | Lodě obsluhuje **personál**: zaměstnanec dojde k zakotvené lodi a natankuje ji. |
| Boj | **Nepřímý**: věže a ochranka bojují samy, hráč staví a vylepšuje obranu předem i během útoku. |
| Struktura | Hra je **kontinuální**: stanice běží pořád dál a **mise** (úkoly) jdou jedna za druhou. Kredity, vylepšení, sloty i zásobník se přenášejí do další mise. Každá mise začíná rozhovorem, ve kterém Pumpík řekne zadání, po splnění se hra pozastaví, ukáže shrnutí a další mise začne svým rozhovorem. Po poslední misi pokračuje volná hra bez cílů. Mise 1 je krátký úvod na pár minut, další mise by měly trvat **aspoň 20 minut**. |
| Ovládání | Hráč kliká na objekty (Pumpík, budovy, zásobník, stavební dron Bzučák, prázdné parcely). Vpravo se otevře info panel s popisem, stavem a tlačítky na vylepšení nebo stavbu. Zobrazují se jen věci, které jde právě koupit. Na co hráč nemá dost kreditů, je vidět, ale šedé. Klik do prázdna panel zavře. |
| Stavění | Nepostavené budovy nejsou vidět, jen velmi jemný obrys prázdné parcely. Po kliknutí na parcelu si hráč vybere, co postavit. Stavba se **platí po částech**: hráč zaplatí část, stavební dron **Bzučák** ji postaví a pak hráč zaplatí další. Budova začne fungovat až po poslední části. Vylepšení budov se platí najednou a Bzučák je pak chvíli staví. |
| Menu | Hra začíná menu, kde jde vybrat, od které mise začít (hodí se hlavně pro testování); pak se použije startovní stav té mise. Poslední volba je **Mise Z**: volná hra bez cílů, kde je všechno postavené a vylepšené na maximum. Pod misemi je **Pumpíkův zápisník**: encyklopedie psaná Pumpíkovým hlasem s kapitolami Lodě, Postavy, Budovy a Svět a s Centrem zvuků. Je přístupná hned od začátku, proto nesmí prozradit tajemství příběhu. Během hry jde hru pozastavit tlačítkem „Menu“ nebo klávesou Esc (pokračovat, začít znovu, hlavní menu). |

## Herní smyčka

1. Loď přiletí a zakotví u volného čerpacího slotu. Když je všechno obsazené, čeká ve frontě.
2. Volný zaměstnanec k ní dojde a natankuje ji. Doba tankování závisí na velikosti lodi a dovednosti zaměstnance.
3. Loď zaplatí a odletí. Když čeká příliš dlouho, odletí bez placení. Když dojde galaxín a žádná cisterna neletí, lodě u čerpadel to po 12 s vzdají (s cisternou na cestě čekají podle své trpělivosti) a odletí všechny včetně fronty. Kdo už tankoval, zaplatí jen to, co dostal, a dýško nedá. Dokud je zásobník prázdný, nové lodě nepřilétají a HUD ukazuje výstrahu.
4. Za vydělané peníze hráč kupuje sloty, personál, obranu a upgrady.
5. Čas od času zaútočí piráti a s postupem levelu jsou útoky silnější.

## Svět a postavy

- **Galaxín:** vesmírné palivo, které stanice prodává. Píše se s malým g jako běžné palivo (natankovat galaxín, plná nádrž galaxínu), velké G jen na začátku věty. Do budoucna se nabízí víc druhů, např. *galaxín Natural* a *galaxín Super*.
- **Pumpík:** první android na stanici, tankuje lodě. Lodě ho znají a oslovují ho („Ahoj, Pumpíku!“).
- **Bzučák:** stavební dron. Staví a vylepšuje budovy na stanici („Čeká na Bzučáka“).
- **Hlášky:** lodě i Pumpík mluví v bublinách. Lodě zdraví, objednávají, stěžují si ve frontě, naštvaně odlétají a děkují, Pumpík odpovídá a raduje se z vylepšení. Všechny hlášky jsou v `dialogue/lines.gd`.

## Vizuální styl

**Atmosféra:** ray-punk a retrofuturismus. Inspirace Flashem Gordonem (art deco, rakety s ploutvemi, vínová a mosaz), Barbarellou (psychedelie, růžová a fialová, smyslnost) a Jodorowským/Moebiem (ozdobné detaily, mystický nádech). Bereme jen styl, žádné konkrétní lodě ani postavy z těch filmů.

**Tón:** dospělý, temný, smyslný a špinavý (noir), ne dětský.
- Tmavá paleta. Výrazně svítí jen neonový galaxín a pár akcentů (tyrkysové hledí Pumpíka).
- Opotřebení: rez stékající od nýtů, olejové skvrny, připálené okraje přistávacích ploch, ošoupaná mosaz.
- Štíhlé a protáhlé tvary místo kulatých a roztomilých.

**Referenční náčrt:** [docs/style/noir_sample.svg](style/noir_sample.svg).

| Barva | Hex | Použití |
|---|---|---|
| Prázdnota | `#0b0812` | vesmír, nejtmavší stíny |
| Krev | `#4a0f1f` | ploutve raket, pumpy, akcenty |
| Ocel | `#1d1a22` | paluba stanice |
| Mosaz | `#8a6a33` | lemování, detaily, art deco ornamenty |
| Chrom | `#8d8f99` | trupy raket, Pumpík, zásobník (odlesky `#d8dbe3`, stín `#5d5f69`) |
| Rez | `#5a2a14` | špína a stékající rez |
| Kouř | `#3a3442` | opar, kouř |
| Neon (galaxín) | `#ff3d8b` | galaxín, neonové nápisy |
| Tyrkys | `#3f8f8a` | hledí Pumpíka, paprsek Bzučáka (světlý `#5fd0c7`) |

**Objekty:**
- **Rakety zákazníků:** štíhlé chromové trupy s vínovými zahnutými ploutvemi a pruhem, tmavé okénko s mosazným rámem, odřeniny, plamen trysky.
- **Pumpík:** elegantní chromový android s tyrkysovým hledím (žádná roztomilá kulatá očka), dlouhé paže, hadice.
- **Bzučák:** hmyzí stavební dron, vybledlé žluto-černé pruhy, síťované rotory, červené světýlko, jiskry svařování.
- **Pumpa u slotu:** štíhlý vínový art deco sloup s mosaznými žebry a skleněnou koulí, ve které svítí galaxín.
- **Zásobník:** zašlá chromová koule s mosaznými obručemi, průzory s růžovým galaxínem, stékající rez.
- **Zábavní systém:** autokino pro rakety. Široké plátno na nýtované ocelové konstrukci s art deco hřebenem a žárovkami, před ním promítací budka a vedle neonová šipka. Na plátně běží hypnotické psychedelické obrazce.
- **Paluba stanice:** tmavá ocel s panelovými spárami, nýty, rez, olejové skvrny, ošoupané mosazné lemování.
- **Vesmír:** téměř černý s vínovými a fialovými mlhovinami, tmavá planeta s rudým okrajem světla a prstencem.

**Efekty:** neonový nápis „galaxín“ s blikajícím písmenem, filmové zrno a ztmavené rohy obrazu, kouř od přistávajících raket, tetelení vzduchu nad tryskami, pulzující neon galaxínu.

**Světla** (2D světla Godotu, hotové):
- **Plamen motoru** raket i cisterny: plápolající plamen ze shaderu (bílé jádro, oranžová, konec do růžového neonu galaxínu), jiskry a oranžové světlo, které osvětlí loď i palubu pod ní. Délka plamene a síla světla rostou s rychlostí. Loď visící ve frontě má malý plamen, na plošině motor zhasne.
- **Značky přistávacích plošek** (jantarová světla v rozích) svítí, až je slot hotový. Volná ploška pomalu „dýchá“, když k ní letí loď, světla rychle obíhají dokola (navádění), a když loď stojí na plošce, svítí klidně a slaběji.
- **Zásobník** barví palubu kolem do růžova. Čím víc galaxínu v něm je, tím víc svítí.
- **Plátno autokina** svítí do okolí v barvě, která zrovna převládá v obraze, a promítací budka na něj hází kužel světla stejné barvy.
- **Bzučák** svítí tyrkysově na konci svařovacího paprsku.
- **Skleněné koule pump** jemně září růžovým neonem.
- **Reflektor nad palubou**: teplé světlo, uprostřed stanice nejsilnější, k okrajům slábne.
- **Viditelnost lodí:** trupy mají chladný obrys ze strany, odkud svítí vzdálená hvězda (vlevo nahoře). Černá závodní raketa je navíc zjasněná, jinak by v temném vesmíru zanikla.

**Rozhraní (HUD):** moderní herní HUD v noir paletě.
- **Písmo** Chakra Petch (Google Fonts, licence OFL v `assets/fonts/OFL.txt`): hranaté technické písmo se zkosenými rohy. Běžný text 13 px, nadpisy polotučně verzálkami s prostrkáním.
- **Panely** jsou tmavé poloprůhledné se zkoseným levým horním a pravým dolním rohem a tenkým mosazným lemem. Shader `ui/hud_panel.gdshader` přidává scanlines, filmové zrno, svítící mosazné rohy, světelný pruh přejíždějící šikmo přes obrazovku a při otevření panel „naskenuje“ shora dolů. Panel galaxínu má místo mosazi neonově růžový akcent.
- **Ikonky** (SVG kreslené ručně v `assets/ui/icons/`): zlatá mince místo „kr“, kapka galaxínu, raketa (obsloužené lodě), raketa s křížkem (odletěly bez placení), zásobník, cenovka, cisterna, graf zájmu, cíl (kosočtverec) a splněný cíl (zelený kosočtverec s fajfkou), šipky vylepšení a klíč stavby.
- **Výběr objektu:** vybraný objekt nemá rámeček, ale pulzující zlatý obrys podle svého tvaru a přejíždí přes něj světelný pruh. Vybraná prázdná parcela se rozsvítí měkkou září.
- **Rozložení:** vlevo nahoře lišta zdrojů (mince s kredity, obsloužené a ztracené lodě), pod ní panel galaxínu. Uprostřed nahoře tlačítko Menu. Vpravo cíle mise (každý s ukazatelem postupu) a pod nimi info panel vybraného objektu. Tlačítka akcí mají vlevo ikonku a popisek, vpravo cenu s mincí. Na co hráč nemá, je ztlumené a cena svítí červeně.
- **Oživení:** kredity „dojíždějí“ k nové hodnotě a mince při příjmu povyskočí (při výdaji se zmenší). Splněný cíl blikne a ikonka cvakne. Tlačítka při najetí myší září. Nápověda dole se ukáže jen při startu od mise 1, pomalu pulzuje a zmizí po prvním kliknutí na objekt.
- Řeč postav v bublinách dál říká „kr“, ikonky jsou jen v HUD a v plovoucích částkách nad loděmi.

**Grafika:** generuje se přes plugin SpriteCook (uživatel tam má účet, bezplatný tarif). Hotové obrázky a jejich ID jsou v `spritecook-assets.json`.
- Všechno je generované modelem GPT 2.5 Flare (medium, 1K, 8 kreditů za obrázek). Aby kredity vystačily, generují se 4 objekty v jednom obrázku (arch 2×2) a rozstříhají se lokálně nástrojem `tools/slice_sheet.gd`. Stylová předloha (reference) by stála 8 kreditů navíc, proto se jednotný styl drží stejným zadáním (téma, styl, paleta).
- **Hotové sprity** (40 kreditů):
  - Rakety zákazníků: `ships/rocket.png` (ve hře), `rocket_cargo.png`, `rocket_racer.png`, `rocket_workhorse.png`; cisterna `ships/tanker.png`.
  - Pumpík (původně `staff/pumpik.png`, teď nahrazený animacemi níže), Bzučák `construction/bzucak.png`.
  - Stanice: pumpa `station/pump.png`, zásobník `station/tank.png`, přistávací plocha `station/landing_pad.png`, autokino `entertainment/drive_in_screen.png` (prázdné plátno, film kreslí shader `fx/film_screen.gdshader`), holá konstrukce `entertainment/drive_in_frame.png`, promítací budka `entertainment/projection_booth.png` a neonová šipka `entertainment/neon_arrow.png` (16 kreditů, arch s referencí), opakovatelná textura paluby `station/deck.png`.
  - Staveniště pro rozestavěné budovy `construction/foundation.png`, planeta s prstencem do pozadí `space/planet.png`.
- **Ve hře** jsou zapojené všechny:
  - Lodě dostávají náhodně jednu ze čtyř raket. Cisterna má sprite, do kterého se jemně promítá barva dodavatele.
  - Pumpík je kulatý retro robot na kolech (červený a krémový smalt, skleněná kopule s elektronkami, knír, budík na břiše, láhev s hadicemi na zádech). Má osm snímků na animaci: jízda ve čtyřech směrech (`staff/pumpik_drive_down.png`, `_up`, `_left`, `_right`, čím rychlejší jízda, tím rychleji se točí kola) , tankování ve čtyřech směrech (`pumpik_pump.png` zepředu, `pumpik_pump_up.png`, `_left`, `_right`) a klid zepředu (`pumpik_idle.png`). Při tankování stojí čelem k lodi (u dvou lodí k první), při střelbě k pirátovi. Když jen stojí, je čelem k hráči. S levelem tankování se jen jemně zbarvuje. Bzučák se ve vzduchu kolébá.
  - Paluba má opakovanou texturu a mosazné lemování. Planeta je vpravo dole v pozadí hry i v menu.
  - Rozestavěné budovy: v 1. části staveniště. Čerpací slot pak má přistávací plochu, art deco pumpu vedle ní a nakonec potrubí k patě pumpy. Zábavní systém ve 2. části ukazuje holou ocelovou konstrukci, ve 3. tmavé plátno s promítací budkou a po zapojení elektřiny film s běžícími titulky, kužel projektoru a neonovou šipku.
- **Nové lodě, kořist a zábava** (16 kreditů, dva archy 2×2): nákladní loď `ships/freighter.png`, turistická `ships/tourist.png`, trosky `loot/wreckage.png`, truhla `loot/chest.png`, výherní automaty, hologram a světla scény v `entertainment/` (ventil potrubí z tohoto archu se nakonec nepoužívá).
- **Potrubí** (40 kreditů, pět archů 2×2): navazující dílek měděné trubky `station/pipe_tile.png`, kolena `pipe_elbow_*.png` a T kusy `pipe_tee_*.png` pro každý potřebný směr ramen (přípona = směry: l, r, u, d), příruba `pipe_flange.png`, podlahová spojka u čerpadla `pipe_floor.png`, průhledítko s galaxínem `pipe_sight.png` a tlakoměr `pipe_gauge.png`. Všechny díly jsou nasvícené zleva shora a nikdy se neotáčejí, aby stíny byly všude na stejné straně: rovné trubky se kreslí zleva doprava a zdola nahoru (lesk nahoře, u svislých vlevo) a každý směr kolena i T kusu má vlastní obrázek. Potrubí je rozvod, který vede jen vodorovně a svisle: ze zásobníku vede trubka nahoru do hlavní větve v uličce mezi horními a dolními parcelami, z ní k čerpadlům v horní řadě odbočují T kusy (na konci větve je koleno). Čerpadla na dolních parcelách mají vlastní trubku do boku zásobníku. U zásobníku jsou příruby, u čerpadel podlahové spojky, na levé větvi průhledítko a na pravé tlakoměr. Trubky leží nad spojkami a zasouvají se do jejich objímek tak, aby zakryly otvory a kolem trubky zůstal vidět mosazný kroužek. Puls galaxínu v trubkách je vypnutý.
- **Stavby a piráti** (24 kreditů, tři archy 2×2): obchod `shop/shop.png` a stánky `shop/food_cart.png`, `holonews.png`, `souvenirs.png`, `accessories.png`; řídící centrum `station/control_center.png` a anténa dispečinku `station/radar_dish.png`; obranná věž `defense/tower_base.png` a kanóny `defense/turret.png`, `turret_twin.png` (level 3); piráti `pirates/raider.png` a `pirates/gunship.png`.
- **Pumpík** (16 + 180 kreditů): nový vzhled podle hráčovy předlohy, nejdřív arch se čtyřmi pohledy na stejného robota (s předlohou jako referencí), pak devět animací po 20 kreditech (`frame-engine-v1.1`). Všechny jsou oříznuté jedním společným rámečkem, aby na sebe při přepínání seděly.
- **Bez kreditů v kódu:** HUD (ikonky, shader panelů), neonový nápis, vesmírné pozadí a mlhoviny, efekty (kouř, jiskry, blikání neonu) a animace pohybem.

## Systémy

### Lodě (zákazníci)
- **Druhy lodí:** běžné rakety mají 16 vzhledů a odemykají se s misemi, viz tabulka. K nim občas **nákladní loď** (10 %, 2× větší nádrž, objedná vždy plnou) a **turistická loď** (8 %, jen když stojí hotový obchod, o 30 % větší nádrž, v obchodě nakupuje ochotněji a utratí 20× víc, nad obchodem se ukáže „+… kr turisté“). Lodě se otáčejí do všech směrů, proto musí být kreslené přesně shora a souměrné podél osy.

| Raketa | Od mise | Trpělivost | Nádrž | Dýško | Povaha |
|---|---|---|---|---|---|
| 4 obyčejné rakety | 1 | 100 % | 100 % | běžné | |
| Žluté taxi | 1 | 70 % | 70 % | 1,5× častěji | spěchá, ale dá dýško |
| Romantická na rande | 2 | 160 % | 80 % | 2× častěji | zamilovaným čekání nevadí |
| Rodinná | 2 | 75 % | 130 % | běžné | s dětmi dlouho nevydrží |
| Kurýrní služba | 3 | 55 % | 60 % | 2× méně často | velký spěch |
| Dodávka | 3 | 100 % | 150 % | běžné | pracovní loď |
| Nomádská | 4 | 200 % | 120 % | nikdy | nikam nespěchá |
| Zmrzlinářská | 4 | 120 % | 80 % | 1,5× častěji | veselý obchodník |
| Odtahovka | 3 | 80 % | 130 % | běžné | spěchá za dalším zákazníkem |
| Pohřební raketa | 4 | 200 % | 100 % | 3× méně často | pasažér počká |
| Císařská hlídka | 5 | 60 % | 100 % | nikdy | čekat nebude, vždy plnou nádrž |
| Luxusní limuzína | 5 | 45 % | 120 % | 4× častěji a 2,5× vyšší | čekat nebude, vždy plnou nádrž |
| Redneck | 5 | 130 % | 130 % | 3× méně často | šetří každý kredit |
- **Strach z pirátů:** když pirát dorazí ke stanici a začne útočit, všechny lodě ve frontě i u čerpadel utečou („Piráti! Mizím!“). Natankovaný galaxín nezaplatí a počítají se mezi lodě, které odletěly bez placení. Dokud útok trvá, žádná nová loď nepřiletí.
- **Cisterny při útoku:** objednaná cisterna, která ještě neletí, se zruší a peníze se vrátí. Cisterna, která už je na obrazovce, odletí i uprostřed přečerpávání: co přečerpala, zůstane v zásobníku, za zbytek vrátí peníze. Dokud útok trvá, nejde objednat novou (ani dispečinkem).
- Loď chce buď plnou nádrž, nebo galaxín jen za určitou částku („Chci galaxínu za 100 kreditů“).
- S postupem levelu přilétá víc lodí a přibývají náročnější zákazníci.

### Parcely a stavění
- Stanice má **5 parcel**: tři nahoře (kam se nejvíc hodí čerpací sloty) a dvě dole. Na každou jde postavit čerpací slot, zábavní systém nebo obchod. Na krajích paluby vlevo a vpravo jsou navíc **2 menší místa pro obranné věže**. Uprostřed stojí pevně zásobník a Pumpíkovo stanoviště, vedle zásobníku jde přistavět řídící centrum.
- Prázdná parcela je vidět jako velmi jemný obrys a jde na ni kliknout, jen když na ní jde něco postavit (podle pravidel mise a limitů, i když na to hráč zrovna nemá). Jinak není vidět vůbec, takže v misi 1 žádné volné parcely nejsou. Po kliknutí ukáže, co jde postavit, kolik to stojí celkem, a tlačítka „Začít stavět…“ s cenou první části. Co v aktuální misi postavit nejde, se nezobrazí.
- **Placení po částech:** každá budova se staví ve čtyřech částech. Hráč zaplatí část, Bzučák ji postaví a pak rozestavěná budova čeká, až hráč zaplatí další. Nad ní je vidět „Další část: …“ a v jejím panelu tlačítko „Postavit: … (cena)“.
- **Vylepšení Bzučáka** (od mise 2, okamžitě): rychlejší let 230 px/s za 2 000 kr a 300 px/s za 4 000 kr (základ 170 px/s), rychlejší práce ×1,4 za 2 500 kr a ×1,8 za 5 000 kr (staví, vylepšuje, opravuje i sbírá kořist rychleji).
- **Stavební dron Bzučák** staví a vylepšuje budovy podle fronty zakázek. Doletí k budově a odpracuje zakázku. Nad budovou ukazuje, na které části se pracuje, a u dalších zakázek „Čeká na Bzučáka“. Když nemá práci, vrátí se ke stanovišti vedle zásobníku. Po kliknutí ukáže, na čem pracuje a kolik zakázek čeká.
- Při vylepšování budova dál funguje na původním levelu. Vylepšení Pumpíka je okamžité.

### Čerpací sloty
- Čerpadlo stojí na opačné straně plošiny než Pumpík. V horní řadě má Pumpík strany natočené k sobě, aby obsloužil dva sloty najednou. Dolní parcely mají čerpadlo u zásobníku, aby potrubí nevedlo pod plošinou.
- Kolik slotů smí stanice mít celkem (včetně těch ve stavbě), určuje mise.
- Části stavby (celkem 8 000 kr a 18 s): základová deska (1 500 kr, 4 s), přistávací plocha (2 500 kr, 5 s), čerpadlo (2 500 kr, 5 s), napojení na potrubí (1 500 kr, 4 s). Po poslední části se ze zásobníku natáhne potrubí.
- Upgrady zvyšují rychlost čerpadla a případně umožní obsluhovat větší lodě (zatím není).

### Personál
- **Androidi** (tankovači) obsluhují lodě.
- Android tankuje jednu loď. S vylepšením **Druhá hadice** (3 000 kr) zvládne **2 lodě najednou**: postaví se mezi dva sloty a ke každé lodi natáhne hadici, každou tankuje plnou rychlostí. Vylepšení se otevře, jakmile stojí druhý čerpací slot (jde postavit od Mise 2, cílem je v Misi 3), a Pumpík o něm řekne v rozhovoru. Při startu od Mise 3 ho už má.
- Pumpíkovi se zvlášť vylepšuje **tankování** a **jízda**. Do jakého levelu jde vylepšovat, určuje mise. Barva těla odpovídá levelu tankování.

| Level | Tankování | Cena | Barva |
|---|---|---|---|
| 1 | 8 j/s | výchozí | šedá |
| 2 | 12 j/s | 800 kr | tyrkysová |
| 3 | 18 j/s | 2 000 kr | zlatá |
| 4 | 24 j/s | 3 500 kr | fialová |
| 5 | 30 j/s | 5 500 kr | růžová |
| 6 | 36 j/s | 8 000 kr | bílomodrá |

| Level | Jízda | Cena |
|---|---|---|
| 1 | 80 px/s | výchozí |
| 2 | 110 px/s | 500 kr |
| 3 | 140 px/s | 1 000 kr |
| 4 | 170 px/s | 2 000 kr |
| 5 | 200 px/s | 3 500 kr |
- **Ochranka** bojuje s piráty, kteří se vylodili na stanici.
- Personál se nabírá a trénuje.

### Zábavní systém
- Autokino pro rakety na stanici. Na plátně běží film a ve spodní části titulky s reklamami a pořady (texty jsou v `dialogue/lines.gd`).
- Lodím ve frontě pomaleji ubývá trpělivost a pobavení zákazníci častěji nechávají dýško. Lodě ve frontě občas komentují, co běží na plátně.
- Části stavby (celkem 4 000 kr a 15 s): základní deska (600 kr, 3 s), konstrukce plátna (800 kr, 4 s), instalace plátna (1 800 kr, 5 s), napojení elektřiny (800 kr, 3 s). Bonusy platí až po zapojení elektřiny.
- Level 4 přidá vedle plátna **holoprojekci** (tančící hologram), level 5 **neonovou show** (světla nad plátnem).
- **Výherní automaty** (6 000 kr, instalace 10 s) jdou dokoupit zvlášť: každé 4 s si každá loď ve frontě s šancí 25 % zahraje a stanice vydělá 15–60 kr („+… kr automaty“).

| Level | Cena | Doba vylepšení | Úbytek trpělivosti | Šance na dýško |
|---|---|---|---|---|
| 1 | 4 000 kr (stavba po částech) | 15 s (stavba) | −25 % | 12 % |
| 2 | 3 000 kr | 8 s | −40 % | 14 % |
| 3 | 5 000 kr | 12 s | −55 % | 16 % |
| 4 (holoprojekce) | 8 000 kr | 14 s | −65 % | 18 % |
| 5 (neonová show) | 12 000 kr | 16 s | −75 % | 20 % |

### Ekonomika galaxínu (od mise 3)
V misích 1 a 2 je galaxínu neomezeně a stojí pevně 6 kr/j. S misí 3 se zapne ekonomika galaxínu a hráč dostane do zásobníku první várku 300 j zdarma. Od té chvíle platí:

- **Zásobník** uprostřed stanice má omezenou kapacitu a ukazuje hladinu (pod 20 % bliká červeně). Pumpík z něj čerpá do lodí. Když dojde, lodě u slotů čekají a ztrácejí trpělivost.

| Level zásobníku | Kapacita | Cena rozšíření | Doba rozšíření (dron) |
|---|---|---|---|
| 1 | 500 j | výchozí | – |
| 2 | 800 j | 1 500 kr | 10 s |
| 3 | 1 200 j | 3 000 kr | 14 s |
| 4 | 1 800 j | 5 000 kr | 18 s |

- **Prodejní cena** se nastavuje v rozmezí 3–12 kr/j (běžná je 6). Lodě přilétají `(6 / cena)^1,5`× častěji a trpělivost jim ubývá `cena / 6`× rychleji. Při 3 kr tedy přilétá zhruba 2,8× víc lodí, při 12 kr asi třetina. Nejvíc vydělá něco mezi (při testu se zásobníkem doplňovaným zadarmo: 3 kr → 87 lodí / 12 700 kr, 6 kr → 48 lodí / 14 400 kr, 12 kr → 19 lodí / 10 700 kr za 3 minuty).
- **Panel galaxínu** (cena, dodavatel, objednávky) se ukáže jen po kliknutí na zásobník.
- **Dodávky** se objednávají ručně v panelu Galaxín. Cisterna se platí předem (velikost cisterny, nejvýš volné místo v zásobníku a nejvýš tolik, na kolik má hráč kredity, aby se hra nezasekla, když dojde galaxín i peníze), po čase přiletí, přečerpá galaxín a za to, co nedovezla nebo co se nevešlo, vrátí peníze. Pak se natočí náhodným směrem pryč od stanice a odletí přídí napřed. Najednou může být objednaná jen jedna cisterna.

| Dodavatel | Cena | Cisterna | Dodání | Zpoždění | Méně galaxínu | Kvalita |
|---|---|---|---|---|---|---|
| Sizel Varn | 2 kr/j | 400 j | 12 s | 35 % (+10–20 s) | 30 % (doveze 30–60 %) | nekvalitní |
| Galaxis Distribuce | 3 kr/j | 400 j | 10 s | 20 % (+6–12 s) | 15 % (poloprázdná) | dobrá |
| Orion Premium | 4 kr/j | 600 j | 8 s | nikdy | nikdy | prémiová |

- **Pokuty:** nekvalitní galaxín se v zásobníku míchá s ostatním. Loď, která ho natankovala, s šancí až 20 % (podle podílu nekvalitního galaxínu) nahlásí stanici a ta zaplatí pokutu **400 kr**. Taková loď nedá dýško. Kredity můžou spadnout do minusu.

### Obchod (od mise 4)
- Staví se na běžnou parcelu ve 4 částech (celkem 3 000 kr): základová deska (500 kr, 3 s), kiosek (1 200 kr, 5 s), vybavení a pult (800 kr, 4 s), neonová reklama (500 kr, 3 s).
- Posádka každé lodi, která přistane, si nakoupí: každý druh zboží si koupí s jeho šancí. Tržba se ukáže nad obchodem („+40 kr obchod“).
- Lodím ve frontě pomaleji ubývá trpělivost (násobí se se zábavním systémem).
- Hned po postavení prodává nápoje. Další druhy zboží přidává hráč, instaluje je Bzučák a každý má vedle obchodu vlastní stánek:

| Zboží | Cena | Instalace | Šance na nákup | Útrata | Trpělivost ve frontě |
|---|---|---|---|---|---|
| Nápoje (základ) | – | – | 40 % | 10–25 kr | −5 % |
| Párky v rohlíku | 2 000 kr | 6 s | 45 % | 20–45 kr | −6 % |
| Holonoviny | 2 500 kr | 6 s | 50 % | 10–25 kr | −8 % |
| Suvenýry | 3 000 kr | 8 s | 30 % | 40–90 kr | −4 % |
| Doplňky | 4 000 kr | 8 s | 25 % | 60–140 kr | −4 % |

### Řídící centrum (od mise 4)
- Malá serverovna, kterou jde přistavět k zásobníku na **levelu 3**. Nabídne ji zásobník. Staví se ve 3 částech (celkem 4 000 kr): základy (1 000 kr, 4 s), serverovna (2 000 kr, 6 s), napojení na zásobník (1 000 kr, 4 s).
- Vylepšení instaluje Bzučák:

| Vylepšení | Level 1 | Level 2 | Účinek (L1 / L2) |
|---|---|---|---|
| Spolehlivé dodávky | 2 000 kr, 6 s | 4 000 kr, 8 s | zpoždění a poloprázdné cisterny o 50 % méně často / nikdy |
| Rychlé doručení | 2 000 kr, 6 s | 4 000 kr, 8 s | doba dodání (i zpoždění) ×0,7 / ×0,45 |
| Větší cisterny | 2 500 kr, 6 s | 5 000 kr, 8 s | cisterna ×1,5 / ×2 |
| Rychlé přečerpávání | 1 500 kr, 5 s | 3 000 kr, 7 s | přečerpávání ×1,6 / ×2,5 |
| Filtry galaxínu | 2 000 kr, 6 s | 3 500 kr, 8 s | vyčistí 40 % / 70 % nekvalitního galaxínu z dodávky; level 3 (5 000 kr, 10 s) vyčistí všechno, takže levný Sizel je bez pokut. Level 1 jde koupit od Mise 4, level 2 od Mise 6 a level 3 až se schématem od Sizela v Misi 8 (`Mission.max_filter_level`) |
| Automatický dispečink | 6 000 kr, 10 s | – | objedná cisternu u vybraného dodavatele sám, když v zásobníku zbývá méně než 40 % (a hráč na ni má) |

### Obrana (od mise 5)
- **Obranná věž** s laserovým kanónem stojí na místě pro věž na kraji paluby (dvě místa). Staví se ve 4 částech (celkem 6 000 kr): základna (1 500 kr, 4 s), věž (1 500 kr, 4 s), laserový kanón (2 000 kr, 5 s), napájení (1 000 kr, 3 s).
- Sama hledá nejbližšího piráta v dosahu, natočí kanón a střílí zlatými laserovými střelami. Když je věž vybraná, ukáže se jemný okruh, kam až dostřelí.

| Level | Cena vylepšení | Poškození | Střelba | Dosah |
|---|---|---|---|---|
| 1 | (stavba) | 1 | každých 0,9 s | 520 px |
| 2 | 4 000 kr, 8 s | 2 | každých 0,75 s | 620 px |
| 3 | 7 000 kr, 10 s | 2, dvojitá hlaveň | každých 0,45 s | 720 px |

- **Pumpík jako ochranka:** postaví se útočícímu pirátovi i tehdy, když stojí věže (ty dostřelí jen na svůj dosah), a střílí po něm zlatými střelami z tankovací pistole (1 poškození za 0,9 s). Během boje netankuje.
- **Odolnost Pumpíka:** piráti střílejí přednostně po něm (každých 2,5 s, 1 zásah). Základní odolnost jsou 3 zásahy, nad Pumpíkem je při poškození vidět ukazatel. Když odolnost klesne na nulu, je **rozbitý**: netankuje, nebrání se a lodě na plošinách čekají. Teprve pak piráti střílejí po zásobníku a kradou kredity.
- **Oprava:** rozbitého Pumpíka opraví Bzučák (10 s při základní rychlosti práce) a dostane plnou odolnost. Částečně poškozeného opraví, až na něj 4 s nikdo nestřílí: Pumpík mezitím pracuje dál a zastaví se, až když k němu Bzučák doletí (nad ním „Pumpík · v opravě“). Rozbitý Pumpík („Pumpík · rozbitý“) jen stojí a čeká. Po opravě se sám vrátí do práce a vezme si i lodě, které mezitím přistály. Oprava má v Bzučákově frontě **přednost** před vším ostatním, rozdělaná stavba si drží postup a počká.
- **Vylepšení Pumpíka do boje** (od mise 5): **štíty** level 1 za 3 000 kr (odolnost 5), level 2 za 6 000 kr (odolnost 7); **nanoboti** level 1 za 4 000 kr (opraví 1 bod odolnosti za 6 s), level 2 za 7 000 kr (za 3 s). Nanoboti léčí jen částečné poškození a Bzučáka pak Pumpík nevolá. Rozbitého Pumpíka (0 odolnosti) nanoboti neopraví, toho opraví vždy Bzučák.

### Piráti (od mise 5)
- Přilétají každých 40–70 s (první 20 s po začátku mise). Zhruba po 3 minutách občas přiletí dva naráz, po 4 minutách i těžké dělové lodě a po 7 minutách občas celá banda 3–4 lodí (šance 30 %).
- Pirát si vybere jedno ze 6 míst kolem stanice a přiletí k němu z bližšího okraje obrazovky. Každých 2,5 s vystřelí: dokud je Pumpík v provozu, po Pumpíkovi, a když je rozbitý, po zásobníku a **ukradne 3–8 % kreditů z pokladny**. Po 5 krádežích odletí. Pirátské střely jsou červené, nad lodí je ukazatel životů.
- **Střelba:** všichni střílejí krátkými světelnými střelami (ne spojitým paprskem). Střela blikne u hlavně, cestou svítí na palubu a při dopadu se rozstříkne v jiskry. Účinek (poškození, krádež) přijde až při dopadu.
- Během útoku bliká v HUD „Piráti útočí!“ a piráti mluví v bublinách.

| Druh | Výdrž (zásahů po 1) |
|---|---|
| Nájezdník | 4 |
| Dělová loď | 15 |

- **Kořist:** ze sestřeleného nájezdníka s šancí 60 % (z dělové lodi vždy) vypadne kořist a zůstane se vznášet na místě. Bzučák pro ni doletí a za 2 s ji sebere (zařadí se do jeho fronty zakázek).
  - **Trosky** vynesou 150–400 kr (z dělové lodi 400–900 kr).
  - **Truhla s artefaktem** (šance 20 %, z dělové lodi 45 %). Bez skladiště se artefakt hned prodá za svou cenu. Se skladištěm se uloží a začne působit. Co hráč ve skladišti má, z pirátů znovu nevypadne. Když je tam všechno, vypadnou místo truhly trosky.

| Artefakt | Cena | Ve skladišti |
|---|---|---|
| Rezavý pirátský kompas | 1 200 kr | sběratelská cennost |
| Láhev staré galaxínové whisky | 1 800 kr | sběratelská cennost |
| Zlatá lebka | 2 500 kr | sběratelská cennost |
| Krystal čistého galaxínu | 1 500 kr | zásobník pojme o 400 j víc |
| Pirátská vysílačka | 3 000 kr | piráti útočí o 20 % méně často |
| Mapa pirátských skrýší | 3 000 kr | trosky vynesou o 50 % víc |

- Původní nápad na pozdější fázi: piráti vystoupí z lodi a útočí na stanici pěšky.

### Cíl a prohra
- **Výhra:** splnění cíle levelu, například vydělat X kreditů.
- **Prohra:** hra nemá game over, hráč se ale nesmí zaseknout (viz Vesmírný vetešník).

### Skladiště (od mise 5)
- Přistavuje se k hotovému obchodu akcí v jeho nabídce, podobně jako řídící centrum k zásobníku. Staví se ve 3 částech (celkem 3 000 kr): základy (800 kr, 3 s), ocelová konstrukce (1 200 kr, 4 s), stěny a vrata (1 000 kr, 4 s). V Misi Z už stojí.
- Hotové skladiště je inventář s **8 sloty** (6 artefaktů z pirátů a místo pro artefakty z příběhu): kliknutí na něj zastaví hru a ukáže, co v něm je. Prázdné sloty jsou prázdné. Po kliknutí na artefakt se ukáže popis, účinek a tlačítko **Prodat** za jeho plnou cenu.
- Účinek artefaktu platí, jen dokud je ve skladišti. Po prodeji skončí a artefakt může z pirátů vypadnout znovu.

### Vesmírný vetešník
- Přiletí, když je zásobník prázdný, žádná cisterna není objednaná ani na cestě a hráč nemá ani na 50 j od nejlevnějšího dodavatele (100 kr). Menší dávku vypije jedna loď a stanice se z ní nevzpamatuje. Musí to trvat 4 s, protože kredity ještě může přinést kořist, obchod nebo automaty, a počká i na lodě u čerpadel, které ještě zaplatí za natankovaný galaxín. Během útoku pirátů nepřiletí.
- Hra se zastaví a vetešník nabídne **3 náhodná vylepšení, která hráč má, za 50 % nákupní ceny**. Prodané vylepšení hráč ztratí (o jeden level zpět) a může si ho později znovu koupit. Prodat jde levely Pumpíka, štíty, nanoboty, Bzučáka, zásobníku, zábavního systému, věží, zboží obchodu, výherní automaty a vylepšení řídícího centra. Budovy samotné ani to, na čem Bzučák právě pracuje, prodat nejde.
- Hráč může odmítnout („Zatím ne“), vetešník se pak vrátí za 30 s.
- Kdo už nemá co prodat, dostane almužnu 150 kr, aby se nezasekl.

## Příběh a rozhovory

**Sizel Varn** (přijde v Misi 8): ještěří dohazovač a překupník z černého trhu v zažloutlém kabátě, s kalkulačkou v ruce. Od začátku ekonomiky je to nejlevnější a nejhorší dodavatel galaxínu. Hráče oslovuje „šéfe“.

**Zora Zender** (přijde v Misi 6): cirkusová artistka s rychlou a obratnou raketou s cirkusovými motivy. Jako malá s ní matka utekla a našla azyl v cirkusu, kde vyrostla. Ve skutečnosti je dcerou galaktického císaře a právoplatnou dědičkou vesmírného trůnu. Hráč se to dozvídá postupně, nesmí to vědět hned. Má stejné čtyři emoce jako Pumpík (`zora_*.png`).

Připravené lodě pro příběh, zatím se ve hře nepoužívají a do běžného provozu nepatří (`assets/sprites/ships/`): Zořina raketa `rocket_zora`, cirkusová maringotka `rocket_circus_wagon`, loď principála `rocket_ringmaster`, císařský kurýr `rocket_imperial_courier`, císařský křižník `rocket_imperial_cruiser` a pirátská vlajková loď `rocket_pirate_flagship`. Křižník a vlajková loď jsou velké jako nákladní loď.

Postavy mluví v dialogovém okně ve spodní části obrazovky: vlevo detailní obličej s emocí, vedle jméno a text, který se postupně vypisuje. Dokud je okno vidět, hra stojí. Tlačítko OK (nebo Enter a mezerník) nejdřív dopíše rozepsaný text, pak přejde na další repliku. Později půjde přidat i tlačítka s výběrem možností.

- Zadání každé mise říká **Pumpík** v rozhovoru místo modálního okna. Cíle jsou vidět vpravo nahoře. Okno se shrnutím po splnění mise zůstává.
- Pumpík má čtyři emoce: klidný, nadšený, ustaraný a naštvaný (`neutral`, `happy`, `worried`, `angry`).
- Kobaltový strážce má čtyři emoce: přísný, pohrdavý, vyděšený a naštvaný (`neutral`, `scornful`, `scared`, `angry`).
- Sizel Varn má čtyři emoce: klidný, potěšený, vyděšený a naštvaný (`neutral`, `happy`, `worried`, `angry`).
- Rozhovory jsou v `dialogue/story.gd`.

## Zvuk

Hudba zatím není, přijde později. Zvukové efekty jsou syntéza kódem (`tools/generate_sfx.gd`), retro raypunk: lasery jako theremin, kovové údery, cinkání mincí, klaxon poplachu. Soubory jsou v `assets/sounds/`.

- **Boj:** zlaté a červené střely, dopad, výbuch (dělová loď hlouběji), poplach na začátku útoku, zásah Pumpíka, rozbití, oprava, krádež.
- **Provoz:** platba (dýško cinkne výš, prodej v obchodě výš a tišeji), pokuta, přistání a odlet, naštvaná loď, dokování cisterny, hotová část stavby, dokončená budova, kořist, artefakt, výhra na automatech.
- **Rozhraní:** kliknutí na tlačítko, výběr objektu, nákup, splněná mise.
- **Smyčky:** tankování (jen glo glo), svařování Bzučáka (jen elektrická zapraskání), přečerpávání z cisterny (výrazné hluboké glo glo a tiché tepání čerpadla). Při pauze ztichnou. Stanice žádný trvalý podkres nemá.
- **Stejné zvuky se nekupí** (nejmenší rozestup mezi přehráními) a mají mírně náhodnou výšku tónu.
- **Ovládání:** ikonka reproduktoru v HUD a v menu ztlumí zvuky, posuvník v pauze mění hlasitost. Hra si nastavení pamatuje.
- **Centrum zvuků** v Pumpíkově zápisníku ukáže všechny zvuky po skupinách. Každý jde pustit kliknutím nebo je projít tlačítky Předchozí a Další, hrají stejně hlasitě jako ve hře, ale bez náhodné výšky. Smyčku zastaví druhé kliknutí.

## Mise

Mise jsou zdroje `missions/mission_*.tres` (dají se upravovat v inspektoru Godotu) a jejich pořadí určuje `missions/missions.gd`. Každá mise má **pravidla** (co jde postavit, kolik slotů, maximální levely Pumpíka, ekonomika galaxínu, četnost lodí), **cíle** a **startovní stav**, který se použije jen při startu rovnou od ní z menu.

## Mise 1: Pumpík se učí tankovat

Úvodní mise, ve které se hráč naučí obsluhu lodí a vylepšování personálu.

**Startovní stav:** 1 čerpací slot (horní prostřední parcela), Pumpík s tankováním i jízdou na levelu 1, 0 kr.

**Cíle** (musí platit oba zároveň):
- Mít na účtu **1 000 kr**. Počítá se zůstatek, peníze utracené za vylepšení se tedy do cíle nezapočítávají.
- Vylepšit Pumpíkovi **tankování na level 3**.

**Piráti:** zatím nejsou, přijdou až s krokem 5 plánu.

**Pumpík** jde v téhle misi vylepšit nejvýš na level 3 (tankování i jízdu). Nic dalšího se zatím stavět nedá.

### Lodě
- Přilétají každé 3–7 s, v průměru tedy každých 5 s.
- Když je slot obsazený, čekají ve frontě (max. 4 lodě). Každá loď zůstává na místě, kam se ve frontě zařadila, fronta se nepřeskládává. Na uvolněný slot letí ta, která čeká nejdéle, a její místo pak zabere další přilétající loď. Po 20 s čekání odletí bez placení.
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
| Ve frontě po polovině trpělivosti | loď | 60 % (se zábavním systémem napůl stížnost, napůl komentář k filmu) |
| Odlet bez placení (červená bublina) | loď | vždy |
| Odlet po zaplacení: dýško | loď, Pumpík poděkuje | 10 % |
| Odlet po zaplacení: poděkování (když nebylo dýško) | loď | 50 % |
| Vylepšení | Pumpík | vždy |
| Došel galaxín v zásobníku | Pumpík | vždy (jednou, dokud se nedoplní) |
| Pokuta za nekvalitní galaxín (červená bublina) | loď | při pokutě |
| Cisterna dorazila (včas / pozdě / s menší dodávkou) | řidič cisterny | vždy |

### Tempo
- „Robotický hráč“ z `tools/balance_sim.gd`, který kupuje hned, jak na to má, misi splnil za 2:31 (jeden běh, vyvažováno nebylo).

## Mise 2: Zábava pro zákazníky

**Startovní stav** (jen při startu od mise 2): 1 čerpací slot, Pumpík s tankováním i jízdou na levelu 3, 2 000 kr. Při plynulé hře pokračuje hráč s tím, co měl na konci mise 1.

**Cíle** (musí platit oba zároveň):
- Mít na účtu **2 000 kr**.
- Postavit **zábavní systém**. Vylepšovat ho není nutné.

**Co jde dělat:** postavit zábavní systém a druhý **čerpací slot za 8 000 kr** (na libovolné prázdné parcele), vylepšovat Pumpíka až do levelu 6. Slot není nutný ke splnění cíle. Jakmile stojí, Pumpík se ozve v rozhovoru a otevře se mu vylepšení **Druhá hadice** (3 000 kr), se kterým tankuje dvě lodě najednou.

**Lodě** přilétají častěji než v misi 1, každé 2–5 s. Jeden slot je nestíhá, takže se vyplatí zábavní systém i druhý slot. Ostatní ekonomika je stejná jako v misi 1.

### Tempo
- Robotický hráč misi splnil za 5:42 při plynulé hře z mise 1 a za 5:15 při startu rovnou od mise 2 (jednotlivé běhy, vyvažováno nebylo).

## Mise 3: Vlastní galaxín

Představuje ekonomiku galaxínu. Cíle jsou zatím provizorní, uprav je podle sebe.

**Startovní stav** (jen při startu od mise 3): 2 čerpací sloty (třetí nejde postavit), Pumpík s tankováním na levelu 6 a jízdou na levelu 5, zábavní systém na levelu 3, 3 000 kr, zásobník na levelu 1. Vždy: 300 j galaxínu zdarma, prodejní cena 6 kr/j, vybraný dodavatel Galaxis.

**Cíle** (musí platit všechny zároveň):
- Mít na účtu **4 000 kr**.
- Vylepšit zásobník na **level 2**.
- Mít **2 hotové čerpací sloty**.

**Co jde dělat:** rozšiřovat zásobník a všechno, co zbylo z mise 2 (Pumpík, zábavní systém, druhý slot).

**Lodě** přilétají každé 2–5 s (při běžné ceně), dál podle nastavené ceny.

### Tempo
- Cíl byl původně 15 000 kr, snížen na 6 000 kr. S původním cílem robotický hráč (výchozí cena, Galaxis, objednává při zásobníku pod polovinou) misi splnil za 16:26 při plynulé hře (cestou utrácel i za vylepšení Pumpíka) a za 9:10 při startu rovnou od mise 3 (jednotlivé běhy, vyvažováno nebylo).

## Mise 4: Obchod a logistika

Klidná mise bez pirátů, představuje obchod a řídící centrum.

**Startovní stav** (jen při startu od mise 4): 2 čerpací sloty (třetí jde postavit), Pumpík s tankováním na levelu 6 a jízdou na levelu 5, zábavní systém na levelu 3, zásobník na levelu 3, 6 000 kr.

**Cíle:**
- Postavit **obchod**.
- Prodávat v něm **1 druh zboží** navíc.
- Řídící centrum s **automatickým dispečinkem**.

## Mise 5: Piráti

Na stanici začnou útočit piráti, jde stavět obranné věže.

**Startovní stav** (jen při startu od mise 5): 3 čerpací sloty, Pumpík s tankováním na levelu 6 a jízdou na levelu 5, zábavní systém na levelu 3, zásobník na levelu 3, obchod se 2 druhy zboží navíc, řídící centrum s dispečinkem, 8 000 kr.

**Cíle:**
- Postavit **skladiště** u obchodu.
- Sestřelit **10 pirátů** (počítá se věž i Pumpík).
- Postavit **obrannou věž**.

## Mise 6: Nečekaná zákaznice

První příběhová mise, přichází Zora Zender.

**Startovní stav** (jen při startu od mise 6): jako v Misi 5, ale zábavní systém na levelu 2, obranná věž na levelu 1 a skladiště.

**Cíle:**
- Mít na účtu **6 000 kr**.
- Zábavní systém na **levelu 3**.
- **2 hotové obranné věže**.
- Mise skončí až po scéně se Zorou (v cílech se neukazuje).

**Scéna se Zorou** (`game/zora_scene.gd`):
1. Asi 45 s po začátku mise přiletí Zora a přistane (jen jednou). Má nekonečnou trpělivost, před piráty neuteče a v dialogu poprosí o plnou nádrž.
2. Pumpík ji normálně obslouží.
3. Pumpík v dialogu řekne cenu, Zora odpoví, že musí letět, a Pumpík se naštve. Začne pomalu odlétat (45 px/s).
4. Pumpík si toho všimne a vystřelí po ní.
5. Raketa se jen otřese a velmi rychle zmizí, ale vypadne z ní truhla.
6. Bzučák truhlu sebere a Pumpík v dialogu popíše **Medailon s císařským orlem**: orel s korunou, slunce a půlměsíc. Uloží se do skladiště a nejde prodat.

## Mise 7: Plné ruce práce

Bzučák nestíhá a dodavatel mešká. Asi 45 s po začátku mise přistane císařská hlídka a Kobaltový strážce se ptá na Zoru. O medailonu nemluví a Pumpík o něm taky nic neřekne. Hráč si vybere, jestli ji prozradí, nebo zatají. Výběr zatím mění jen repliky a pamatuje si ho `Game.zora_reported` pro další příběh. Mise skončí až po téhle scéně.

**Startovní stav** (jen při startu od mise 7): jako v Misi 6, ale zábavní systém na levelu 3 a 2 věže na levelu 1. Ve skladišti je medailon od Zory a zůstává tam i v dalších misích, dokud ho nepoužije pozdější příběh.

**Cíle:**
- Jedna obranná věž na **levelu 2**.
- Spolehlivé dodávky na **levelu 2** (maximum).
- Rychlost letu i práce Bzučáka na **levelu 2**.

## Mise 8: Embargo

Císař uvalí embargo na celou oblast a snaží se zastavit pohyb osob. Oficiální dodavatelé nefungují, objednávat jde jen od překupníka Sizela Varna z černého trhu za 6 kr/j. Posádky se bojí létat a čerpat, takže přilétá o 50 % lodí méně. Strach trvá po celou dobu embarga.

**Startovní stav** (jen při startu od mise 8): jako v Misi 7, ale obě věže na levelu 2.

**Cíle:**
- Filtry galaxínu na **levelu 3** (maximum). Tenhle level jde koupit až se schématem od Sizela.

**Příběh Sizela** (`game/sizel_scene.gd`, počítají se dodávky, které dorazily k zásobníku):
1. První dodávka: Sizel se představí a Pumpík se zlobí na cenu.
2. Druhá dodávka: Sizel varuje, že jsou mu hlídky v patách.
3. Třetí cisterna přiletí poškozená a hořící. Pumpík ji okamžitě pošle na plošinu. Volnou, a když žádná není, loď na první plošině zaplatí, co natankovala, a uhne.
4. Bzučák cisternu opraví. Má to přednost před ostatní prací a piráti ji neodeženou.
5. Sizel je náš přítel: zlevní na 4 kr/j a dá nám schéma na filtr level 3. Cisterna pak dokončí dodávku za původní cenu 6 kr/j.
6. Hráč si filtr level 3 nainstaluje za 5 000 kr a tím misi dokončí.

Embargo je pravidlo mise (`Mission.embargo`). Platí i ve volné hře po misi a vypne ho až další mise bez tohoto pravidla. Další mise musí mít `max_filter_level = 3`, jinak by hráč schéma ztratil. Volba z Mise 7 (prozradit, nebo zatajit Zoru) zatím průběh Mise 8 nemění.

## Mise 9: Provizorní motel

Embargo trvá a Sizel přijde s nápadem: lidé uvízli a někde spát musejí, tak ať stanice postaví provizorní motel. Plány dodá za provizi, to je ale jen řeč v rozhovoru, ceny staveb to nemění. Pumpík si stěžuje, kolik práce to bude.

**Startovní stav** (jen při startu od mise 9): jako v Misi 8, ale filtry na levelu 3 a Sizel je přítel (galaxín za 4 kr/j).

**Cíle:**
- **Rozšířit plošinu** (3 části, 8 000 kr). Paluba se rozšíří doprava a přibudou na ní 2 nové parcely.
- **Postavit motel** (4 části, 6 000 kr) na běžné parcele.
- **Postavit parkoviště** (3 části, 4 000 kr) pod plošinou pro 4 lodě.

**Rozložení:** kamera se nemění, všechno se vejde do základního výhledu. Rozšíření je vpravo, aby ho nezakrýval panel galaxínu. Parkoviště přiléhá k palubě zespodu, vpravo od kotviště cisterny.

**Hosté motelu:** když stojí motel i parkoviště a je volné stání, loď po zaplacení s šancí 35 % přeletí na parkoviště. Zůstane 25 až 45 s a každých 5 s pošle platbu: běžně 20 kr, rodinná raketa 40 kr a luxusní limuzína 50 kr. Turistická loď do motelu nejezdí. Před piráty hosté neutíkají. Šance a délka pobytu jsou odhad, zatím nevyvážené.

Hotové parkoviště je s palubou jeden kus (`Station._update_deck`), stejně jako její rozšíření.

## Mise Z: Volná hra

Jde na ni jen z menu, na misi 5 nenavazuje. Pravidla jsou jako v misi 5 (včetně pirátů), ale nejsou tu žádné cíle a na začátku je všechno hotové: 3 čerpací sloty, obchod s veškerým zbožím, zábavní systém na levelu 5 s výherními automaty, obě věže na levelu 3, řídící centrum se všemi vylepšeními, zásobník na levelu 4 (plný), Pumpík i Bzučák na maximu. Start s 10 000 kr. Artefakty se sbírají až během hry.

## Otevřené otázky
- Kradou piráti zatím jen kredity. Mají později krást i galaxín, ničit sloty nebo unášet personál?
- Jak se staví: na pevné pozice, nebo volně na mřížku?
- Bude stanice mít reputaci, která ovlivní počet zákazníků?
- Kolik bude misí a čím se budou lišit? Bude hra mít víc stanic?

## Plán vývoje

Do kroku 8 se používají jednoduché barevné tvary, grafika přijde na řadu, až bude hra hratelná.

1. ~~Kostra projektu~~ ✅
2. ~~**Stanice a lodě:** stanice se sloty, lodě přilétají, kotví, natankují se automaticky a odletí. Hned potom první test web exportu.~~ ✅
3. ~~**Personál:** tankovač chodí k lodím a tankuje je, lodě čekají ve frontě a mají omezenou trpělivost.~~ ✅ (mise 1)
4. **Ekonomika a HUD:** kredity, cíle misí, klikání na objekty s info panelem, stavění na parcelách stavebním dronem a kontinuální mise jsou hotové. Zbývá nábor dalších zaměstnanců.
5. **Piráti:** pirátské lodě kradou kredity, brání je obranné věže a Pumpík (mise 5) ✅. Zbývá výsadek pirátů pěšky a podmínka prohry.
6. **Upgrady:** personál, sloty, obrana.
7. **Piráti, útok lodí:** pirátské lodě útočí na obranné systémy.
8. **Vyladění:** vyvážení na 20+ minut hraní, grafika, zvuky, export na itch.io.
