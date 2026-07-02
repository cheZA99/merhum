# Predikcija popunjenosti groblja

Umjesto klasicnog recommendera, sistem koristi model masinskog ucenja koji za svako groblje
procjenjuje za koliko mjeseci ce biti popunjeno i koji je ocekivani datum popunjenja.

## Algoritam

Koristi se regresija (FastTree iz ML.NET biblioteke). Model uci vezu izmedu stanja groblja i
broja mjeseci do popunjenja, pa tu vrijednost predvidi za novo stanje.

Kod: `MerhumAPI/Services/MachineLearning`.

## Ulazni podaci (features)

Model gleda cetiri podatka o groblju:

- ukupan kapacitet (broj mjesta)
- trenutna popunjenost (zauzeta mjesta)
- procenat popunjenosti
- prosjecan broj ukopa mjesecno

Sva cetiri se stvarno koriste u treniranju i predikciji.

Prosjecan broj ukopa se racuna iz stvarnih termina koji su oznaceni kao odrzani (`Held`), i to za
zadnjih 12 mjeseci. Ako u zadnjih godinu dana nema podataka, uzima se cijeli period da procjena ne
bi bila prazna.

## Podaci za treniranje

Trening skup se pravi iz dva izvora:

- stvarni podaci iz baze (samo groblja koja imaju iskoristiv broj ukopa)
- sinteticki podaci (dodatni redovi generisani po logici kapacitet / stopa ukopa, sa malo suma)

Sinteticki podaci se dodaju jer u bazi nema dovoljno stvarnih groblja da model sam nauci obrazac.
Podaci se dijele na trening i test dio (80/20), a rezultat (R2 i RMSE) se loguje.

Model se trenira dugmetom "Treniraj model" na Predictions ekranu, ili automatski pri prvom upitu
ako jos nije treniran. Istrenirani model se cuva u `model.zip`.

## Objasnjivost

Korisniku se ne prikazuje samo broj mjeseci, nego i podaci na osnovu kojih je procjena napravljena:
kapacitet, trenutna popunjenost, procenat popunjenosti i prosjecan broj ukopa mjesecno. Tako je
jasno zasto je za jedno groblje procjena kratka (visoka popunjenost i vise ukopa), a za drugo duga.

Uz procjenu se prikazuje i pouzdanost, koja zavisi od toga koliko stvarnih ukopa groblje ima u
historiji:

- Visoka: 10 ili vise
- Srednja: 3 do 9
- Niska: manje od 3

Sto je vise stvarnih podataka, procjena je pouzdanija.
