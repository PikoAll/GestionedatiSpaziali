/*Funzione*/
select priorita_manutenzione();


/*QUERY 1*/

/* Somma di chiese, musei e attrazioni turistiche contenute in ogni città*/
select tab.nome, tab.id, sum(tab.conta+tab2.conta2+tab3.conta) as total
from 

(select area.nome as nome, area.id as id, sum(case when st_contains(area.geom,chiesa.geom) then 1 else 0 end ) as conta 
 	from area,chiesa 
 	where area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata'
 	group by area.id) as tab,
	
(select area.id as id ,sum(case when st_contains(area.geom,attrazioni.geom) then 1 else 0 end ) as conta2 
 	from area,attrazione_turistica as attrazioni
 	where area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata'
 	group by area.id) as tab2,
	
(select area.id as id ,sum(case when st_contains(area.geom,museo.geom) then 1 else 0 end ) as conta 
 	from area,museo
 	where area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata'
 	group by area.id) as tab3 
	
where tab.id=tab2.id and tab.id=tab3.id and tab3.id=tab2.id
group by tab.nome,tab.id
order by total desc;


/*QUERY 2*/
/*Nome dell’hotel più a ovest in Basilicata, comune d’appartenenza, chiesa più vicina, museo più vicino e attrazione turistica più vicina.*/
select hotel_ovest.nome_hotel ,area.nome as comune,  chiesa_vicina.nome, museo_vicino.nome, attrazione_vicina.nome
from (select st_x(hotel.geom), hotel.geom as pos_hotel, punto_interesse.nome as nome_hotel
   from hotel inner join punto_interesse on punto_interesse.id=hotel.id
   order by st_x(hotel.geom) limit 1) as hotel_ovest,
   
   (select punto_interesse.nome as nome 
    from chiesa inner join punto_interesse on punto_interesse.id=chiesa.id,
	(select st_x(hotel.geom), hotel.geom as pos_hotel, punto_interesse.nome as nome_hotel
        from hotel inner join punto_interesse on punto_interesse.id=hotel.id
      order by st_x(hotel.geom) limit 1) as hotel_ovest
    where st_dwithin(ST_GeographyFromText(st_AsText(hotel_ovest.pos_hotel)), ST_GeographyFromText(st_AsText(chiesa.geom)), 20000) 
    order by st_distance(ST_GeographyFromText(st_AsText(hotel_ovest.pos_hotel)), ST_GeographyFromText(st_AsText(chiesa.geom))) limit 1) as chiesa_vicina,
  
   
   (select punto_interesse.nome as nome 
    from museo inner join punto_interesse on punto_interesse.id=museo.id,(
		select st_x(hotel.geom), hotel.geom as pos_hotel, punto_interesse.nome as nome_hotel
        from hotel inner join punto_interesse on punto_interesse.id=hotel.id
      order by st_x(hotel.geom) limit 1) as hotel_ovest 
    where st_dwithin(ST_GeographyFromText(st_AsText(hotel_ovest.pos_hotel)), ST_GeographyFromText(st_AsText( museo.geom)), 20000)
   order by st_distance(ST_GeographyFromText(st_AsText(hotel_ovest.pos_hotel)), ST_GeographyFromText(st_AsText( museo.geom))) limit 1) as museo_vicino,
    
   (select punto_interesse.nome as nome 
    from attrazione_turistica inner join punto_interesse on punto_interesse.id=attrazione_turistica.id, 
	(select st_x(hotel.geom), hotel.geom as pos_hotel, punto_interesse.nome as nome_hotel
         from hotel inner join punto_interesse on punto_interesse.id=hotel.id
          order by st_x(hotel.geom) limit 1) as hotel_ovest 
    where st_dwithin(ST_GeographyFromText(st_AsText(hotel_ovest.pos_hotel)), ST_GeographyFromText(st_AsText( attrazione_turistica.geom)), 20000)
    order by st_distance(ST_GeographyFromText(st_AsText(hotel_ovest.pos_hotel)), ST_GeographyFromText(st_AsText( attrazione_turistica.geom))) limit 1) as attrazione_vicina, 
   
   area
where st_contains( area.geom, hotel_ovest.pos_hotel) and 
area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata';

/*QUERY 3*/
/*Distanza tra ogni hotel e il centroide della città di cui 
fanno parte in kilometri*/

select punto_interesse.nome as nomehotel, area.nome as comune, st_distance(ST_GeographyFromText(st_AsText(hotel.geom)), ST_GeographyFromText(st_AsText(st_centroid(area.geom))))/1000 as dist
  from area, hotel inner join punto_interesse on punto_interesse.id=hotel.id
  where st_contains(area.geom, hotel.geom) and 
area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata';


