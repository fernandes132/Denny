# Bouwen zonder eigen MacBook

De app kan op een macOS-cloudrunner worden gebouwd. `.github/workflows/iphone-build.yml` bevat de workflow: echte simulatorbuild en XCTest, daarna compilatie voor een fysieke iPhone en een gecontroleerde `Luma-unsigned.ipa` als downloadbaar artifact. Er wordt geen iOS-simulator-app omgedoopt tot iPhone-app.

## Wat nog nodig is om de build te starten

Er is nu geen toegankelijke repository voor dit project. Aanmaken via de aangemelde GitHub-commandoregel is geprobeerd; GitHub weigerde dit met `does not have the correct permissions to execute CreateRepository`. Er is dus **geen cloudbuild gestart en geen IPA gecompileerd**.

Maak op [GitHub een nieuwe privérepository](https://github.com/new), bijvoorbeeld `luma-iphone-pilot`, en geef de repositorylink door in dit gesprek. Zorg dat de GitHub-koppeling deze repository kan benaderen. Deel geen token of wachtwoord. De bron, workflow en scripts zijn al lokaal voorbereid; daarna kunnen we uploaden, de runner starten, logs bekijken en eventuele compilerfouten oplossen.

Als je het zelf uploadt: de inhoud van de map Luma-iPhone hoort direct in de repositoryroot. De workflow moet exact onder `.github/workflows/iphone-build.yml` terechtkomen. Bij een zip of een extra bovenliggende map in de repository start hij niet vanzelf. Open daarna Actions → Build Luma for iPhone → Run workflow. Een eerste push naar main met deze bestanden start hem ook.

## Kosten

Voor een private repository gebruikt een standaardrunner de inbegrepen Actions-minuten en opslag van je GitHub-plan. Gebruik boven dat tegoed kan geld kosten. De workflow heeft een limiet van 30 minuten en bewaart artifacts 7 dagen. Controleer je beschikbare tegoed en stel desgewenst een bestedingslimiet in; de workflow belooft geen onbeperkte gratis builds. [GitHub runnerdocumentatie](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## Gebouwd is nog niet geïnstalleerd

De IPA is bewust **ongetekend**. Apple-inloggegevens staan niet in de workflow. Een iPhone accepteert dit bestand niet door het alleen te downloaden of aan te tikken.

Een route zonder eigen Mac is persoonlijke ondertekening met **AltStore Classic en AltServer op Windows**. Gebruik de [officiële installatie-instructies](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows). Je voert je eigen accountgegevens zelf in bij de betreffende software; niet in dit gesprek of een workflowbestand. Deze route moet nog met de daadwerkelijke Luma-IPA en jouw iOS-versie worden getest. Gratis persoonlijk ondertekende apps verlopen doorgaans na 7 dagen en moeten worden vernieuwd. [AltStore over limieten](https://faq.altstore.io/altstore-classic/your-altstore).

AltStore PAL is een ander product en geen algemene route voor willekeurige ongetekende IPA's. AltStore Classic verleent geen CarPlay-video-entitlement. De cloudbuild gebruikt daarom de gewone iPhone-target. De aparte CarPlay-target en voertuigtoelating blijven afhankelijk van Apple en de auto.

Zonder een eigen Mac én zonder toegang tot een geschikte Windows-computer of ondertekenservice is deze persoonlijke installatieroute nog niet compleet. Je hoeft de app niet in de App Store te zetten, maar een serverbuild alleen vervangt de vereiste ondertekening niet.
