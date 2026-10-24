# Luma voor iPhone

Een native SwiftUI-app met YouTube als hoofdonderdeel. Donkerblauw, grote beelden, limoengroene accenten en Nederlandse bediening. Geen App Store-publicatie, geen externe Swift-packages en geen server nodig voor de basisfuncties.

## Verbeteringen in 1.1

Enter in het zoekveld opent zonder sleutel nu rechtstreeks de officiële YouTube-zoekpagina; een geplakte videolink heeft bovendien een zichtbare Open-knop. Een apart zoekmodel voorkomt dat een oude of geannuleerde aanvraag een nieuw resultaat overschrijft. Bij verlaten van een lopende zoekopdracht verdwijnt ook de laadstatus. Zoeken in de startselectie doorzoekt alle categorieën, ook als er eerder een filter gekozen was.

De collectie en AirPlay-test gebruiken nu dezelfde modale presenter als Toevoegen. Een CarPlay-selectie wacht tot het bestaande scherm gesloten is en de iPhone-app op de voorgrond staat. De native test laadt pas een stream na Start, biedt pauzeren en herstelt een mislukte stream bij opnieuw starten. Mediaknoppen voor de test worden verwijderd zodra die sessie eindigt, zodat ze YouTube niet overnemen.

De bibliotheek heeft compacte optiemenu's; videorijen schakelen bij toegankelijkheidstekst over naar een verticale indeling. Uitgeschakelde knoppen zijn zichtbaar gedimd. De player heeft een laadmelding onder het videovlak, wist oude fouten na succesvol laden en biedt herstel wanneer het WebKit-proces stopt. API-fouten onderscheiden nu quota, sleutelbeperkingen, niet-geactiveerde API, timeout en onleesbare antwoorden. Titels worden deterministisch één keer gedecodeerd, inclusief Unicode-entities.

## Op je MacBook openen

