# Merhum

Aplikacija za organizaciju dzenaza i smrtovnice. Sadrzi REST API, worker servis, desktop (admin)
i mobilnu aplikaciju.

## Tehnologije

.NET 8 API, EF Core, SQL Server, Identity + JWT, RabbitMQ + MassTransit, Flutter (desktop i mobilni).
Chatbot koristi Groq, predikcija popunjenosti groblja ML.NET, placanje PayPal sandbox.

## Tajne

Tajne nisu u repou nego u `.env` fajlu u korijenu projekta. Raspakuj `.env-tajne.zip` (sifra je
na DL sistemu) i dobijeni `.env` ostavi u root, pored `docker-compose.yml`. Primjer kljuceva je
u `.env.example`.

## Backend (Docker)

```
docker compose -f docker-compose.yml up --build
```

Podize SQL Server, RabbitMQ, API i Worker. Baza se pri prvom pokretanju sama kreira i napuni
test podacima. API je na http://localhost:5000/swagger, RabbitMQ na http://localhost:15672 (guest/guest).

## Desktop

```
cd merhum_desktop
flutter pub get
flutter run -d windows
```

API je podesen na `localhost:5000`.

## Mobilni

```
cd merhum_mobile
flutter pub get
flutter run
```

API je podesen na `10.0.2.2:5000` (Android emulator). Build APK-a: `flutter build apk --release`.

## Kredencijali

Sve lozinke su `test`.

| Korisnicko ime | Uloga |
|----------------|-------|
| desktop | Administrator |
| mobile | Porodica |
| korisnik | JavniKorisnik |
| imam | Imam |
| pogrebnopreduzece | PogrebnoPreduzece |