/*QUERY 4*/
/*Tutti gli hotel e stazioni che si trovano nel raggio di 10 km da una montagna/collina di cui si riporta l'altezza in metri*/
select punto_interesse.nome, tab1.nomepeak,tab1.altezza,tab1.nomestazione from punto_interesse inner join hotel on hotel.id=punto_interesse.id,
(select peak.nome as nomepeak,peak.ele as altezza,stazione.nome  as nomestazione, peak.geom as posizionepeak from stazione, peak
where st_dwithin(ST_GeographyFromText(st_AsText(peak.geom)), ST_GeographyFromText(st_AsText(stazione.geom)), 10000) 
group by peak.nome,peak.ele,stazione.nome,posizionepeak
order by peak.nome desc)tab1
where st_dwithin(ST_GeographyFromText(st_AsText(hotel.geom)), ST_GeographyFromText(st_AsText(tab1.posizionepeak)), 10000);


/*QUERY 5*/
/*numero di montagne/colline per ogni area*/
select area.nome, count(peak.geom) as numeropeak from area,peak
where st_contains(area.geom,peak.geom) and area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata'
group by area.nome
order by numeropeak desc;

/*QUERY 6*/
/*Nome di tutte le aree amministrative che contengono delle chiese di cui si riporta l'area e il nome*/
select area.nome, tab2.nomechiesa, tab2.areachiesa from area,
(select punto_interesse.nome as nomechiesa, st_area(chiesa.geom) as areachiesa, chiesa.geom as posizione
from punto_interesse inner join chiesa on chiesa.id=punto_interesse.id) tab2
where st_contains(area.geom,tab2.posizione) and area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata';


/*QUERY 7*/
/*Area amministrativa che contiene strade che intersecano fiumi*/

select area.id,area.nome, tab1.strada, tab1.fiume from area,
(select strada.nome as strada, strada.geom as posizione, fiume.nome as fiume 
 from strada, fiume where st_crosses(fiume.geom,strada.geom) ) tab1
where ST_Contains(area.geom,tab1.posizione) 
and area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata' ;


/*QUERY 8*/
/*Per ogni area amministrativa, si riportano hotel che hanno nel raggio di un kilometro una stazione di cui si riporta il nome e la distanza tra essi*/
select area.nome, tab.hotelnome, tab.stazionenome, tab.distanza from area,
(select hotel.geom as hotelpos, punto_interesse.nome as hotelnome, stazione.nome as stazionenome, ST_Distance(ST_GeographyFromText(st_AsText(hotel.geom)),ST_GeographyFromText(st_AsText(stazione.geom))) as distanza
 from hotel inner join punto_interesse on punto_interesse.id=hotel.id,stazione where ST_DWithin(hotel.geom,stazione.geom,0.01)
) as tab
 where ST_Contains(area.geom,tab.hotelpos) and  area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata'
group by area.nome, tab.hotelnome, tab.stazionenome,tab.distanza;

/*QUERY 9*/
/*ferrovie elettrificate che attaversano dei fiumi*/
select ferrovia.nome, ST_Intersection(ferrovia.geom,fiume.geom)
from ferrovia, fiume
where ferrovia.elettrificazione='contact_line' and ST_Intersects(ferrovia.geom,fiume.geom);

/*QUERY 10*/
/*strade e ferrovie che si trovano in un raggio di 5 kilometri da una montagna*/
select s.nome as nome_strada, f.nome as nome_ferrovia, cima.nome
from strada s, ferrovia f, peak cima
where st_dwithin(cima.geom, s.geom, 0.05) and st_dwithin(cima.geom, f.geom, 0.05);

/*QUERY 11*/
/*strade che incrociano sia ferrovia che fiumi*/
select tab.nome
from ferrovia,
	(select strada.nome as nome, strada.geom as posizione
	from strada, fiume
	where ST_Intersects(strada.geom,fiume.geom)) as tab
	
where ST_Intersects(tab.posizione,ferrovia.geom)
group by tab.nome;


/*QUERY 12*/
/*Nome del comune d’appartenenza di una fattoria, nome del comune il quale centro urbano è il 
più vicino alla fattoria e la distanza in metri tra questo centro urbano e la fattoria. */
select area.nome as nometerritorioapparteneza, tab6.nomefattoria, tab6.distanzaminima, tab6.nomecittavicino from area,
(select citta.nome as nomecittavicino , tab5.pos as posizione,tab5.nome as nomefattoria, tab2.minimo  as distanzaminima 
from citta,(select fattoria.nome as nome, st_pointonsurface(fattoria.geom) as pos from fattoria) as tab5 ,
	(
	select tab2.nomefattoria, min(tab2.distanza) as minimo from 
			(
			select citta.nome as nomecitta, tab.nome as nomefattoria, ST_Distance(ST_GeographyFromText(st_AsText(citta.geom)),ST_GeographyFromText(st_AsText(tab.pos))) as distanza 
			from citta, 
				(select fattoria.nome as nome, st_pointonsurface(fattoria.geom) as pos from fattoria) as tab 
			)tab2
	group by tab2.nomefattoria
	)tab2
	

where ST_Distance(ST_GeographyFromText(st_AsText(citta.geom)),ST_GeographyFromText(st_AsText(tab5.pos))) = tab2.minimo)tab6
where st_contains(area.geom,tab6.posizione) and area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata';


