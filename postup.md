# Postup při vypracování case study

Tento soubor slouží jako popis postupu při vypracování case study. Pokud byl nějaký kód repetitivní, je zde uveden jen na jednom příkladu. Kompletní skript najdete **ZDE**. 

## 1. Validace a nahrání zdrojových dat do databáze
#### 1. Rozdělila jsem data ze zdrojového .xlsx souboru do tří .csv souborů dle národnosti. Vytvořila jsem samostatné soubory *cz.csv*, *sk.csv* a *hu.csv*. 
#### 2. V databázi jsem vytvořila tři staging tabulky: *staging_orders_cz*, *staging_orders_sk* a *staging_orders_hu* dvěma novými sloupci:
- transakce_id - id daného záznamu
- Kod_zeme - země pro snažší filtrování

```sql
# Vytvoření staging tabulky
create table staging_orders_cz (
    transakce_id int auto_increment primary key,
    zakaznik_id varchar(50),
    datum_nakupu varchar(50),
    castka varchar(50),
    kod_zeme varchar(2) not null default 'CZ'
);

```
#### 3. Do staging tabulek jsem nahrála data a zkontrolovala počet záznamů.

```sql
load data local infile 'f:/python & sql/astratex/data/cz.csv'
into table staging_orders_cz
character set utf8mb4
fields terminated by ';'
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
(zakaznik_id, datum_nakupu, castka);

select count(1) from staging_orders_cz; #969 - sedí


```
#### 4. Zkontrolovala jsem, zda jsou všechny hodnoty v mnou pořadovaném formátu. Při vizuální kontrole dat v Excelu jsem si všimla zdánlivých NULL hodnot jak ve sloupci *zakaznik_id*, tak ve sloupci *castka*.

Nejprve jsem se rozhodla jsem se očistit data z obou stran o "neviditelné znaky" - escape znaky, tab a pevné mezery. 

```sql
# Nejprve osekat data z obou stran o escape znaky (10 - \n, 13 - \r, 9 - tab, 160 - pevná mezera)
update staging_orders_cz
set
    zakaznik_id = trim(
        both char(160) from trim(
            both char(9) from trim(
                both char(10) from trim(
                    both char(13) from trim(zakaznik_id)
                )
            )
        )
    ),
    datum_nakupu = trim(
        both char(160) from trim(
            both char(9) from trim(
                both char(10) from trim(
                    both char(13) from trim(datum_nakupu)
                )
            )
        )
    ),
    castka = trim(
        both char(160) from trim(
            both char(9) from trim(
                both char(10) from trim(
                    both char(13) from trim(castka)
                )
            )
        )
    );
```

Výsledný skript pro zobrazení špatně formátovaných nebo chybných hodnot:

```sql
select * from staging_orders_cz soc 
where zakaznik_id is null
	or datum_nakupu is null
	or castka is null
	or trim(zakaznik_id) = ''
	or trim(datum_nakupu) = ''
	or trim(castka) = ''
	or char_length(castka) = 1
	or zakaznik_id not like "CZ%"
	or castka like '-%';
```
<img width="600" height="450" alt="image" src="https://github.com/user-attachments/assets/a45b1fd5-dde1-4294-9c6c-e4496ca7d1b5" />



Vzhledem k charakteru dat a cíli case study jsem se u čištění dat rozhodla postupovat následovně:

a) Data, u kterých chybí *zakaznik_id* - smazat

b) Data, u kterých chybí ve sloupci *zakaznik_id* prefix země - doplnit prefix země
	
- Díky tomu, že zdrojová data jsou ze 3 zemí s rozdílnými měnami, jejíchž částky se pohybují v jiných řádech, předpokládám, že se opravdu jedná o zákazníka dané země.  

c) Data, u kterých chybí *castka* - ponechat a vložit 0.
	
- V závislosti na charakteru této case study jsem se rozhodla tyto záznamy ponechat. Za jiných okolností by se mohlo k těmto záznamů přistupovat jinak, např. nahrazením chybějící hodnoty průměrem všech částek nebo jejich odstraněním.

d) Ve sloupci *castka* se objevují i záporné hodnoty. Ty považuji za vratky - smazat
- Opět vzhledem k charakteru case study jsem se rozhodla pro toto řešení. Za jiných okolností by se data mazat nemusela. 


```sql
# bod a)
delete from staging_orders_cz
where zakaznik_id is null
   or trim(zakaznik_id) = '';

# bod b)
update staging_orders_cz
set zakaznik_id = concat('CZ', zakaznik_id)
where zakaznik_id is not null
  and trim(zakaznik_id) <> ''
  and zakaznik_id not like 'CZ%'

# bod c)
update staging_orders_cz
set castka = '0'
where castka is null
   or trim(castka) = '';

# bod d)
delete from staging_orders_cz
where castka like '-%';

```

Upravila jsem ještě formát sloupce *castka* a nahradila čárku tečkou. 

```sql

# nahrazení desetinné čárky tečkou
update staging_orders_cz
set castka = replace(castka, ',', '.')
where castka like '%,%';
```

# **DUPLICITY**
# **Vytvořit finální tabulky**




