-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------
# Vytvoření orders_cz
-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------

# Vytvoření staging tabulky
create table staging_orders_cz (
    transakce_id int auto_increment primary key,
    zakaznik_id varchar(50),
    datum_nakupu varchar(50),
    castka varchar(50),
    kod_zeme varchar(2) not null default 'CZ'
);

load data local infile 'f:/python & sql/astratex/data/cz.csv'
into table staging_orders_cz
character set utf8mb4
fields terminated by ';'
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
(zakaznik_id, datum_nakupu, castka);

select count(1) from staging_orders_cz; #969 - sedí


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
set datum_nakupu = date_format(str_to_date(datum_nakupu, '%d.%m.%Y'), '%Y-%m-%d')
where datum_nakupu like '%.%';

# bod f)
update staging_orders_cz
set castka = replace(castka, ',', '.')
where castka like '%,%';

# bod g)
delete from staging_orders_cz 
where datum_nakupu not between '2023-01-01' and '2024-12-31';


select * from staging_orders_cz soc 
limit 10;




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

select count(1) from staging_orders_cz soc ; # 948


# Vytvoření finálních tabulek


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



-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------
# Vytvoření orders_sk
-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------


# Vytvoření staging tabulky
create table staging_orders_sk (
    transakce_id int auto_increment primary key,
    zakaznik_id varchar(50),
    datum_nakupu varchar(50),
    castka varchar(50),
    kod_zeme varchar(2) not null default 'SK'
);

load data local infile 'f:/python & sql/astratex/data/sk.csv'
into table staging_orders_sk
character set utf8mb4
fields terminated by ';'
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
(zakaznik_id, datum_nakupu, castka);

select count(1) from staging_orders_sk; # 976 - sedí


# Nejprve osekat data z obou stran o escape znaky (10 - \n, 13 - \r, 9 - tab, 160 - pevná mezera)
update staging_orders_sk
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
   
   
   
   
select * from staging_orders_sk sos 
where zakaznik_id is null
	or datum_nakupu is null
	or castka is null
	or trim(zakaznik_id) = ''
	or trim(datum_nakupu) = ''
	or trim(castka) = ''
	or char_length(castka) = 1
	or zakaznik_id not like "SK%"
	or castka like '-%'
	or datum_nakupu like '%.%'
	or datum_nakupu not between '2023-01-01' and '2024-12-31';



# bod a)
delete from staging_orders_sk
where zakaznik_id is null
   or trim(zakaznik_id) = '';

# bod b)
update staging_orders_sk
set zakaznik_id = concat('SK', zakaznik_id)
where zakaznik_id is not null
  and trim(zakaznik_id) <> ''
  and zakaznik_id not like 'SK%';

# bod c)
update staging_orders_sk
set castka = '0'
where castka is null
   or trim(castka) = '';

# bod d)
delete from staging_orders_sk
where castka like '-%';

# bod e)
update staging_orders_sk
set castka = replace(castka, ',', '.')
where castka like '%,%';

# bod f)
update staging_orders_sk
set datum_nakupu = date_format(str_to_date(datum_nakupu, '%d.%m.%Y'), '%Y-%m-%d')
where datum_nakupu like '%.%';

# bod g)
delete from staging_orders_sk
where datum_nakupu not between '2023-01-01' and '2024-12-31';

select * from staging_orders_sk sos 
limit 10;



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
    from staging_orders_sk
) x
where poradi_v_duplicite > 1;

# 2 - zobrazení duplicit

select
    sos.transakce_id,
    sos.zakaznik_id,
    sos.datum_nakupu,
    sos.castka,
    d.pocet
from staging_orders_sk sos
join (
    select
        zakaznik_id,
        datum_nakupu,
        castka,
        count(1) as pocet
    from staging_orders_sk
    group by
        zakaznik_id,
        datum_nakupu,
        castka
    having count(1) > 1
) d
    on sos.zakaznik_id = d.zakaznik_id
   and sos.datum_nakupu = d.datum_nakupu
   and sos.castka = d.castka
order by
    sos.zakaznik_id,
    sos.datum_nakupu,
    sos.castka,
    sos.transakce_id;


