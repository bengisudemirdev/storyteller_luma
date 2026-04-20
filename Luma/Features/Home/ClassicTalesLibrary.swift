import Foundation

/// Kamuya açık halk masalı geleneğine dayanan özgün Türkçe anlatımlar (Grimm, Perrault, Andersen rivayetleri ve Türk sözlü geleneği).
/// Ana liste `GET /v1/classic-tales` ile gelir; `bundledTales` yalnızca çevrimdışı / yedek.
/// Şiddet ve korku unsurları uyku öncesi kullanım için yumuşatılmıştır.
/// Tam metin, kapak üretimi seed’i ile hizalı tutulmalı: `luma-backend/scripts/classic-tales-full-stories.ts`.
struct ClassicTaleItem: Identifiable, Hashable {
    /// Sunucudaki kalıcı slug (`taleId`); ses önbelleği ve kapak yolu için anahtar.
    let id: String
    let title: String
    let tag: String
    /// Olia kapak şablonu (liste ve önizleme kartlarında kullanılır).
    let coverTemplate: StoryCoverTemplateType
    /// Kart altı, tek satırlık davet
    let teaser: String
    /// Okunacak tam masal metni
    let fullStory: String
    /// Edebî kaynak notu (bilgilendirme)
    let attribution: String
    /// `GET /v1/classic-tales` / `GET /v1/classic-tales/{taleId}` → `audioUrl` (sunucudaki seslendirme; cihaza indirilir).
    let audioURL: URL?
    /// `GET /v1/classic-tales` → `coverImageUrl` (varsa şablon + Supabase yolunun üstüne biner).
    let coverImageURL: URL?
    /// Sunucu kaydı UUID’si (`POST /v1/classic-tales/{id}/cover` için).
    let apiRecordId: String?

    init(
        id: String,
        title: String,
        tag: String,
        coverTemplate: StoryCoverTemplateType,
        teaser: String,
        fullStory: String,
        attribution: String,
        audioURL: URL? = nil,
        coverImageURL: URL? = nil,
        apiRecordId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.tag = tag
        self.coverTemplate = coverTemplate
        self.teaser = teaser
        self.fullStory = fullStory
        self.attribution = attribution
        self.audioURL = audioURL
        self.coverImageURL = coverImageURL
        self.apiRecordId = apiRecordId
    }

    /// API’den gelen kapak; yoksa `AppConfig.classicTaleCoverImageURL(taleId:)`.
    var resolvedCoverImageURL: URL? {
        if let coverImageURL { return coverImageURL }
        return AppConfig.classicTaleCoverImageURL(taleId: id)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ClassicTaleItem, rhs: ClassicTaleItem) -> Bool {
        lhs.id == rhs.id
    }

    /// Paket içi yedek liste (API kapalıysa veya boş dönüşte kullanılır).
    static let bundledTales: [ClassicTaleItem] = [
        ClassicTaleSeeds.littleRedRidingHood,
        ClassicTaleSeeds.snowWhite,
        ClassicTaleSeeds.sleepingBeauty,
        ClassicTaleSeeds.cinderella,
        ClassicTaleSeeds.hanselAndGretel,
        ClassicTaleSeeds.rapunzel,
        ClassicTaleSeeds.threeLittlePigs,
        ClassicTaleSeeds.jackBeanstalk,
        ClassicTaleSeeds.uglyDuckling,
        ClassicTaleSeeds.pussInBoots,
        ClassicTaleSeeds.goldilocksAndThreeBears,
        ClassicTaleSeeds.frogPrince,
        ClassicTaleSeeds.thumbelina,
        ClassicTaleSeeds.emperorsNewClothes,
        ClassicTaleSeeds.littleMermaid,
        ClassicTaleSeeds.lionAndMouse,
        ClassicTaleSeeds.foxAndCrane,
        ClassicTaleSeeds.keloglanStarlitPath,
        ClassicTaleSeeds.nasreddinSweetWords
    ]

    /// Seslendirme ve önbellek için tam metin (başlık + gövde).
    var narrationText: String {
        let body = fullStory.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(title).\n\n\(body)"
    }
}
