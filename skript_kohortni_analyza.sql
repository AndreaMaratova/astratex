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
