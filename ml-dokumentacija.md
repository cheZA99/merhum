# Predikcija popunjenosti groblja

Sistem koristi model masinskog ucenja koji za svako groblje procjenjuje za koliko mjeseci ce biti
popunjeno i koji je ocekivani datum popunjenja. Ovo je zasebna prijavljena funkcionalnost projekta,
odvojena od chatbot asistenta (vidi `recommender-dokumentacija.md`).

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

Prosjecan broj ukopa se racuna iz stvarnih termina koji su oznaceni kao odrzani (`Held`). Prozor
posmatranja je zadnjih 12 mjeseci, ali ako groblje ima krace historije, dijeli se sa stvarnim
brojem mjeseci od prvog ukopa do danas. Time se izbjegava da groblje sa tri mjeseca podataka
ispadne cetiri puta sporije nego sto jeste.

## Podaci za treniranje

Trening skup se gradi iz historije ukopa u bazi. Jedan red nije jedno groblje, nego **jedno groblje
u jednom mjesecu svoje historije**. Za groblje sa dvije godine ukopa nastane oko 23 reda, pa mali
broj grobalja ipak daje iskoristiv skup.

Za svaki takav mjesec `m`:

- feature `AverageBurialsPerMonth` je stopa ukopa **prije** mjeseca `m`
- ostali featurei opisuju stanje groblja u mjesecu `m` (kapacitet, popunjenost, procenat)
- popunjenost u mjesecu `m` se rekonstruise tako da se od danasnje popunjenosti oduzmu ukopi
  koji su se desili poslije `m`

### Kako nastaje target

Target `MonthsUntilFull` se racuna kao slobodna mjesta u mjesecu `m` podijeljena sa stopom ukopa
koja je **stvarno uslijedila poslije** `m`. To je bitna razlika: target ne dolazi iz istog broja
koji je vec dat kao feature. Da dolazi, model bi samo naucio dijeljenje koje je kod sam izracunao.
Ovako model uci da iz trenutnog stanja i dosadasnje stope procijeni kako ce se groblje stvarno
puniti, a to je stvaran problem predikcije.

### Sinteticki podaci

Sinteticki redovi se dodaju samo ako historija ne daje ni minimalnih 10 redova, i to tacno onoliko
koliko nedostaje do tog minimuma. Nikad se ne dodaje fiksnih 200 redova i ne mogu nadglasati
stvarne podatke.

### Podjela i evaluacija

Test skup se uzima **iskljucivo iz stvarnih redova** (20% njih), dok trening skup cini ostatak
stvarnih plus eventualni sinteticki redovi. Time R2 i RMSE mjere kako model radi na stvarnoj
historiji, a ne koliko dobro pogada vlastiti generator. Ako stvarnih redova ima manje od pet,
evaluacija se preskace i to se zapise u log umjesto da se prijavi neupotrebljiva ocjena.

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
