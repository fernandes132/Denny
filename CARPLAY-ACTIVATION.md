# CarPlay activeren — wat nog nodig is

De afzonderlijke CarPlay-target vraagt `com.apple.developer.carplay-video` aan en registreert de juiste CarPlay-scène. De [cloudworkflow is geslaagd](https://github.com/fernandes132/Denny/actions/runs/40111730348) met Xcode 27.1, voor simulator én fysieke iPhones. Het gedownloade resultaat is gecontroleerd op fysieke iOS-arm64-code, iOS 27 minimum en de opgeloste CarPlay-scèneregistratie. Het resultaat heet nadrukkelijk **unsigned candidate**, niet geactiveerde CarPlay-app.

Artifact: [Luma-CarPlay-unsigned-candidate](https://github.com/fernandes132/Denny/actions/runs/40111730348/artifacts/12565944389), verloopt 31 oktober 2026. IPA SHA-256: `148ecf67d8e90d960ce352cabd74dd58de309161ec134170ad8bba653b62045a`.

Een entitlements-bestand in de broncode geeft geen rechten. Apple moet de capability op het Apple Developer-team/App ID activeren. Daarna moeten een geldig provisioningprofiel en de ondertekening dezelfde rechten bevatten. Zonder dat profiel kan persoonlijk sideloaden of TestFlight de beperking niet oplossen. Ook de auto moet de Video in Car-functie ondersteunen.

## Voorbereide aanvraagtekst — niet ingediend

Gebruik de officiële [CarPlay-aanvraag](https://developer.apple.com/contact/carplay/) vanuit het Apple Developer-account van de eigenaar. Dit document is een concept; de eigenaar moet de gegevens, contentrechten en daadwerkelijke AirPlay-ondersteuning bevestigen voordat het wordt ingestuurd.

**Appnaam:** Luma (werktitel).

**Beoogde Bundle ID:** `nl.luma.pilot.carplay` (vervangen door een eigen geregistreerde identifier indien nodig).

**Categorie:** CarPlay Video.

**Beoogd gebruik:** een persoonlijke videobibliotheek en een pilot voor videoweergave in geparkeerde, daarvoor geschikte voertuigen. Het systeembeleid bepaalt wanneer video beschikbaar is; de app vervalst geen parkeerstatus en omzeilt geen beperkingen.

**Huidige implementatie:** native iPhone-interface, CarPlay-lijstsjablonen, gedeelde lokale bibliotheek, capabilitycontrole en een native AVPlayer/AirPlay-test met openbare Apple HLS-testcontent. De standaard iPhone-app gebruikt daarnaast de officiële YouTube-embedded speler.

**Nog te valideren vóór een definitieve aanvraag:** YouTube via de officiële webspeler is niet aangetoond als werkende CarPlay-videoroute. De YouTube-lijst in de kandidaat zet een video alleen klaar op de iPhone. De native teststream is een afzonderlijke technische proef. Dit mag niet als complete, goedgekeurde YouTube-CarPlay-integratie worden gepresenteerd. Eventuele aanvullende content-/providerrechten moeten worden bevestigd.

**Nog door eigenaar in te vullen:** officiële bedrijfs-/ontwikkelaarsnaam, Apple Team ID, contactpersoon, geregistreerde App ID, voertuig-/headunitpartner, ondersteunde uitvoeringen en bewijs van AirPlay-video met de beoogde content.

## Activeringscontrole na toestemming

1. Apple heeft de video-capability voor de juiste Team ID/App ID goedgekeurd.
2. Provisioningprofiel bevat de juiste app-ID, team-ID en video-entitlement.
3. De ondertekende IPA bevat dezelfde goedgekeurde entitlement; deze wordt gecontroleerd bij het maken van een ondertekende build.
4. De app verschijnt op een geschikte CarPlay-configuratie en toont echte video in parkeerstand.
5. YouTube wordt apart op daadwerkelijk beeld en audio getest, niet alleen op een zichtbare link of thumbnail.
6. Geen goedkeuring of voertuigsignaal wordt door een lokale schakelaar nagebootst.

Er is geen Apple-account gekoppeld, aanvraag ingediend of provisioningprofiel ontvangen via dit project.

Bron: [Apple: Requesting CarPlay Entitlements](https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements).
