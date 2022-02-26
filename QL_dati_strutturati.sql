/*Funzione*/
select conta_turisti('Cristo La Gravinella','attrazione_turistica',2);

/*QUERY 1 : 
	   CITTA' CON IL NUMERO DI HOTEL RECENSITI E IL NUMERO DI HOTEL NON RECENSITI*/

SELECT c.*, (SELECT COUNT(*) FROM hotel h 
			 INNER JOIN punto_interesse pi ON pi.id = h.id WHERE c.id = pi.id_citta AND pi.id 
			 NOT IN (SELECT r.id_punto_interesse FROM recensione r WHERE r.id_punto_interesse = pi.id))
			 as cnt_nrecensiti,
			 (SELECT COUNT(*) FROM hotel h 
			 INNER JOIN punto_interesse pi ON pi.id = h.id WHERE c.id = pi.id_citta AND pi.id 
			 IN (SELECT r.id_punto_interesse FROM recensione r WHERE r.id_punto_interesse = pi.id))
			 as cnt_recensiti
			 FROM citta c;
/*----------------------------------------------------------------------------------------------------------------------------------------*/

/*QUERY 2 
		MEDIA DEI VOTI OTTENUTI DA OGNI HOTEL ESCLUSI QUELLI OTTENUTI NELL'ANNO CORRENTE*/
		   
SELECT h.id, pi.nome, AVG(r.voto) AS media_voti
FROM hotel h INNER JOIN punto_interesse pi ON pi.id=h.id 
	INNER JOIN recensione r ON pi.id = r.id_punto_interesse
WHERE r.tempo=1
GROUP BY (h.id, pi.nome);
 
/*-----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 3:
		PERCENTUALE DEL NUMERO DI RECENSIONI OTTENUTE DA OGNI CATEGORIA DI PUNTO D'INTERESSE*/

SELECT CAST(tab_attr.numero_attrazioni_recensite as float)/CAST(tab_rec.numero_recensioni as float)*100 AS perc_attrazioni_turistiche,
	   CAST(tab_hotel.numero_hotel_recensiti as float)/CAST(tab_rec.numero_recensioni as float)*100 AS perc_hotel,
	   CAST(tab_mus.numero_musei_recensiti as float)/CAST(tab_rec.numero_recensioni as float)*100 AS perc_musei,
	   CAST(tab_chiese.numero_chiese_recensite as float)/CAST(tab_rec.numero_recensioni as float)*100 AS perc_chiese
FROM (SELECT COUNT(*) AS numero_recensioni
		FROM recensione) AS tab_rec,
	 (SELECT COUNT(*) AS numero_attrazioni_recensite
	 	FROM attrazione_turistica att INNER JOIN punto_interesse pi ON pi.id = att.id INNER JOIN recensione r ON r.id_punto_interesse = pi.id) AS tab_attr,
	 (SELECT COUNT(*) AS numero_hotel_recensiti
	    FROM hotel h INNER JOIN punto_interesse pi ON pi.id = h.id INNER JOIN recensione r ON r.id_punto_interesse = pi.id) AS tab_hotel,
	 (SELECT COUNT(*) AS numero_musei_recensiti
	    FROM museo mus INNER JOIN punto_interesse pi ON pi.id = mus.id INNER JOIN recensione r ON r.id_punto_interesse = pi.id) AS tab_mus,
	 (SELECT COUNT(*) AS numero_chiese_recensite
	    FROM chiesa ch INNER JOIN punto_interesse pi ON pi.id = ch.id INNER JOIN recensione r ON r.id_punto_interesse = pi.id) AS tab_chiese;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 4:
			NUMERO VISITATORI PER OGNI CITTA DIVISI IN OGNI CATEGORIA DI PUNTO D'INTERESSE*/
