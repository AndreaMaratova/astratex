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

Export výsledné kohorní retenční tabulky naleznete [zde](https://github.com/AndreaMaratova/CRM-Analytik-Case-Study/blob/main/kohorni_retencni_tabulka.csv). Soubor neotvírejte v Excelu - přepíše se formátování. 

Vizualizaci dat přes Looker Studio naleznete [zde](https://datastudio.google.com/s/iEPu3P8QDuc).

Zdrojová data nejsou z důvodu bezpečnosti součástí repozitáře. 

## Shrnutí práce a odpovězení na zadané otázky




1) Jaký datový zdroj bys napojil/a a jak bys data připravil/a pro Looker Studio
- Záleželo by, kde by zdrojová data byla. Já jsem pro tento úkol šla cestou "nejmenšího odporu" a jelikož jde o jednorázové řešení, nahrála jsem .csv do Google Sheets, nad kterými jsem pak udělala vizualizaci v Looker Studiu. V nějakém dlouhodobém řešení by pak bylo ideální napojit se na danou databázi, kde by se data počítala přes view. Jelikož ale moje databáze běží lokálně, bylo by napojení na Looker Studio náročnější. 
2) Jaké typy vizualizací bys zvolil/a a proč
- Heatmapu - na první dobrou z ní člověk vyčte, co potřebuje
- Spojnicový graf - pro zobrazení dat v čase
- Rychlý přehled - pro rychlé zobrazení např. průměrné retence
3) Jak bys ošetřil/a filtry a jejich vzájemné propojení
- ???
4) Jakékoliv limity nebo úskalí, která by tě při realizaci čekala
- Jelikož vizualizace byla dělána v Looker Studiu, které mi není úplně nejbližší, tak bych řekla, že největší limity a úskalí pro mě bylo ze začátku samotné Looker Studio :D  

Shrnutí práce (3-5 vět)
???
<img width="1824" height="1483" alt="image" src="https://github.com/user-attachments/assets/bb7ff6aa-2ecc-4e47-b5f7-88e8958f30d0" />
<img width="1805" height="695" alt="image" src="https://github.com/user-attachments/assets/0867c3ea-360f-4822-9ae6-7db10d1c4a0e" />
