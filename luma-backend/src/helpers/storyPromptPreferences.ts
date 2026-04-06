/**
 * Çocuk kaydından ve temadan türetilen kalıcı-vari hissi veren tercihler (DB'de ayrı kolon yok;
 * yaş + tema ile deterministik — iOS LumaAgeGroup / CreateStoryViewModel ile hizalı).
 */

export type ReadingAgeBand = "3-5" | "6-8" | "9-11";

/** Swift LumaAgeGroup.from(age:) ile aynı bölmeler */
export function readingAgeBandFromChildAge(age: number | null): ReadingAgeBand {
  if (age == null) return "6-8";
  if (age < 3) return "3-5";
  if (age <= 5) return "3-5";
  if (age <= 8) return "6-8";
  if (age <= 11) return "9-11";
  return "9-11";
}

export function lengthPreferenceForBand(band: ReadingAgeBand): string {
  switch (band) {
    case "3-5":
      return "short";
    case "6-8":
      return "short_to_medium";
    case "9-11":
      return "medium";
    default:
      return "short_to_medium";
  }
}

export function tonePreferenceForThemeAndBand(themeLower: string, band: ReadingAgeBand): string {
  let base: string;
  switch (band) {
    case "3-5":
      base = "çok sıcak, yumuşak, sakinleştirici";
      break;
    case "6-8":
      base = "sıcak, nazik, hafif maceralı ama güvenli";
      break;
    case "9-11":
      base = "sıcak, umut verici, hafifçe maceralı ama asla karanlık değil";
      break;
  }

  let extra: string;
  switch (themeLower) {
    case "hayvanlar":
    case "uyku":
      extra = "özellikle uyku öncesi rahatlatıcı ve sakin";
      break;
    case "arkadaşlık":
    case "dostluk":
      extra = "ilişki onarıcı, empatik ve yumuşak";
      break;
    case "umut":
    case "eğitici":
      extra = "cesaretlendirici, destekleyici ve açıklayıcı";
      break;
    case "adventure":
    case "macera":
      extra = "merak uyandıran ama güvenli ve hafif";
      break;
    default:
      extra = "çocuğu güvende ve anlaşılmış hissettiren";
  }

  return `${base}, ${extra}`;
}

/** Tema + yaş bandına göre masal odağı (opsiyonel API storyGoal yoksa kullanılır) */
export function defaultStoryGoalForThemeAndBand(themeLower: string, band: ReadingAgeBand): string {
  switch (themeLower) {
    case "hayvanlar":
      return "bedtime_calm: sakinleştirici ve güvenli bir uyku hazırlığı hikayesi";
    case "arkadaşlık":
      return "friendship_repair: arkadaşlık ilişkilerinde duyguların anlaşılması ve onarılması";
    case "umut":
      return "patience_and_persistence: sabır, tekrar deneme ve öğrenme becerilerini desteklemek";
    case "adventure":
      return "gentle_space_adventure: yaş grubuna uygun, hafif heyecan içeren ama güvenli bir macera";
    default:
      switch (band) {
        case "3-5":
          return "bedtime_calm: çok basit ve rahatlatıcı bir günlük hikaye";
        case "6-8":
          return "courage_everyday: küçük bir gündelik kaygıyla baş etme ve cesaret bulma";
        case "9-11":
          return "courage_everyday: hafif duygusal zorlukları güvenli biçimde ele alma";
      }
  }
}
