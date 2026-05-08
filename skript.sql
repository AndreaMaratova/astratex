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
