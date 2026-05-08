# Postup při vypracování case study

Tento soubor slouží jako popis postupu při vypracování Case Study. Pokud byl nějaký kód repetitivní, je zde uveden jen na jednom příkladu. Kompletní skript najdete [zde](https://github.com/AndreaMaratova/CRM-Analytik-Case-Study/blob/main/skript.sql). 

## 1. Validace a nahrání zdrojových dat do databáze
#### 1. Rozdělila jsem data ze zdrojového .xlsx souboru do tří .csv souborů dle národnosti. Vytvořila jsem samostatné soubory *cz.csv*, *sk.csv* a *hu.csv*. 
#### 2. V databázi jsem vytvořila tři staging tabulky: *staging_orders_cz*, *staging_orders_sk* a *staging_orders_hu* dvěma novými sloupci:
- transakce_id - id daného záznamu
- kod_zeme - země pro snazší filtrování

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
#### 4. Zkontrolovala jsem, zda jsou všechny hodnoty v mnou požadovaném formátu. Při vizuální kontrole dat v Excelu jsem si všimla zdánlivých NULL hodnot jak ve sloupci *zakaznik_id*, tak ve sloupci *castka*.

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
	or char_length(castka) = 1 # slouží pro kontrolu, zda nejsou v tabulce další nesmyslné znaky
	or zakaznik_id not like "CZ%"
	or castka like '-%'
	or datum_nakupu like '%.%'
	or datum_nakupu not between '2023-01-01' and '2024-09-30';

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
where datum_nakupu not between '2023-01-01' and '2024-09-30';

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
select count(1) from vw_orders_all; # 2 870 záznamů = 948 (CZ) + 955 (SK) + 967 (HU)    - sedí
```


## 3. Vytvoření skriptu pro výpočet kohorty

#### 1. Nejprve jsem vytvořila základ pro správný výpočet kohorty. Aby bylo možné v reportu jednodušše filtrovat, jsou data uvedena jak po jednotlivých zemích, tak i jako celek za všechny 3 země. 

```sql
with obj as (

    # data za jednotlivé země
    select
        kod_zeme as zeme,
        zakaznik_id,
        datum_nakupu,
        castka
    from vw_orders_all

    union all

    # celek za všechny 3 země
    select
        'ALL' as zeme,
        zakaznik_id,
        datum_nakupu,
        castka
    from vw_orders_all

),

```
#### 2. Vytvořila jsem si vypočtené pomocné sloupce, které zobrazují např. poslední den (konec sledovaného období). Ten mi slouží k určení, jestli retenční okno ještě spadá do časového okna dat, které mám, nebo ne. Určitě nebude možné vyhodnotit M6 nebo M9 pro pozdější data, jelikož nejsou dostupná data od 2024-10-01. V těchto případech se hodnota nastaví jako NULL. 

```sql
posledni_den as (

    # poslední den v datasetu
    select
        last_day(max(datum_nakupu)) as konec_sledovaneho_obdobi
    from vw_orders_all

),
```

#### 3. Jako další jsem doplnila datum první objednávky každého zákazníka. Každý zákazník má právě jedno datum svého prvního nákupu. Seskupení muselo proběhnout podle *zeme*, protože je potřeba, aby report fungoval jak pro jednotlivé samostatné země, tak i jako celek.


```sql
prvni_obj as (

    # první nákup každého zákazníka
    select
        zeme,
        zakaznik_id,
        min(datum_nakupu) as prvni_obj_datum
    from obj
    group by
        zeme,
        zakaznik_id

),

```

#### 4. Jako další jsem zařadila zákazníka do kohorty na základě jeho první objednávky. Kohorta je měsíc prvního nákupu, takže všechna data v měsíci převádím na první den v měsíci. Formát datumu jsem pak zpětně převedla opět na date. 


```sql


kohorta as (

    # zařazení zákazníka do kohorty dle jeho první objednávky
    select
        zeme,
        zakaznik_id,
        prvni_obj_datum,
        str_to_date(date_format(prvni_obj_datum, '%Y-%m-01'), '%Y-%m-%d') as kohorta_mesic
    from prvni_obj

),

```
#### 5. Pak jsem připojila kohortu zákazníka ke každé objednávce. Doplnila jsem k objednávce měsíc kohorty a počet měsíců od prvního nákupu.  



```sql
obj_s_kohortou as (


	# Připojení kohorty zákazníka ke každé objednávce a počet měsíců od jeho prvního nákupu
    select
        o.zeme,
        o.zakaznik_id,
        o.datum_nakupu,
        o.castka,
        k.kohorta_mesic,
        period_diff(
            date_format(o.datum_nakupu, '%Y%m'),
            date_format(k.prvni_obj_datum, '%Y%m')
        ) as pocet_mesicu_od_prvni_obj
    from obj o
    join kohorta k
        on o.zeme = k.zeme
       and o.zakaznik_id = k.zakaznik_id

),

```

#### 6. Poté jsem provedla agregaci dat tak, aby se mi zákazníci rozhodili do správných retenčních období M3, M6 a M9. Aby nedošlo ke zkreslení dat, k započtení zákazníka, který v měsíci svého návratu udělal více objednávek, právě jednou, jsem použila *count(distinct case...)*. 

```sql

agregace_kohort as (

    # agregace zákazníků podle kohorty a retenčních období
    select
        zeme,
        kohorta_mesic,

        # velikost kohorty = počet zákazníků, kteří měli v daném měsíci první nákup
        count(distinct zakaznik_id) as velikost_kohorty,

        # zákazníci, kteří se vrátili 2 až 4 měsíce po prvním nákupu
        count(distinct case
            when pocet_mesicu_od_prvni_obj between 2 and 4
            then zakaznik_id
        end) as zakaznici_mesic_3,

        # zákazníci, kteří se vrátili 5 až 7 měsíců po prvním nákupu
        count(distinct case
            when pocet_mesicu_od_prvni_obj between 5 and 7
            then zakaznik_id
        end) as zakaznici_mesic_6,

        # zákazníci, kteří se vrátili 8 až 10 měsíců po prvním nákupu
        count(distinct case
            when pocet_mesicu_od_prvni_obj between 8 and 10
            then zakaznik_id
        end) as zakaznici_mesic_9

    from obj_s_kohortou
    group by
        zeme,
        kohorta_mesic

),

```
#### 7. Dále jsem doplnila datum, které je poslední pro určení daného retenčního okna dané objednávky. To použiju později k určení, jestli mám všechna data pro správné určení kohorty. Pokud je datum po 2024-09-30, pak se u daného okna zobrazí NULL, jelikož nemám všechna data pro správné vypočtení a mohlo by dojít k chybnému zkreslení. 


```sql


agregace_s_dostupnosti as (

	# Ke kohortě přidáme datum konce pro sledované období. Pokud datum konce nespadá do časového okna 2023-01-01 - 2024-09-30, pak se retenční okno nevyhodnotí - NULL

    select
        a.*,
        p.konec_sledovaneho_obdobi
    from agregace_kohort a
    cross join posledni_den p

),

```

#### 8. V posledním kroku jsem se dostala k výpočtu procent retence. Retence je vypočtena jako podíl unikátních zákazníků, kteří se v daném období vrátili, vůči celkové velikosti dané kohorty. M0 je vždy 100 %. Opět kontroluji, jestli mám všechna data pro férové vyhodnocení kohorty. Pokud je datum po konci sledovaného období, zobrazí se NULL. 

```sql
select
    zeme,
    kohorta_mesic,
    velikost_kohorty,

    
    100.00 as retence_mesic_0_pct, # month 0 je baseline, tedy 100 % zákazníků v dané kohortě

    # m3 = zákazníci s nákupem 2 až 4 měsíce po prvním nákupu, výsledek se zobrazí jen v případě, kdy je dostupné celé okno (tedy 4 měsíce od nákupu)
    case
        when konec_sledovaneho_obdobi >= last_day(date_add(kohorta_mesic, interval 4 month))
        then round(zakaznici_mesic_3 * 100.0 / velikost_kohorty, 2)
        else null
    end as retence_mesic_3_pct,

    # m6 = zákazníci s nákupem 5 až 7 měsíců po prvním nákupu, výsledek se zobrazí jen v případě, kdy je dostupné celé okno (tedy 7 měsíců od nákupu)
    case
        when konec_sledovaneho_obdobi >= last_day(date_add(kohorta_mesic, interval 7 month))
        then round(zakaznici_mesic_6 * 100.0 / velikost_kohorty, 2)
        else null
    end as retence_mesic_6_pct,

    # m9 = zákazníci s nákupem 8 až 10 měsíců po prvním nákupu, výsledek se zobrazí jen v případě, kdy je dostupné celé okno (tedy 10 měsíců od nákupu)
    case
        when konec_sledovaneho_obdobi >= last_day(date_add(kohorta_mesic, interval 10 month))
        then round(zakaznici_mesic_9 * 100.0 / velikost_kohorty, 2)
        else null
    end as retence_mesic_9_pct,

    case
        when konec_sledovaneho_obdobi >= last_day(date_add(kohorta_mesic, interval 4 month))
        then zakaznici_mesic_3
        else null
    end as zakaznici_mesic_3,

    case
        when konec_sledovaneho_obdobi >= last_day(date_add(kohorta_mesic, interval 7 month))
        then zakaznici_mesic_6
        else null
    end as zakaznici_mesic_6,

    case
        when konec_sledovaneho_obdobi >= last_day(date_add(kohorta_mesic, interval 10 month))
        then zakaznici_mesic_9
        else null
    end as zakaznici_mesic_9,

    konec_sledovaneho_obdobi,
from agregace_s_dostupnosti;

```
#### 9. Pro info a kontrolu jsem ještě doplnila poslední den, do kterého bych musela mít data pro správné vyhodnocení retenčního okna. 

```sql

    # poslední den retenčního okna, kdy je možné vyhodnotit
    last_day(date_add(kohorta_mesic, interval 4 month)) as datum_potrebne_pro_m3,
    last_day(date_add(kohorta_mesic, interval 7 month)) as datum_potrebne_pro_m6,
    last_day(date_add(kohorta_mesic, interval 10 month)) as datum_potrebne_pro_m9

```
#### 10. Data jsem pro přehled seřadila dle země a měsíce dané kohorty. 

```sql

order by
    case
        when zeme = 'ALL' then 1
        when zeme = 'CZ' then 2
        when zeme = 'SK' then 3
        when zeme = 'HU' then 4
        else 5
    end,
    kohorta_mesic;
```