SELECT city.id AS id_citta, city.nome AS comune,
		(SELECT COUNT(*) 
		 FROM punto_interesse pi INNER JOIN attrazione_turistica attr ON pi.id = attr.id
								INNER JOIN recensione r ON r.id_punto_interesse = pi.id 
		 WHERE pi.id_citta = city.id) AS n_turisti_attrazioni_turistiche,
		(SELECT COUNT(*) 
		 FROM punto_interesse pi INNER JOIN chiesa ch ON pi.id = ch.id
								INNER JOIN recensione r ON r.id_punto_interesse = pi.id 
		 WHERE pi.id_citta = city.id) AS n_turisti_chiese,
		(SELECT COUNT(*) 
		 FROM punto_interesse pi INNER JOIN museo mus ON pi.id = mus.id
								INNER JOIN recensione r ON r.id_punto_interesse = pi.id 
		 WHERE pi.id_citta = city.id) AS n_turisti_musei,
		(SELECT COUNT(*) 
		 FROM punto_interesse pi INNER JOIN hotel h ON pi.id = h.id
								INNER JOIN recensione r ON r.id_punto_interesse = pi.id 
		 WHERE pi.id_citta = city.id) AS n_tuisti_hotel,
		(SELECT COUNT(*) 
		 FROM punto_interesse pi INNER JOIN recensione r ON r.id_punto_interesse = pi.id 
		 WHERE pi.id_citta = city.id) AS totale_turisti
FROM citta city;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 5:
	Turisti che hanno recensito una chiesa con denominazione "roman_catholic" con voto > 2  negli ultimi 2 anni */

select turista.nickname, recensione.voto, recensione.tempo 
from turista inner join recensione  on turista.id=recensione.id_turista inner join punto_interesse on punto_interesse.id=recensione.id_punto_interesse
inner join chiesa on chiesa.id=punto_interesse.id
where chiesa.denominazione='roman_catholic' and recensione.voto>2 and tempo between 0 and 2;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 6:
	 Turisti che hanno recensito hotel con 4 o 3 stelle con voto maggiore di 3, indicando anche la città di apparteneza dell'hotel */
select turista.nickname, recensione.voto, punto.nome, h.classe, citta.nome
from hotel h inner join punto_interesse punto on punto.id=h.id inner join citta on citta.id=punto.id_citta inner join 
recensione on recensione.id_punto_interesse=punto.id  inner join turista on turista.id=recensione.id_turista
where h.classe ='3 stelle ***' or h.classe='4 stelle ****' and recensione.voto>3;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 7:
	Numero di recensioni per ogni punto d'interesse*/
select punto_interesse.nome, count(recensione.id_punto_interesse) as conteggio from punto_interesse inner join recensione on recensione.id_punto_interesse=punto_interesse.id
group by punto_interesse.nome order by conteggio desc;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 8:
	Percentuale annua di recensioni*/
select count(*)as conteggioAnnuo,Cast((CAST(count(*) as float)/CAST(tab.totalerecensioni as float))*100 as Decimal(13,2))as percentualeAnnua from recensione,
		(select count(*) as totalerecensioni from recensione) as tab
group by recensione.tempo,tab.totalerecensioni ;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 9:
	Numero di turisti che hanno visitato ogni città, divisi per anno*/
select tab3.nomecitta, tab3.totale as totaleturisti,string_agg(tab3.annofa::text,', ') as anni,string_agg(tab3.numeroInAnno::text,', ') as numeroTuristioAllanno from
(select tab2.nomecitta as nomecitta,tab2.totale as totale,tab2.annoFa as annofa ,count(r.tempo) as numeroInAnno
from recensione as r inner join punto_interesse on r.id_punto_interesse=punto_interesse.id inner join citta on citta.id=punto_interesse.id_citta,

(select tab.nomecitta as nomecitta, tab.totale as totale, recensione.tempo as annoFa from recensione,
	
 (select citta.nome as nomecitta, count(*) as totale
	from turista inner join recensione on recensione.id_turista=turista.id inner join punto_interesse on punto_interesse.id=recensione.id_punto_interesse
	inner join citta on citta.id=punto_interesse.id_citta
	group by citta.nome ) as tab
group by tab.nomecitta,tab.totale,recensione.tempo
order by tab.nomecitta)tab2

where r.tempo=tab2.annofa and citta.nome=tab2.nomecitta
group by tab2.nomecitta,tab2.totale,tab2.annoFa) tab3
group by tab3.nomecitta, tab3.totale;

/*    -----------------------------OPPURE EQUIVALENTEMENTE----------------------------------*/

