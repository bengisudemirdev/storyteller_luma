import SwiftUI

struct PoliciesDetailView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LumaTheme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        coreProtocolSection
                        ageAdaptationSection
                        safetySection
                        riskHandlingSection
                        parentSupportSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Güvenli Hikâye Politikaları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Olia’da güvenli hikâye deneyimi")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(LumaTheme.text)
            Text("Temel protokolümüz: **ebeveyn destekli, yaşa uyarlanmış, güvenli hikâye deneyimi**.")
                .font(.subheadline)
                .foregroundColor(LumaTheme.secondaryText)
        }
    }

    private var coreProtocolSection: some View {
        policyCard(
            title: "1. Temel Protokol",
            icon: "heart.text.square.fill",
            color: LumaTheme.lavender,
            lines: [
                "Her masal, çocuğun seçilen yaş grubuna göre dil, uzunluk ve duygu yoğunluğu açısından uyarlanır.",
                "Masallar sıcak, güvenli, yargılayıcı olmayan ve destekleyici bir tonda yazılır.",
                "Hiçbir hikâye, çocuğu korku, suçluluk veya utanç duygusuyla baş başa bırakmaz.",
                "Her hikâyenin sonu sakinleştirici, umut verici veya mutlu olacak şekilde tasarlanır."
            ]
        )
    }

    private var ageAdaptationSection: some View {
        policyCard(
            title: "2. Yaşa Uyarlanmış Hikâyeler",
            icon: "figure.and.child.holdinghands",
            color: LumaTheme.softBlue,
            lines: [
                "3–5 yaş: Çok basit, kısa, tekrar eden, düşük gerilimli ve tamamen güvenli hikâyeler.",
                "6–8 yaş: Küçük maceralar, basit sorun–çözüm yapısı ve hızlıca gelen güvenli çözümler.",
                "9–11 yaş: Biraz daha katmanlı ama hâlâ çocuk dostu, umutlu ve duygusal olarak düzenlenmiş hikâyeler.",
                "Her yaş grubunda, hikâye karmaşıklığı ve gerilim seviyesi ayrı ayrı sınırlandırılır."
            ]
        )
    }

    private var safetySection: some View {
        policyCard(
            title: "3. Güvenlik ve Sınırlar",
            icon: "shield.checkered",
            color: .blue,
            lines: [
                "Şiddet, işkence, ölüm, kan, ağır ceza, intikam ve benzeri temalar hikâyelere alınmaz.",
                "Korku, karanlık atmosfer, kaybolma ve yalnızlık gibi hassas temalar, gerekirse çok yumuşatılarak ve hızlıca güvenli bir çözüme bağlanır.",
                "Çocuk karakter asla aşağılanmaz, suçlanmaz veya çaresiz bırakılmaz.",
                "Hikâyelerde suçluluk, utanç ve aşağılanma yerine; anlama, öğrenme ve onarma vurgulanır."
            ]
        )
    }

    private var riskHandlingSection: some View {
        policyCard(
            title: "4. Riskli İsteklere Yaklaşım",
            icon: "exclamationmark.triangle.fill",
            color: .orange,
            lines: [
                "Aile veya çocuk çok karanlık, ürkütücü veya cezalandırıcı temalar talep etse bile, bu istekler doğrudan takip edilmez.",
                "Sistem, bu tür istekleri daha yumuşak, güvenli ve çocuk dostu alternatiflere dönüştürür.",
                "Örneğin, ‘korkunç canavar’ hikâyesi, sonunda dost ve yanlış anlaşılan bir karaktere dönüşebilir.",
                "Amaç; hayal gücünü korurken, duygusal güvenliği daima en önde tutmaktır."
            ]
        )
    }

    private var parentSupportSection: some View {
        policyCard(
            title: "5. Ebeveyn Destekli Deneyim",
            icon: "person.2.fill",
            color: .green,
            lines: [
                "Olia, masalların çoğunlukla ebeveyn–çocuk birlikte okunduğunu varsayar.",
                "Hikâyeler, duygular üzerine konuşmayı kolaylaştıracak şekilde sade ve anlaşılır yazılır.",
                "Hedefimiz; çocuğun duygularını fark etmesine, kendini güvende hissetmesine ve ebeveyniyle bağ kurmasına yardımcı olmaktır.",
                "Her hikâye, sonrasında kısa bir sohbet ve sarılma için uygun, yumuşak bir tonda biter."
            ]
        )
    }

    private func policyCard(title: String, icon: String, color: Color, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(LumaTheme.text)
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(lines, id: \.self) { line in
                    Text("• \(line)")
                        .font(.caption)
                        .foregroundColor(LumaTheme.secondaryText)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(18)
        .shadow(color: LumaTheme.softShadow, radius: 8, x: 0, y: 3)
    }
}

