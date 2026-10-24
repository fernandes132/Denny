# Gerichte verificatie

## Uitgevoerd in Linux

De precieze uitkomst staat in `VERIFICATION.txt`. Broncontrole is geen Apple SDK-build. Geen iPhone- of CarPlay-playback geclaimd.

## Uit te voeren op Mac/iPhone

1. Open Luma.xcodeproj, schema Luma. Simulatorbuild en XCTest moeten slagen. Kies daarna je eigen team en echte iPhone, bouw opnieuw.
2. Eerste start: er worden geen YouTube-thumbnails of spelers geladen vóór YouTube is ingeschakeld. Ontdekken, Bibliotheek en Instellingen blijven navigeerbaar.
3. Voeg `https://youtu.be/aqz-KE-bpKQ` toe met eigen titel. Controleer bewaren, herstart, zoeken, delen en verwijderen. Dubbele link geeft een melding. Kanaal-, playlist- en nep-hostlinks worden geweigerd.
4. Geef mediatoestemming. Open een startvideo; controleer werkelijk beeld, pauze, zoeken in tijd, fullscreen en officiële YouTube-bediening. Controleer de minimumplayerhoogte in portret en landschap. Laat de app achtergrond/voorgrond gaan: geen automatische hervatting van YouTube.
5. Schakel internet uit. Wacht op timeout; foutmelding en Open in YouTube blijven beschikbaar. Herstel verbinding en druk opnieuw proberen.
6. Test verwijderde/private/embedding-geblokkeerde video's. Native melding staat onder de speler en bedekt nooit YouTube-knoppen.
7. Zonder API-sleutel: lokale zoekresultaten en extern zoeken werken. Met een echte beperkte sleutel: zoek via Enter, wijzig zoekterm tijdens een request, test quotafout, ongeldige sleutel en wissen van de query. Oude resultaten mogen de nieuwe zoekopdracht niet overschrijven.
8. Trek toestemming in: bestaande thumbnails/player verdwijnen uit Luma; webdata kan worden gewist. Geen nieuwe API-zoekopdracht mag starten.
9. Open Ziggo GO: officiële dienst opent; geen fictieve ingebouwde speler.
10. VoiceOver: tabnamen, toevoegen, bewaren, verwijderen en zoekveld herkenbaar. Grootste Dynamic Type en kleinere iPhone testen; scroll blijft mogelijk. Reduce Motion respecteren (geen verplichte animatie).
11. Bibliotheek wissen vraagt bevestiging; de API-sleutel verwijderen niet alleen verbergen maar daadwerkelijk uit Sleutelhanger verwijderen. Een bibliotheekreset wist niet de provideraccounts.
12. Native AirPlay-test: start Apple-stream handmatig, kies route, test pauze en sluiten, verlies internet en verbind opnieuw. Een vast frame of MPNowPlaying-metadata is geen bewijs van playback.
13. CarPlay: volg CARPLAY.md op geschikte simulator en auto, inclusief wegvallen van video-beschikbaarheid. Scheid native-streamsucces van YouTube-succes in het verslag.
14. Start een trage zoekopdracht en dien meteen een nieuwe in. De late eerste reactie mag de nieuwste resultaten niet vervangen. Verlaat een lopende zoekopdracht en keer terug: geen achtergebleven spinner of fictieve resultaatstatus.
15. Kies Film, voer vervolgens een titel uit Tech in: de lokale zoekopdracht doorzoekt alle categorieën. Plak een link en controleer de zichtbare Open-knop. Zonder sleutel moet Enter de officiële YouTube-zoekpagina openen.
16. Open Toevoegen, de collectie of de AirPlay-test en selecteer tegelijkertijd een YouTube-link via CarPlay. Het bestaande scherm mag niet verdwijnen; de laatste selectie verschijnt nadat het scherm gesloten is en de iPhone-app actief is.
17. Open alleen de AirPlay-test zonder Start aan te raken: geen teststream wordt voorbereid. Start, pauzeer, sluit en open YouTube. De vorige native test mag de mediaknoppen of audiosessie niet overnemen. Probeer na een mislukte teststream opnieuw: een nieuw item moet laden.
18. Verander naar de grootste toegankelijkheidstekst. Videorijen worden verticaal en titels blijven leesbaar. Open het toevoegformulier met lege link: de bewaar-knop is zichtbaar uitgeschakeld. Na correctie van een foute link verdwijnt de oude foutmelding.

## Visuele controle op de Mac

Gebruik `Design/Concept.png` als richting. Vergelijk echte iPhone-screenshots met het concept: (1) midnight-achtergrond en lime-accent, (2) grote titel en SF-hiërarchie, (3) 20pt-goten en ruime touch targets, (4) mediaframe en eigen collectiebeeld, (5) tabbar en bronvermelding, (6) detailhiërarchie en vrije officiële player. Geen native screenshot is hier geproduceerd; visuele overeenkomst is nog niet bewezen.

Bewuste afwijkingen: werkelijke startlinks in plaats van verzonnen video's; collectie heeft beeld boven tekst in plaats van tekst op het beeld voor betere schaalbaarheid; aanvullende privacy- en foutschermen; playerhoogte minimaal 220 pt; API-sleutel optioneel. Deze zijn vastgelegd in DESIGN.md. Above-the-fold copy bevat op eerste start een extra toestemmingspaneel; geen claim van pixelidentieke uitvoering.