/*QUERY 13*/
/*aree amministrative che hanno sia fattorie che industrie*/
select area.nome, st_union(area.geom,industria.geom)
from area,industria 
where area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata' 
and st_contains(area.geom,industria.geom) 
intersect
select area.nome, st_union(area.geom,fattoria.geom)
from area, fattoria
where area.wikipedia!='it:Provincia di Potenza' and area.wikipedia!='it:Provincia di Matera' and area.wikipedia!='it:Basilicata' 
and st_contains(area.geom,fattoria.geom);

/*QUERY 14*/
/*ESTENSIONE TERRITORIALE IN PERCENTUALE DI OGNI TERRITORIO E DENSITA' DI POPOLAZIONE PER OGNUNO DI ESSI*/
select area.nome as comune, estensione_territoriale.perc_ext, densita_popolazione.dens as densita

from area, (select c.id as id_citta,(st_area(c.geom)/st_area(d.geom))*100 as perc_ext 
   from area c, area d
   where d.nome = 'Basilicata') as estensione_territoriale, 
   (select c.id as id_citta,(pt.popolazione/st_area(c.geom))*100 as dens
   from area c, citta pt
   where st_contains(c.geom, pt.geom) and c.nome = pt.nome) as densita_popolazione
   
where 
area.id = estensione_territoriale.id_citta 
and area.id = densita_popolazione.id_citta
and area.wikipedia!='it:Provincia di Potenza' 
and area.wikipedia!='it:Provincia di Matera' 
and area.wikipedia!='it:Basilicata';

/*QUERY 15*/
/*Per ogni industria si riportano hotel e stazione più vicini con le relative distanze*/
select tab.nome as idIndustria ,punto_interesse.nome as nomeHotel, tab3.minimo as distanzaminimahotel,stazione.nome as nomestazione,
tab4.minimostazioni as distanzaminimastazione
from hotel inner join punto_interesse on punto_interesse.id=hotel.id,stazione,
	(select industria.id as nome, ST_Centroid(industria.geom) as posizione from industria) as tab ,
	(select tab2.nomeind as nomeind,min(tab2.distanza) as minimo
	from
		(select tab.nome as nomeind, tab.posizione as posizione, punto_interesse.nome, st_distance(ST_GeographyFromText(st_AsText(tab.posizione)),ST_GeographyFromText(st_AsText(hotel.geom))) as distanza
		from hotel inner join punto_interesse on punto_interesse.id=hotel.id,
			(select industria.id as nome, ST_Centroid(industria.geom) as posizione from industria) as tab )tab2
	group by tab2.nomeind) tab3,
	
	(select tab2.nomeind as nomeind2,min(tab2.distanza) as minimostazioni
	from
		(select tab.nome as nomeind, tab.posizione as posizione, stazione.nome, st_distance(ST_GeographyFromText(st_AsText(tab.posizione)),ST_GeographyFromText(st_AsText(stazione.geom))) as distanza
		from stazione,
			(select industria.id as nome, ST_Centroid(industria.geom) as posizione from industria) as tab )tab2
	group by tab2.nomeind) tab4
	
	
where st_distance(ST_GeographyFromText(st_AsText(tab.posizione)),ST_GeographyFromText(st_AsText(hotel.geom)))= tab3.minimo and 
st_distance(ST_GeographyFromText(st_AsText(tab.posizione)),ST_GeographyFromText(st_AsText(stazione.geom)))= tab4.minimostazioni
order by tab.nome;

/*QUERY 16*/
/*Numero di aree amministrative attraversate da ogni fiume elencati in ordine decrescente*/
select f.id as id_fiume, sum(case when st_intersects(f.geom, ci.geom) then 1 else 0 end) as territori_attraversati
from fiume f, area ci
group by id_fiume
order by territori_attraversati desc;

/*QUERY 17*/
/*fattoria che nel raggio di 2 km ha una montagna/collina*/
select fattoria.nome, peak.nome from fattoria,peak
where st_dwithin(ST_GeographyFromText(st_AsText(fattoria.geom)), ST_GeographyFromText(st_AsText(peak.geom)), 2000) and length(fattoria.nome)>1 and length(peak.nome)>1
group by fattoria.nome,peak.nome;

/*QUERY 18*/
/*conteggio punti interesse per ogni regione*/
SELECT area.nome AS provincia, (SELECT COUNT(*)
        FROM attrazione_turistica attr WHERE st_contains(area.geom, attr.geom)) AS attrazioni_turistiche,
        (SELECT COUNT(*)
        FROM chiesa ch WHERE st_contains(area.geom, ch.geom)) AS chiese,
        (SELECT COUNT(*)
        FROM museo mus WHERE st_contains(area.geom, mus.geom)) AS musei,
        (SELECT COUNT(*)
        FROM hotel h WHERE st_contains(area.geom, h.geom)) AS hotel
FROM area
WHERE (area.wikipedia='it:Provincia di Potenza' OR area.wikipedia='it:Provincia di Matera') AND area.wikipedia!='it:Basilicata';










