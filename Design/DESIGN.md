# Luma — ontwerp

Visuele specificatie: `Concept.png`. Native SwiftUI, iPhone-first. Geen website of App Store-publicatie.

Tokens: achtergrond #0B1017; oppervlak #141D28; tekst #F4F3EE; secundair #96A4B5; accent #D5FB77. SF Pro via systeemfont, SF Symbols. Goot 20 pt, 8/12/16/24/32 spacing; media 20 pt radius, bediening minimaal 44 pt. Grote titel 34 pt bold, sectie 22 pt, body 17 pt. Alle tekst schaalt via Dynamic Type. Native tabbar en navigatie.

Gerichte verbeteringen in 1.1: lokale collectie vóór de toestemmingsuitleg zodat het eerste scherm al eigen beeld toont zonder externe requests; compacte bibliotheekmenu's; verticale videorijen bij toegankelijkheidstekst; duidelijke disabled-knoppen; zichtbare actie voor geplakte links en een laadstatus onder de player. Het bestaande palet en de schermstructuur blijven de ontwerpbron. Dit zijn bronwijzigingen; native visuele verificatie blijft open.

Schermen: Ontdekken (woordmerk, toevoegen, titel, zoekveld, filters, collectiebeeld, echte YouTube-links), Bibliotheek (bewaarde links, zoeken, verwijderen), Instellingen (privacy, sleutel, Ziggo, CarPlay-status), detail (officiële player, bewaren, extern openen, bron), toevoegen (linkvalidatie), toestemming (geen externe requests voor akkoord).

Bewuste functionele afwijkingen van concept: categorieën Film/Ruimte/Tech passen bij geverifieerde startlinks; geen verzonnen documentairetitels, duur of kijkcijfers. Hero is collectiebeeld, geen videothumbnail. Player krijgt minimaal 200 pt hoogte; 16:9 zou op kleine iPhones te laag worden. Extra privacy-, fout-, API-instellingen en CarPlay-status zijn nodig voor eerlijke functionaliteit.

Verificatiegrens: deze Linux-omgeving heeft geen Xcode, iOS Simulator of SwiftUI renderer. Een browsernabootsing bewijst geen native rendering; daarom geen nagebootste browser-screenshot als bewijs. Native visuele en playback-QA op een Mac/iPhone blijft expliciet open. Geen 10/10-fidelityclaim zonder die controle.