# 3 - smazání duplicit

delete from staging_orders_sk
where transakce_id in (
    select transakce_id
    from (
        select
            transakce_id,
            row_number() over (
                partition by zakaznik_id, datum_nakupu, castka
                order by transakce_id
            ) as poradi_v_duplicite
        from staging_orders_sk
    ) x
    where poradi_v_duplicite > 1
);

# 4 - kontrola smazaných duplicit

select
    zakaznik_id,
    datum_nakupu,
    castka,
    count(1) as pocet
from staging_orders_sk
group by
    zakaznik_id,
    datum_nakupu,
    castka
having count(1) > 1;

select count(1) from staging_orders_sk sos ; # 955

select * from staging_orders_sk
limit 10;


# Vytvoření finální tabulky


create table orders_sk (
    transakce_id int primary key,
    zakaznik_id varchar(50) not null,
    datum_nakupu date not null,
    castka decimal(10,2) not null,
    kod_zeme varchar(2) not null
);

# Nahrání dat do tabulky

insert into orders_sk (
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
from staging_orders_sk;

# Kontrola počtu záznamů
select count(1) from orders_sk ; # 955



-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------
# Vytvoření orders_hu
-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------


# Vytvoření staging tabulky
create table staging_orders_hu (
    transakce_id int auto_increment primary key,
    zakaznik_id varchar(50),
    datum_nakupu varchar(50),
    castka varchar(50),
    kod_zeme varchar(2) not null default 'HU'
);

load data local infile 'f:/python & sql/astratex/data/hu.csv'
into table staging_orders_hu
character set utf8mb4
fields terminated by ';'
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
(zakaznik_id, datum_nakupu, castka);

select count(1) from staging_orders_hu; # 988 - sedí


# Nejprve osekat data z obou stran o escape znaky (10 - \n, 13 - \r, 9 - tab, 160 - pevná mezera)
update staging_orders_hu
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
   
   
   
   
select * from staging_orders_hu soh 
where zakaznik_id is null
	or datum_nakupu is null
	or castka is null
	or trim(zakaznik_id) = ''
	or trim(datum_nakupu) = ''
	or trim(castka) = ''
	or char_length(castka) = 1
	or zakaznik_id not like "HU%"
	or castka like '-%'
	or datum_nakupu like '%.%'
	or datum_nakupu not between '2023-01-01' and '2024-12-31';



# bod a)
delete from staging_orders_hu
where zakaznik_id is null
   or trim(zakaznik_id) = '';

# bod b)
update staging_orders_hu
set zakaznik_id = concat('HU', zakaznik_id)
where zakaznik_id is not null
  and trim(zakaznik_id) <> ''
  and zakaznik_id not like 'HU%';

# bod c)
update staging_orders_hu
set castka = '0'
where castka is null
   or trim(castka) = '';

# bod d)
delete from staging_orders_hu
where castka like '-%';

# bod e)
update staging_orders_hu
set castka = replace(castka, ',', '.')
where castka like '%,%';

# bod f)
update staging_orders_hu
set datum_nakupu = date_format(str_to_date(datum_nakupu, '%d.%m.%Y'), '%Y-%m-%d')
where datum_nakupu like '%.%';

# bod g)
delete from staging_orders_hu 
where datum_nakupu not between '2023-01-01' and '2024-12-31';

select * from staging_orders_hu soh 
limit 10;



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
    from staging_orders_hu
) x
where poradi_v_duplicite > 1;

# 2 - zobrazení duplicit

select
    soh.transakce_id,
    soh.zakaznik_id,
    soh.datum_nakupu,
    soh.castka,
    d.pocet
from staging_orders_hu soh
join (
    select
        zakaznik_id,
        datum_nakupu,
        castka,
        count(1) as pocet
    from staging_orders_hu
    group by
        zakaznik_id,
        datum_nakupu,
        castka
    having count(1) > 1
) d
    on soh.zakaznik_id = d.zakaznik_id
   and soh.datum_nakupu = d.datum_nakupu
   and soh.castka = d.castka