SELECT k.nomecitta, k.totaleturisti, string_agg(k.concat::text, ', ') FROM (select tab3.nomecitta, tab3.totale as totaleturisti,(CONCAT('(AnnoFa: ',tab3.annofa,' )->(NumeroTuristi: ',tab3.numeroInAnno,' )'))
from
(select tab2.nomecitta as nomecitta,tab2.totale as totale,tab2.annoFa as annofa ,count(r.tempo) as numeroInAnno
from recensione as r inner join punto_interesse on r.id_punto_interesse=punto_interesse.id inner join citta on citta.id=punto_interesse.id_citta,

(select tab.nomecitta as nomecitta, tab.totale as totale, recensione.tempo as annoFa from recensione,
	
 (select citta.nome as nomecitta, count(*) as totale
	from turista inner join recensione on recensione.id_turista=turista.id inner join punto_interesse on punto_interesse.id=recensione.id_punto_interesse
	inner join citta on citta.id=punto_interesse.id_citta
	group by citta.nome ) as tab
group by tab.nomecitta,tab.totale,recensione.tempo
order by tab.nomecitta)tab2

where r.tempo=tab2.annofa and citta.nome=tab2.nomecitta
group by tab2.nomecitta,tab2.totale,tab2.annoFa) tab3
group by tab3.nomecitta, tab3.totale,tab3.numeroInAnno,tab3.annofa
) k GROUP BY k.nomecitta, k.totaleturisti;


/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 10:
	  Numero di punti d'interesse per ogni città*/
select citta.nome, count(attrazione_turistica.id) as connteggioattrazione,tab3.conteggiomuseo,tab3.conteggiochiesa,tab3.conteggiohotel 
from attrazione_turistica inner join punto_interesse on attrazione_turistica.id=punto_interesse.id right join citta on citta.id=punto_interesse.id_citta,
	(select citta.nome cittamuseo, count(museo.id) as conteggiomuseo, tab2.cittachiesa,tab2.conteggiochiesa,tab2.conteggiohotel,tab2.cittahotel
	from museo inner join punto_interesse on museo.id=punto_interesse.id right join citta on citta.id=punto_interesse.id_citta,

		(select citta.nome as cittachiesa,count(chiesa.id) conteggiochiesa,tab1.conteggiohotel,tab1.cittahotel 
		 from chiesa inner join punto_interesse on chiesa.id=punto_interesse.id right join citta on citta.id=punto_interesse.id_citta,

			 (select count(hotel.id) conteggiohotel, citta.nome as cittahotel 
			  from hotel inner join punto_interesse on hotel.id=punto_interesse.id right join citta on citta.id=punto_interesse.id_citta
				group by citta.nome 
				) tab1

		where citta.nome=tab1.cittahotel
		group by cittachiesa,tab1.conteggiohotel,tab1.cittahotel) tab2

	where citta.nome=tab2.cittachiesa
	group by citta.nome,tab2.cittachiesa,tab2.conteggiochiesa,tab2.conteggiohotel,tab2.cittahotel) tab3

where citta.nome=tab3.cittamuseo
group by citta.nome,tab3.conteggiomuseo,tab3.conteggiochiesa,tab3.conteggiohotel 
order by tab3.conteggiochiesa desc;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 11:
		PUNTI D'INTERESSI MIGLIORI PER CATEGORIA IN BASE ALLA MEDIA DELLE RECENSIONI*/
SELECT hotel_migliore.nome AS hotel, chiesa_migliore.nome AS chiesa, museo_migliore.nome AS museo, attrazione_migliore.nome	AS attrazione_turistica		
FROM		(SELECT pi.nome AS nome, city.id AS id_comune, AVG(r.voto) AS media_voti
			FROM hotel h INNER JOIN punto_interesse pi ON pi.id = h.id
						 INNER JOIN recensione r ON pi.id = r.id_punto_interesse 
						 INNER JOIN citta city ON city.id = pi.id_citta
			GROUP BY(pi.nome,id_comune)
			ORDER BY media_voti DESC
			LIMIT 1) AS hotel_migliore,

			(SELECT pi.nome AS nome, city.id AS id_comune, AVG(r.voto) AS media_voti
			FROM museo mus INNER JOIN punto_interesse pi ON pi.id = mus.id
						 INNER JOIN recensione r ON pi.id = r.id_punto_interesse 
						 INNER JOIN citta city ON city.id = pi.id_citta
			GROUP BY (pi.nome, id_comune)
			ORDER BY media_voti DESC
			LIMIT 1) AS museo_migliore,


			(SELECT pi.nome AS nome, city.id AS id_comune, AVG(r.voto) AS media_voti
			FROM chiesa ch INNER JOIN punto_interesse pi ON pi.id = ch.id
						 INNER JOIN recensione r ON pi.id = r.id_punto_interesse 
						 INNER JOIN citta city ON city.id = pi.id_citta
			GROUP BY (pi.nome, id_comune)
			ORDER BY media_voti DESC
			LIMIT 1) AS chiesa_migliore,


			(SELECT pi.nome AS nome, city.id AS id_comune, AVG(r.voto) AS media_voti
			FROM attrazione_turistica attr INNER JOIN punto_interesse pi ON pi.id = attr.id
						 INNER JOIN recensione r ON pi.id = r.id_punto_interesse 
						 INNER JOIN citta city ON city.id = pi.id_citta
			GROUP BY (pi.nome, id_comune)
			ORDER BY media_voti DESC
			LIMIT 1) AS attrazione_migliore;


