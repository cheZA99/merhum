# Chatbot kao alternativa recommenderu

Umjesto klasicnog recommendera, sistem nudi AI chatbot asistenta koji porodicama odgovara na
pitanja o procedurama, terminima, grobljima, dzamijama i uslugama, koristeci Groq API i kontekst
izvucen iz baze. Zasebna funkcionalnost projekta je ML predikcija popunjenosti groblja, opisana u
`ml-dokumentacija.md`.

Kod: `MerhumAPI/Services/Chat`.

## Groq API

`GroqService.GetChatResponseAsync()` poziva Groq chat completion API. Model, temperatura i broj
tokena se citaju iz konfiguracije (`Groq:Model`, podrazumijevano `openai/gpt-oss-120b`), a poziv se
salje sa sistemskim promptom, historijom razgovora i novom porukom korisnika. Ako API kljuc/URL
nisu podeseni, poziv ne uspije ili odgovor ne stigne na vrijeme, korisniku se vraca fiksna poruka o
privremenoj nedostupnosti umjesto greske.

## Kontekst iz baze

`ContextBuilderService.BuildContextAsync()` prije svakog upita sastavlja tekstualni kontekst za
prijavljenog korisnika: njegovi osnovni podaci (ime, grad, uloga), dostupna groblja u njegovom
gradu sa brojem slobodnih mjesta i procentom popunjenosti, dzamije i imami, faze procedure,
prosjecne cijene po tipu usluge, njegove aktivne procedure (`Deceased`) i predstojeci termini u
sljedecih 7 dana. Taj kontekst se ubacuje u sistemski prompt, tako da chatbot odgovara samo na
osnovu stvarnih podataka iz baze, a ne izmisljenih informacija.

## Historija razgovora

`ChatService.SendMessageAsync()` prije poziva Groq API-ja iz `ChatLog` tabele ucitava zadnjih 5
parova poruka (korisnik/asistent) tog korisnika i salje ih kao dio konverzacije, tako model ima
kontekst prethodnih poruka u razgovoru. Poslije odgovora se poruka, odgovor asistenta i (skraceni)
kontekst iz baze cuvaju kao novi red u `ChatLog`, vezan za `UserId`.

## Veza sa prijavljenim korisnikom

`ChatController` (`/api/chat/*`) je zasticen sa `[Authorize]`, a `UserId` se uzima iz JWT claimova
(`ClaimTypes.NameIdentifier` / `sub`), ne iz parametra koji bi klijent mogao mijenjati. Slanje
poruke, citanje historije (`GET /api/chat/history`) i njeno brisanje (`DELETE /api/chat/history`)
rade uvijek nad zapisima tog korisnika.

## Mobilni ekran

Family korisnici imaju ekran za chat (`chat_screen.dart`) sa listom poruka, brzim akcijama
(npr. "Koja groblja su dostupna?", "Kako zakazati termin?"), indikatorom da asistent kuca i
mogucnoscu brisanja cijelog razgovora. Ekran koristi `ChatProvider` i `ChatService`
(`chat_service.dart`), koji poziva `/api/chat/message` za slanje poruke i `/api/chat/history` za
ucitavanje i brisanje historije.
