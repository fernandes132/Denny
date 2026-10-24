# CarPlay voor jouw auto's

## Wat daadwerkelijk in dit project zit

De target **Luma-CarPlay** gebruikt dezelfde iPhone-interface plus een `CPTemplateApplicationSceneDelegate`. `Info-CarPlay.plist` registreert de scène onder `CPTemplateApplicationSceneSessionRoleApplication`, met scene class `CPTemplateApplicationScene`. Het afzonderlijke entitlement-bestand bevat `com.apple.developer.carplay-video`. De gewone Luma-target gebruikt deze entitlement niet.

De CarPlay-scène controleert `CPSessionConfiguration.supportsVideoPlayback`. Dit is een capability, **geen actuele parkeerstatus**. Luma probeert geen voertuigsignalen te vervalsen. De systeemroute van CarPlay/AirPlay bepaalt of video op dat moment weergegeven mag worden.

De scène bevat:

1. Een native Apple HLS-teststream, met `CPPlaybackConfiguration(preferredPresentation: .video, ...)` en AVPlayer. Dit is de technische proef voor het native pad, geen YouTube-integratie.
2. Een lijst van je bewaarde YouTube-links (of de startselectie). Selectie zet de gekozen video klaar op de iPhone. Een duidelijke melding zegt dat YouTube-CarPlay-playback nog niet gevalideerd is.
3. Herladen van de bibliotheek na wijzigingen en pauzeren van de native teststream bij verbreken van de verbinding.

## Wat nog niet bewezen is

De officiële YouTube-webspeler biedt niet automatisch hetzelfde AirPlay-gedrag als AVPlayer met eigen content. `allowsAirPlayForMediaPlayback` is ingeschakeld, maar dat bewijst geen videoroute naar een CarPlay-display. YouTube-streams worden niet uit de speler gehaald. Daarom wordt de bibliotheekselectie niet ten onrechte als afspeelbare native YouTube-video aangemerkt met een video-playbackconfiguration.

Als YouTube de gewenste route niet ondersteunt, kan dit niet eerlijk met alleen extra Swift-code worden opgelost. Dan zijn een officiële providerroute, andere content of een andere productafspraak nodig. De iPhone-app blijft bruikbaar.

## Activering op de MacBook

1. Installeer een actuele Xcode met **iOS 27 SDK** voor de CarPlay-target. De ondergrens van die target is bewust iOS 27, op basis van Apples actuele videoapp-documentatie.
2. Vraag bij Apple het CarPlay-video-entitlement aan voor de eigen Bundle Identifier. Een Personal Team zonder deze rechten is voldoende voor de gewone iPhone-target, maar niet voor CarPlay Video.
3. Selecteer de **Luma-CarPlay**-target en je goedgekeurde Apple-team. Pas de Bundle Identifier aan die in het provisioningprofiel is toegestaan. Het bestaande bestand met de entitlement is geen bewijs van toestemming.
4. Gebruik de officiële CarPlay Simulator en configureer een voertuig met Video in Car. Bouw het schema Luma-CarPlay.
5. Controleer of de app op het CarPlay-startscherm verschijnt. Zonder geschikte auto-/simulatorconfiguratie en rechten hoort dit niet te worden aangenomen.
6. Test eerst de native HLS-stream en de AirPlay-route. Controleer dat het systeem video uitschakelt wanneer video niet beschikbaar is. Noteer iPhone-/iOS-/headunitversie en logs.
7. Test daarna YouTube apart, met een vrij embedbare video en de officiële bediening. Controleer werkelijk bewegend beeld, audio, AirPlay-route en het gedrag bij vertrek. Als dat niet werkt: registreer dit als providerblokkade; schakel niet over op extractie of een onofficiële speler.

## De auto zelf

Je eigen headunit moet CarPlay en de benodigde Video in Car-/AirPlay-functie officieel ondersteunen. Dit project kan een willekeurige Linux- of Android-computer niet veranderen in een gecertificeerde CarPlay-ontvanger. Het OEM-/MFi-traject, headunit-SDK, voertuigsignalen en certificering horen bij het voertuigproject en zijn niet door deze broncode afgehandeld.

Videoweergave voor de bestuurder tijdens het rijden is niet als beschikbare functie geïmplementeerd. De besproken pilot vervangt geen schriftelijke voorwaarden en geen Apple-/providerrechten. Er zijn geen aanvragen of berichten verstuurd namens jou.

## Primaire bronnen — gecontroleerd 24 oktober 2026

- [Apple CarPlay](https://developer.apple.com/carplay/): entitlementaanvraag, auto-integratie en geparkeerde video.
- [WWDC26: Rev up your CarPlay app](https://developer.apple.com/videos/play/wwdc2026/212/): iOS 27-videoapps en vereiste AirPlay-ondersteuning.
- [CarPlay Video entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.carplay-video).
- [supportsVideoPlayback](https://developer.apple.com/documentation/carplay/cpsessionconfiguration/supportsvideoplayback): ondersteuning blijft tijdens de sessie gelijk, beschikbaarheid kan wisselen.
- [Playbackconfiguration](https://developer.apple.com/documentation/carplay/cpplaybackconfiguration): videopresentatie en tijdinformatie.
- [Apple-engineer over presentatie](https://developer.apple.com/forums/thread/831710): systeem probeert video bij beschikbare videopresentatie.
- [YouTube WebView-identiteit](https://developers.google.com/youtube/terms/required-minimum-functionality): baseURL/Referer gebaseerd op werkelijke Bundle Identifier.
