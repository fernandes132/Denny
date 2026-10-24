# Bouwen zonder eigen MacBook

De app kan op een macOS-cloudrunner worden gebouwd. `.github/workflows/iphone-build.yml` bevat de workflow: echte simulatorbuild en XCTest, daarna compilatie voor een fysieke iPhone en een gecontroleerde `Luma-unsigned.ipa` als downloadbaar artifact. Er wordt geen iOS-simulator-app omgedoopt tot iPhone-app.

## Actuele build

De koppeling is geactiveerd en de bron staat in [fernandes132/Denny](https://github.com/fernandes132/Denny). De [cloudbuild voor iPhone is geslaagd](https://github.com/fernandes132/Denny/actions/runs/40109957438). De [eerste run](https://github.com/fernandes132/Denny/actions/runs/40109194357) bewijst 15 geslaagde native tests; die run eindigde pas bij de daaropvolgende verpakkingscontrole met een fout. Na herstel is alleen de iPhone-build/verpakking herhaald, met ongewijzigde app- en testbronnen.

Download onder Artifacts **Luma-unsigned-iPhone**. De zip bevat de echte `Luma-unsigned.ipa` en `BUILD-INFO.txt`. Het artifact verloopt op 31 oktober 2026. SHA-256 van de IPA: `2ff4d51414547eaec2a234b22368ab7c1b6d70e110cf496f761257ef5bbda283`.

Toekomstige builds: Actions → Build Luma for iPhone → Run workflow. Laat **run_tests** normaal ingeschakeld. Alleen wanneer de exacte app-/testbronnen al geslaagd zijn en uitsluitend de verpakking wijzigt, kan deze optie uit. Een push van appcode naar main start standaard de volledige controle.

## Kosten

Denny is op dit moment openbaar; standaard GitHub-hosted runners voor openbare repositories zijn volgens GitHub gratis. Voor een private repository gebruikt een standaardrunner de inbegrepen Actions-minuten en opslag van je GitHub-plan. Gebruik boven dat tegoed kan geld kosten. De workflow heeft een limiet van 30 minuten en bewaart artifacts 7 dagen. Controleer je beschikbare tegoed en stel desgewenst een bestedingslimiet in; de workflow belooft geen onbeperkte gratis builds. [GitHub runnerdocumentatie](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## Gebouwd is nog niet geïnstalleerd

De IPA is bewust **ongetekend**. Apple-inloggegevens staan niet in de workflow. Een iPhone accepteert dit bestand niet door het alleen te downloaden of aan te tikken.

Een route zonder eigen Mac is persoonlijke ondertekening met **AltStore Classic en AltServer op Windows**. Gebruik de [officiële installatie-instructies](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows). Je voert je eigen accountgegevens zelf in bij de betreffende software; niet in dit gesprek of een workflowbestand. Deze route moet nog met de daadwerkelijke Luma-IPA en jouw iOS-versie worden getest. Gratis persoonlijk ondertekende apps verlopen doorgaans na 7 dagen en moeten worden vernieuwd. [AltStore over limieten](https://faq.altstore.io/altstore-classic/your-altstore).

AltStore PAL is een ander product en geen algemene route voor willekeurige ongetekende IPA's. AltStore Classic verleent geen CarPlay-video-entitlement. De cloudbuild gebruikt daarom de gewone iPhone-target. De aparte CarPlay-target en voertuigtoelating blijven afhankelijk van Apple en de auto.

De gebruiker heeft alleen een iPhone beschikbaar. Daardoor is de hierboven beschreven Windows-installatieroute nu niet uitvoerbaar. Een mogelijke route is TestFlight via een betaald Apple Developer-account, met een apart ondertekende cloudbuild en App Store Connect-configuratie. Die accounttoegang en configuratie zijn nog niet aanwezig; de huidige IPA is daarom nog niet vanaf de iPhone installeerbaar. Je hoeft de app niet in de App Store te zetten, maar een serverbuild alleen vervangt de vereiste ondertekening niet.