Heb je nog geen MacBook? De [cloudbuild-route](CLOUD-BUILD.md) gebruikt GitHub Actions op macOS. De workflow heeft een echte iPhone-IPA opgeleverd in [Denny](https://github.com/fernandes132/Denny/actions/runs/40109957438). De 15 native tests zijn geslaagd in [de eerste run](https://github.com/fernandes132/Denny/actions/runs/40109194357); alleen de verpakking moest daarna worden hersteld. Installatie vereist daarna persoonlijke ondertekening; er is ook een mogelijke Windows-route beschreven.

1. Pak de volledige zip uit op je MacBook. Bewaar de mapstructuur.
2. Installeer Xcode vanuit de Mac App Store en open Xcode eenmaal om de extra onderdelen te installeren. Voor de gewone iPhone-build volstaat een Xcode-versie met iOS 17 SDK of nieuwer; gebruik bij voorkeur de actuele stabiele Xcode.
3. Open **Luma.xcodeproj**. Je hoeft geen project te genereren of pakketten te installeren.
4. Kies bovenaan het schema **Luma** en een iPhone-simulator. Druk op Run (⌘R).
5. Voor je echte iPhone: verbind met een kabel, vertrouw de Mac en schakel indien gevraagd Ontwikkelaarsmodus in op de iPhone. Kies je iPhone als bestemming.
6. Selecteer project → target **Luma** → **Signing & Capabilities** → **Automatically manage signing**. Voeg je Apple-account toe bij Team. Wijzig `nl.luma.pilot` naar een eigen unieke Bundle Identifier als Xcode daar om vraagt. De speler leidt zijn app-identiteit automatisch af van die identifier.
7. Druk opnieuw op Run. Je Apple-wachtwoord of certificaat hoeft nooit aan ons te worden gegeven.

Met een gratis Personal Team kun je persoonlijk testen zonder App Store. De installatie/provisioning verloopt doorgaans na zeven dagen; bouw en installeer dan opnieuw. Dit is geen blijvende distributieroute voor een wagenpark. [Apple over Personal Teams](https://developer.apple.com/help/account/basics/about-your-developer-account).

**Open eerst het schema Luma.** Het aparte schema Luma-CarPlay vereist andere rechten en een nieuwere SDK; het staat er bewust naast zodat het je persoonlijke iPhone-installatie niet blokkeert.

## Wat is geïmplementeerd?

- Ontdekken met categorieën en een eigen vormgegeven collectie.
- Officiële YouTube IFrame-speler in WKWebView, met de oorspronkelijke bediening en advertenties.
- YouTube-links, Shorts-/live-links en losse video-ID's toevoegen; geen playlists.
- Lokaal bewaren, verwijderen, zoeken in de bibliotheek en delen.
- Je eigen titel meegeven aan een link; geen nep-kijkcijfers of verzonnen videoduur.
- Toestemming vóór externe YouTube-afbeeldingen, player of API-zoekopdrachten worden geladen.
- Netwerk-/playerfouten, opnieuw proberen en altijd rechtstreeks openen in YouTube.
- Optioneel zoeken via YouTube Data API v3 met je eigen sleutel in de iOS Sleutelhanger.
- Een knop naar de officiële Ziggo GO-website. Geen ingebouwde Ziggo-speler.
- Aparte CarPlay-scène met gedeelde bibliotheek en native AirPlay-testpad; zie CARPLAY.md voor de harde beperkingen.

## Zoeken zonder en met API-sleutel

Zonder sleutel kun je de startselectie en bewaarde links doorzoeken, eigen videolinks openen en op de knop **Zoek verder op YouTube** drukken. Die laatste opent YouTube buiten Luma. Afspelen van een link via de officiële embed heeft geen Data API-sleutel nodig, maar blijft afhankelijk van YouTube, het netwerk en toestemming van de maker.

Voor vrije zoekresultaten *in Luma*: maak een Google Cloud-project, activeer **YouTube Data API v3**, maak een API-sleutel en plak die in Instellingen. Beperk de sleutel tot deze API en, waar ondersteund, je eigen iOS Bundle Identifier. Test die beperkingen op het echte apparaat. De app stuurt de identifier mee als `X-Ios-Bundle-Identifier`. Google kan aanvullende quota-/compliancecontroles verlangen. Een sleutel is niet meegeleverd en er is geen account voor je aangemaakt.

Zoeken gebeurt pas op Enter of een zoekknop, niet bij iedere toetsaanslag. Oude zoekopdrachten worden geannuleerd. API-resultaten worden niet als centrale zoekcache opgeslagen. Bewaarde metadata uit zoekresultaten wordt na 29 dagen bij laden/activeren verwijderd; de link blijft. Een eigen backend met rate limiting is aangewezen voordat je sleutels over een grotere pilot verspreidt. Een mobiele app kan een eigen beheerderssleutel nooit volledig geheim houden.

## CarPlay — lees dit vóór je test

Dit project is **geen reeds toegelaten of op een echte auto gevalideerde CarPlay-videoapp**. Er is wel een afzonderlijke target, scene delegate, entitlement-bestand en native testspeler geïmplementeerd. Volg CARPLAY.md. De YouTube-linkselectie in CarPlay selecteert de video op de iPhone; ze doet geen belofte dat de YouTube-webspeler als AirPlay-video op het autoscherm verschijnt. Daarvoor is een hardware-/providerproef vereist. De native Apple-teststream is een afzonderlijk testpad.

## Techniek

- iOS 17+, Swift 5 taalmodus, SwiftUI, WebKit, AVKit, Security/Keychain.
- `Luma/App`: app shell en design tokens.
- `Luma/Core`: links, bibliotheek, API-client en Sleutelhanger.
- `Luma/Features`: schermen en formulieren.
- `Luma/Player`: officiële embed en afzonderlijke native testspeler.
- `Luma/CarPlay`: optionele integratie voor iOS 27 SDK.
- `LumaTests`: XCTest voor linkvalidatie, opslag, metadata-expiry, API-antwoorden, concurrerende zoekopdrachten en modale CarPlay-selecties.
- `Design/Concept.png`: het gegenereerde ontwerp, **geen screenshot van een draaiende app**.

Geen advertenties blokkeren, geen YouTube-audio loshalen, geen achtergrond-YouTube-audio of videodownloads. Geen Netflix-integratie in deze versie.

## Controles uitvoeren

Op macOS, in deze map:

```bash
bash scripts/check_on_mac.sh
```

Dit bouwt de iPhone-app voor de simulator en voert XCTest uit op een beschikbare iPhone-simulator met iOS 17+. Met een iOS 27 SDK wordt ook de CarPlay-target tegen die SDK gebouwd. Dat laatste is een compilatiecontrole, geen entitlementgoedkeuring of bewijs van afspelen in een auto. Voor dit script is `python3` nodig; er worden geen dependencies geïnstalleerd.

Of voer de stappen handmatig uit:

```bash
xcodebuild -list -project Luma.xcodeproj
xcodebuild -project Luma.xcodeproj -scheme Luma -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcrun simctl list devices available
```

Kies vervolgens een simulator-ID uit de lijst:

```bash
xcodebuild -project Luma.xcodeproj -scheme Luma -destination 'platform=iOS Simulator,id=JOUW-SIMULATOR-ID' CODE_SIGNING_ALLOWED=NO test
```

Of gebruik Product → Test (⌘U) in Xcode. De optionele Linux/CI-broncontrole gebruikt `python3 scripts/verify_source.py` en `node scripts/test_player.mjs`.

## Verificatiestatus

**24 oktober 2026: daadwerkelijk gebouwd met Xcode 26.6 / iOS SDK 26.5 op GitHub macOS.** De simulatorbuild en alle 15 XCTest-tests slaagden (0 failures). Ook de Release-build voor fysieke iPhones slaagde. Na herstel van de argumentvolgorde in de `lipo`-controle is de ongetekende IPA succesvol verpakt en als artifact opgeslagen.

- [Tests, broncommit 0b609db](https://github.com/fernandes132/Denny/actions/runs/40109194357): native tests geslaagd; deze run eindigde door de latere verpakkingsfout met failure.
- [Geslaagde iPhone-verpakking, broncommit 1836ed1](https://github.com/fernandes132/Denny/actions/runs/40109957438): iPhone-build en packaging success. De app-, project- en testbronnen zijn identiek aan de geteste commit; alleen buildscript/workflow wijzigden. Daarom zijn de native tests niet herhaald.
- [Download buildartifact](https://github.com/fernandes132/Denny/actions/runs/40109957438/artifacts/12566112435), bewaartermijn tot 31 oktober 2026.

De gedownloade echte IPA is aanvullend gecontroleerd op ZIP-integriteit, `Payload/Luma.app`, arm64 Mach-O met fysieke iOS-platformcode, iOS 17 minimum en overeenkomende SHA-256. De app is **niet ondertekend of op een echte iPhone geïnstalleerd**. Handmatige UI/VoiceOver/playback, YouTube met een echte sleutel en CarPlay/AirPlay op hardware zijn nog niet gevalideerd. De CarPlay-target is niet tegen iOS 27 gebouwd: deze runner heeft SDK 26.5.

Voor installatie met alleen een iPhone is een aparte onderteken-/distributieroute nodig, bijvoorbeeld TestFlight met een betaald Apple Developer-account. Deze build publiceert niets in de App Store en creëert geen Apple-account. Zie CLOUD-BUILD.md en QA.md.

## Privacy en inhoud

Geen eigen accounts of analytics. Voorkeuren en bewaarde links staan lokaal in UserDefaults; je optionele API-sleutel staat in de Sleutelhanger. Google/YouTube verwerkt gegevens zodra je zijn media inschakelt of extern opent. Een privacy-enhanced embed betekent geen volledige anonimiteit. De app maakt geen AVG-/ATT-goedkeuringsclaim; beoordeel dit opnieuw voordat de pilot wordt verspreid.

De collectieafbeelding en het icoon zijn gegenereerde assets. Videothumbnails worden van YouTube geladen en blijven van de betreffende rechthebbenden. De startselectie bevat links, geen meegeleverde kopieën van films.
