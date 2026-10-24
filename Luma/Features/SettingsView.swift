import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var presentation: PresentationRouter
    @AppStorage("luma.mediaConsent") private var consent = false
    @State private var apiKey = ""
    @State private var feedback: String?
    @State private var confirmClear = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LUMA").font(.title.weight(.heavy)).tracking(2)
                    Text("Meer ruimte voor wat je wilt zien.").foregroundStyle(LumaTheme.muted)
                    Text("iPhone-pilot · versie 1.1").font(.caption).foregroundStyle(LumaTheme.muted)
                }.padding(.vertical, 10)
            }
            Section {
                Toggle("YouTube-media laden", isOn: $consent)
                Text("Afbeeldingen, de speler en online zoekresultaten komen van Google/YouTube. Je IP-adres en gebruik kunnen daarbij worden verwerkt. Zonder toestemming blijven je links beschikbaar.")
                    .font(.footnote).foregroundStyle(LumaTheme.muted)
                Link("Privacybeleid van Google", destination: URL(string: "https://policies.google.com/privacy")!)
                Link("Gebruiksvoorwaarden van YouTube", destination: URL(string: "https://www.youtube.com/t/terms")!)
                Button("Wis YouTube-webgegevens") { clearWebData() }
            } header: { Text("Privacy") }

            Section {
                SecureField("YouTube Data API-sleutel", text: $apiKey)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Sleutel veilig bewaren") {
                    do { try APIKeyStore.write(apiKey); feedback = apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "De API-sleutel is verwijderd." : "Sleutel opgeslagen in de Sleutelhanger." }
                    catch { feedback = error.localizedDescription }
                }
                Button("Verwijder sleutel", role: .destructive) {
                    do { try APIKeyStore.write(""); apiKey = ""; feedback = "De API-sleutel is verwijderd." }
                    catch { feedback = error.localizedDescription }
                }
                Text("Optioneel: alleen nodig voor vrij zoeken binnen de app. Je kunt zonder sleutel video's openen en bewaren. Beperk je sleutel tot YouTube Data API v3 en deze iOS-app. Gebruik voor een grotere pilot een beheerde backend.")
                    .font(.footnote).foregroundStyle(LumaTheme.muted)
                Link("Open Google Cloud Console", destination: URL(string: "https://console.cloud.google.com/apis/library/youtube.googleapis.com")!)
            } header: { Text("Zoeken op YouTube") }

            Section {
                Label("CarPlay · nog niet op een auto getest", systemImage: "car.side")
                Text("Video op je autoscherm vereist een geschikte auto en activering door Apple. Of YouTube via deze verbinding werkt, moet nog worden getest.")
                    .font(.footnote).foregroundStyle(LumaTheme.muted)
                Button("Test AirPlay-verbinding", systemImage: "airplayvideo") { presentation.sheet = .airPlay }
                Text("Gebruik een Apple-testvideo om de verbinding te controleren. Video op het autoscherm is bedoeld voor parkeerstand.")
                    .font(.footnote).foregroundStyle(LumaTheme.muted)
                Link("Over CarPlay-ondersteuning", destination: URL(string: "https://developer.apple.com/carplay/")!)
            } header: { Text("Voor jouw auto's") }

            Section {
                Link(destination: URL(string: "https://www.ziggogo.tv")!) {
                    Label("Open Ziggo GO", systemImage: "arrow.up.right.square")
                }
                Text("Opent de officiële dienst. Een geschikt abonnement is nodig. Ziggo GO wordt niet in onze eigen speler afgespeeld.")
                    .font(.footnote).foregroundStyle(LumaTheme.muted)
            } header: { Text("Andere diensten") }

            Section {
                LabeledContent("Bewaarde video's", value: String(library.saved.count))
                Button("Wis mijn bibliotheek", role: .destructive) { confirmClear = true }
                Text("Geen account, cloudsync of eigen analytics. Je videolinks blijven lokaal. Verwijderen van je bibliotheek wist je Google- of YouTube-gegevens niet.")
                    .font(.footnote).foregroundStyle(LumaTheme.muted)
            } header: { Text("Jouw gegevens") }
        }
        .scrollContentBackground(.hidden).listRowBackground(LumaTheme.surface)
        .navigationTitle("Instellingen").lumaScreen()
        .onAppear { apiKey = APIKeyStore.read() }
        .onChange(of: consent) { _, allowed in if !allowed { clearWebData() } }
        .alert("Luma", isPresented: Binding(get: { feedback != nil }, set: { if !$0 { feedback = nil } })) {
            Button("OK") { feedback = nil }
        } message: { Text(feedback ?? "") }
        .confirmationDialog("Alle bewaarde links verwijderen?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Wis bibliotheek", role: .destructive) { library.clear() }
            Button("Annuleren", role: .cancel) { }
        }
    }

    private func clearWebData() {
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {
            Task { @MainActor in feedback = "Webgegevens van de ingebouwde speler zijn gewist." }
        }
    }
}
