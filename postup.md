# Postup při vypracování case study

## 1. Validace a nahrání zdrojových dat do databáze
1. Rozdělila jsem data ze zdrojového .xlsx souboru do tří .csv souborů dle národnosti. Vytvořila jsem samostatné soubory cz.csv, sk.csv a hu.csv. 
2. V databázi jsem vytvořila tři staging tabulky: objednavky_cz, objednavky_sk a objednavky_hu.

```sql
# Vytvoření staging tabulek
create table staging_objednavky_cz (
	zakaznik_id varchar(50),
	datum_nakupu varchar(50),
	castka varchar(50)
);

create table staging_objednavky_sk (
	zakaznik_id varchar(50),
	datum_nakupu varchar(50),
	castka varchar(50)
);

create table staging_objednavky_hu (
	zakaznik_id varchar(50),
	datum_nakupu varchar(50),
	castka varchar(50)
);

```
3. Do staging tabulek jsem nahrála data a zkontrolovala počet záznamů.

```sql
load data local infile 'F:/Python & SQL/Astratex/data/cz.csv'
into table staging_objednavky_cz
character set utf8mb4
fields terminated by ';'
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

oad data local infile 'F:/Python & SQL/Astratex/data/sk.csv'
into table staging_objednavky_sk
character set utf8mb4
fields terminated by ';'
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

load data local infile 'F:/Python & SQL/Astratex/data/hu.csv'
into table staging_objednavky_hu
character set utf8mb4
fields terminated by ';'
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select count(1) from staging_objednavky_cz; #969 - sedí
select count(1) from staging_objednavky_sk; #976 - sedí
select count(1) from staging_objednavky_hu; #988 - sedí

```