order by
    soh.zakaznik_id,
    soh.datum_nakupu,
    soh.castka,
    soh.transakce_id;


# 3 - smazání duplicit

delete from staging_orders_hu
where transakce_id in (
    select transakce_id
    from (
        select
            transakce_id,
            row_number() over (
                partition by zakaznik_id, datum_nakupu, castka
                order by transakce_id
            ) as poradi_v_duplicite
        from staging_orders_hu
    ) x
    where poradi_v_duplicite > 1
);

# 4 - kontrola smazaných duplicit

select
    zakaznik_id,
    datum_nakupu,
    castka,
    count(1) as pocet
from staging_orders_hu
group by
    zakaznik_id,
    datum_nakupu,
    castka
having count(1) > 1;

select count(1) from staging_orders_hu soh ; # 967

select * from staging_orders_hu
limit 10;


# Vytvoření finální tabulky

create table orders_hu (
    transakce_id int primary key,
    zakaznik_id varchar(50) not null,
    datum_nakupu date not null,
    castka decimal(10,2) not null,
    kod_zeme varchar(2) not null
);

# Nahrání dat do tabulky

insert into orders_hu (
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
from staging_orders_hu;

# Kontrola počtu záznamů
select count(1) from orders_hu ; # 967



-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------
# Vytvoření vw_orders_all
-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------


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

select count(1) from vw_orders_all; # 2 870 záznamů = 948 (CZ) + 955 (SK) + 967 (HU);



-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------
# Vytvoření skriptu ke kohortě
-- -------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------

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

posledni_den as (

    # poslední den v datasetu
    select
        last_day(max(datum_nakupu)) as konec_sledovaneho_obdobi
    from vw_orders_all

),

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

kohorta as (

    # zařazení zákazníka do kohorty dle jeho první objednávky
    select
        zeme,
        zakaznik_id,
        prvni_obj_datum,
        str_to_date(date_format(prvni_obj_datum, '%Y-%m-01'), '%Y-%m-%d') as kohorta_mesic
    from prvni_obj

),

obj_s_kohortou as (

    # připojení kohorty zákazníka ke každé objednávce a počet měsíců od jeho prvního nákupu
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

agregace_s_dostupnosti as (

    # ke kohortě přidáme datum konce pro sledované období
    # pokud celé retenční okno není dostupné, výsledek se nastaví na null
    select
        a.*,
        p.konec_sledovaneho_obdobi
    from agregace_kohort a
    cross join posledni_den p

)

select
    zeme,
    kohorta_mesic,
    velikost_kohorty,

    # month 0 je baseline, tedy 100 % zákazníků v dané kohortě
    100.00 as retence_mesic_0_pct,

    # m3 = zákazníci s nákupem 2 až 4 měsíce po prvním nákupu
    case
        when konec_sledovaneho_obdobi >= last_day(date_add(kohorta_mesic, interval 4 month))
        then round(zakaznici_mesic_3 * 100.0 / velikost_kohorty, 2)
        else null
    end as retence_mesic_3_pct,

    # m6 = zákazníci s nákupem 5 až 7 měsíců po prvním nákupu
    case
        when konec_sledovaneho_obdobi >= last_day(date_add(kohorta_mesic, interval 7 month))
        then round(zakaznici_mesic_6 * 100.0 / velikost_kohorty, 2)
        else null
    end as retence_mesic_6_pct,

    # m9 = zákazníci s nákupem 8 až 10 měsíců po prvním nákupu
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

    # poslední den retenčního okna, kdy je možné vyhodnotit
    last_day(date_add(kohorta_mesic, interval 4 month)) as datum_potrebne_pro_m3,
    last_day(date_add(kohorta_mesic, interval 7 month)) as datum_potrebne_pro_m6,
    last_day(date_add(kohorta_mesic, interval 10 month)) as datum_potrebne_pro_m9

from agregace_s_dostupnosti

order by
    case
        when zeme = 'ALL' then 1
        when zeme = 'CZ' then 2
        when zeme = 'SK' then 3
        when zeme = 'HU' then 4
        else 5
    end,
    kohorta_mesic;
