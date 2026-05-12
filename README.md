# <div align="center"> CRM Analytik - Case Study

<img width="1983" height="793" alt="39ea498b-ccd7-44f4-9c09-c29d4af108af" src="https://github.com/user-attachments/assets/a8c790fe-8e0c-438d-99ec-207412e9a47c" />

<div align="left"> 

### Tento projekt je vypracovanou Case Study v rámci přijímacího řízení na pozici CRM Analytik, jejíž cílem je vytvoření kohortní analýzy pomocí SQL ze zdrojových dat v .xlsx a vizualizace výsledků v Looker Studiu. Jedná se o data e-shopu ze 3 různých zemí - Česka, Slovenska a Maďarska.  

## Použité programy/technologie:
- SQL
- MariaDB
- DBeaver
- Looker Studio
- ChatGPT


## Výstupy

Detailně popsaný postup naleznete [zde](https://github.com/AndreaMaratova/CRM-Analytik-Case-Study/blob/main/postup.md).

Kompletní SQL skript naleznete [zde](https://github.com/AndreaMaratova/CRM-Analytik-Case-Study/blob/main/skript.sql).

SQL skript ke kohortní analýze naleznete [zde](https://github.com/AndreaMaratova/CRM-Analytik-Case-Study/blob/main/skript_kohortni_analyza.sql). 

Export výsledné kohortní retenční tabulky naleznete [zde](https://github.com/AndreaMaratova/CRM-Analytik-Case-Study/blob/main/kohorni_retencni_tabulka.csv). Soubor neotvírejte v Excelu - přepíše se formátování. 

Vizualizaci dat přes Looker Studio naleznete [zde](https://datastudio.google.com/s/iEPu3P8QDuc). Dashboard obsahuje retenční tabulku s heatmapou, filtry podle země a období kohorty a trendový graf vývoje retence M3/M6/M9.

Zdrojová data nejsou z důvodu bezpečnosti součástí repozitáře. 

## Shrnutí práce a odpovězení na zadané otázky


## Zodpovězení zadaných otázek a shrnutí práce

1) Jaký datový zdroj bys napojil/a a jak bys data připravil/a pro Looker Studio
- Záleželo by, kde by zdrojová data byla. Já jsem pro tento úkol šla cestou "nejmenšího odporu" a jelikož jde o jednorázové řešení, nahrála jsem .csv do Google Sheets, nad kterými jsem pak udělala vizualizaci v Looker Studiu. V produkčním prostředí bych preferovala přímé napojení Looker Studia na databázové view nebo datový sklad, aby byl report automaticky aktualizovaný a nebylo nutné pracovat s ručním exportem. Jelikož moje databáze běží lokálně, bylo by napojení na Looker Studio náročnější.
2) Jaké typy vizualizací bys zvolil/a a proč
- Heatmapu - na první dobrou z ní člověk vyčte, co potřebuje
- Spojnicový graf - pro zobrazení dat v čase
- Rychlý přehled - pro rychlé zobrazení např. průměrné retence
3) Jak bys ošetřil/a filtry a jejich vzájemné propojení
- Filtry jsem zvolila na základě země (CZ, SK, HU a ALL, které je kombinací všech zemí). Jako další filtr jsem zvolila filtr měsíce kohorty. Oba filtry jsou napojené na stejný zdroj dat, takže se automaticky promítají do všech metrik i grafů.
4) Jakékoliv limity nebo úskalí, která by tě při realizaci čekala
- Asi největším limitem zvoleného řešení je ruční export dat do Google Sheets. Pro dlouhodobé produkční využití by bylo vhodnější přímé napojení na databázi nebo datový sklad. Dalším úskalím je správné nastavení datových typů v Google Sheets a agregací v Looker Studiu, aby se předpočítané retenční metriky dále nesčítaly nebo neinterpretovaly jako text.

**Shrnutí práce:** 

V rámci case study jsem připravila transakční data ze tří trhů, provedla jejich validaci a očištění ve staging tabulkách a následně vytvořila finální tabulky. Nad sjednoceným view jsem připravila SQL kohortní analýzu zákaznické retence v obdobích M0, M3, M6 a M9. Výsledky jsem exportovala do retenční tabulky a vizualizovala v Looker Studiu s možností filtrování podle země a měsíce kohorty.

Z výsledků je patrné, že průměrná retence zákazníků se napříč sledovanými obdobími pohybuje přibližně mezi 26–29 %. Retence M3, M6 a M9 je relativně stabilní, bez jednoznačného dlouhodobého růstového nebo klesajícího trendu. Silnější návratovost vykazují některé kohorty z první poloviny roku 2023, zatímco u novějších kohort je část hodnot ponechána jako null, protože pro ně nejsou dostupná kompletní retenční okna. Hodnoty null proto neznamenají nulovou retenci, ale neúplnost dostupných dat.

<img width="1821" height="1491" alt="image" src="https://github.com/user-attachments/assets/4e63b564-99a1-474b-9095-b48075117dfb" />
<img width="1811" height="771" alt="image" src="https://github.com/user-attachments/assets/aebb27c1-347a-4dd8-b044-aa9f92f0a9b7" />