/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 12:
	PERCORSO HOTEL-ATTRAZIONE-CHIESA-MUSEO CONSIGLIATO SULLA BASE DELLA MEDIA DEI VOTI DELLE RECENSIONI PER OGNI CITTA' */
SELECT DISTINCT city.nome AS comune, 
		(SELECT pi.nome
		 FROM punto_interesse pi INNER JOIN hotel h ON h.id = pi.id INNER JOIN recensione r ON r.id_punto_interesse = pi.id
		 WHERE pi.id_citta = city.id
		 GROUP BY pi.nome
		ORDER BY AVG(r.voto) DESC
		LIMIT 1) AS miglior_hotel,
		
		(SELECT pi.nome
		 FROM punto_interesse pi INNER JOIN attrazione_turistica attr ON attr.id = pi.id INNER JOIN recensione r ON r.id_punto_interesse = pi.id
		 WHERE pi.id_citta = city.id
		 GROUP BY pi.nome
		ORDER BY AVG(r.voto) DESC
		LIMIT 1) AS miglior_attrazione, 
		
		(SELECT pi.nome
		 FROM punto_interesse pi INNER JOIN chiesa ch ON ch.id = pi.id INNER JOIN recensione r ON r.id_punto_interesse = pi.id
		 WHERE pi.id_citta = city.id
		 GROUP BY pi.nome
		ORDER BY AVG(r.voto) DESC
		LIMIT 1) AS miglior_chiesa,
		
		(SELECT pi.nome
		 FROM punto_interesse pi INNER JOIN museo mus ON mus.id = pi.id INNER JOIN recensione r ON r.id_punto_interesse = pi.id
		 WHERE pi.id_citta = city.id
		 GROUP BY pi.nome
		ORDER BY AVG(r.voto) DESC
		LIMIT 1) AS miglior_museo
FROM citta city;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/*QUERY 13:
			CITTA' ORDINATE IN BASE AL NUMERO DI RECENSIONI RILASCIATE A PUNTI D'INTERESSE APPARTENTI AD ESSA*/

SELECT ci.nome AS comune, 
						(SELECT COUNT(*) from recensione r INNER JOIN punto_interesse pi ON pi.id = r.id_punto_interesse
						WHERE pi.id_citta = ci.id) AS n_turisti_ricevuti
FROM citta ci
ORDER BY n_turisti_ricevuti DESC;

/*QUERY 14:
			NUMERO DI CHIESE NON CATTOLICHE, NUMERO DI CHIESE CATTOLICHE E TOTALE NUMERO DI CHIESE PER OGNI CITTA'*/
SELECT citta.nome AS comune, (SELECT COUNT(*) 
							  FROM chiesa INNER JOIN punto_interesse ON punto_interesse.id = chiesa.id 
							  WHERE punto_interesse.id_citta = citta.id AND chiesa.denominazione= 'catholic' ) AS chiese_cattoliche,
							  (SELECT COUNT(*) 
							  FROM chiesa INNER JOIN punto_interesse ON punto_interesse.id = chiesa.id 
							  WHERE punto_interesse.id_citta = citta.id AND chiesa.denominazione != 'catholic' ) AS chiese_non_cattoliche,
							  (SELECT COUNT(*) 
							  FROM chiesa INNER JOIN punto_interesse ON punto_interesse.id = chiesa.id 
							  WHERE punto_interesse.id_citta = citta.id) AS total
							  
FROM citta
ORDER BY total DESC;

/*QUERY 15:
		
					città di apparteneza degli hotel con apertura annuale*/

select citta.nome, punto_interesse.nome 
from citta inner join punto_interesse on citta.id=punto_interesse.id_citta inner join hotel on hotel.id = punto_interesse.id
where hotel.apertura='annuale';

