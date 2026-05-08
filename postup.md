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
	or castka like '-%'
	or datum_nakupu like '%.%'
	or datum_nakupu not between '2023-01-01' and '2024-12-31';

```
<img width="650" height="650" alt="image" src="https://github.com/user-attachments/assets/8c5d8bec-629c-43d5-9079-577cdd0f18e2" />





Vzhledem k charakteru dat a cíli case study jsem se u čištění dat rozhodla postupovat následovně:

a) Data, u kterých chybí *zakaznik_id* - smazat

b) Data, u kterých chybí ve sloupci *zakaznik_id* prefix země - doplnit prefix země
	
- Díky tomu, že zdrojová data jsou ze 3 zemí s rozdílnými měnami, jejíchž částky se pohybují v jiných řádech, předpokládám, že se opravdu jedná o zákazníka dané země.  

c) Data, u kterých chybí *castka* - ponechat a vložit 0.
	
- V závislosti na charakteru této case study jsem se rozhodla tyto záznamy ponechat. Za jiných okolností by se mohlo k těmto záznamů přistupovat jinak, např. nahrazením chybějící hodnoty průměrem všech částek nebo jejich odstraněním.

d) Ve sloupci *castka* se objevují i záporné hodnoty. Ty považuji za vratky - smazat
- Opět vzhledem k charakteru case study jsem se rozhodla pro toto řešení. Za jiných okolností by se data mazat nemusela.

e) Ve sloupci *castka* jsem změnila , za .

f) Upravila jsem formát datumu z dd.mm.yyyy na yyyy-mm-dd

g) Odstranila data, která nespadají do období 2023-01-01 - 2024-09-30.


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
  and zakaznik_id not like 'CZ%';

# bod c)
update staging_orders_cz
set castka = '0'
where castka is null
   or trim(castka) = '';

# bod d)
delete from staging_orders_cz
where castka like '-%';

# bod e)
update staging_orders_cz
set castka = replace(castka, ',', '.')
where castka like '%,%';

# bod f)
update staging_orders_cz
set datum_nakupu = date_format(str_to_date(datum_nakupu, '%d.%m.%Y'), '%Y-%m-%d')
where datum_nakupu like '%.%';

# bod g)
delete from staging_orders_cz 
where datum_nakupu not between '2023-01-01' and '2024-12-31';

```


#### 5. Odstranila jsem duplicity

```sql
# Duplicity
# 1 - počet duplicit
select count(1) as pocet_duplicit
from (
    select
        transakce_id,
        row_number() over (
            partition by zakaznik_id, datum_nakupu, castka
            order by transakce_id
        ) as poradi_v_duplicite
    from staging_orders_cz
) x
where poradi_v_duplicite > 1;

# 2 - zobrazení duplicit

select
    soc.transakce_id,
    soc.zakaznik_id,
    soc.datum_nakupu,
    soc.castka,
    d.pocet
from staging_orders_cz soc
join (
    select
        zakaznik_id,
        datum_nakupu,
        castka,
        count(1) as pocet
    from staging_orders_cz
    group by
        zakaznik_id,
        datum_nakupu,
        castka
    having count(1) > 1
) d
    on soc.zakaznik_id = d.zakaznik_id
   and soc.datum_nakupu = d.datum_nakupu
   and soc.castka = d.castka
order by
    soc.zakaznik_id,
    soc.datum_nakupu,
    soc.castka,
    soc.transakce_id;


# 3 - smazání duplicit

delete from staging_orders_cz
where transakce_id in (
    select transakce_id
    from (
        select
            transakce_id,
            row_number() over (
                partition by zakaznik_id, datum_nakupu, castka
                order by transakce_id
            ) as poradi_v_duplicite
        from staging_orders_cz
    ) x
    where poradi_v_duplicite > 1
);

# 4 - kontrola smazaných duplicit

select
    zakaznik_id,
    datum_nakupu,
    castka,
    count(1) as pocet
from staging_orders_cz
group by
    zakaznik_id,
    datum_nakupu,
    castka
having count(1) > 1;

```

Po čištění dat zbylo celkem 948 záznamů z původních 969. 

```sql
select count(1) from staging_orders_cz soc ; # 948
```

#### 6. Vytvořila jsem finální tabulky a zkontrolovala, že se nahrály všechny záznamy

```sql
create table orders_cz (
    transakce_id int primary key,
    zakaznik_id varchar(50) not null,
    datum_nakupu date not null,
    castka decimal(10,2) not null,
    kod_zeme varchar(2) not null
);

# Nahrání dat do tabulky

insert into orders_cz (
    transakce_id,
    zakaznik_id,
    datum_nakupu,
    castka,
    kod_zeme
)
select
    transakce_id,
    zakaznik_id,
    datum_nakupu,
    cast(castka as decimal(10,2)) as castka,
    kod_zeme
from staging_orders_cz;

# Kontrola počtu záznamů
select count(1) from orders_cz oc; # 948

```

## 2. Vytvoření view pro kohortní analýzu

Pro kohortní analýzu jsem se rozhodla vytvořit view, nad kterým budu danou analýzu stavět. View bude kombinací všech tří tabulek *orders_cz*, *orders_sk* a *orders_hu*.

```sql
create view vw_orders_all as
select
    concat(kod_zeme, '-', transakce_id) as global_transakce_id,
    transakce_id as puvodni_transakce_id,
    zakaznik_id,
    datum_nakupu,
    castka,
    kod_zeme
from orders_cz
union all
select
    concat(kod_zeme, '-', transakce_id) as global_transakce_id,
    transakce_id as puvodni_transakce_id,
    zakaznik_id,
    datum_nakupu,
    castka,
    kod_zeme
from orders_sk
union all
select
    concat(kod_zeme, '-', transakce_id) as global_transakce_id,
    transakce_id as puvodni_transakce_id,
    zakaznik_id,
    datum_nakupu,
    castka,
    kod_zeme
from orders_hu;
```

Provedla jsem kontrolu, jestli se nahrály všechny záznamy.

```sql
select count(1) from vw_orders_all; # 2 882 záznamů = 952 (CZ) + 959 (SK) + 971 (HU)    - sedí
```
