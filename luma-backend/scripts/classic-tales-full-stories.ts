/**
 * iOS `ClassicTalesLibrary` ile aynı tam metinler — kapak üretiminde içerik tabanlı prompt için.
 * Metin değişince burayı ve Swift dosyasını birlikte güncelle.
 */
export type ClassicTaleSeedRow = {
  taleId: string;
  title: string;
  teaser: string;
  fullStory: string;
};

export const CLASSIC_TALES_WITH_FULL_STORY: ClassicTaleSeedRow[] = [
  {
    taleId: "little-red-riding-hood",
    title: "Kırmızı Başlıklı Kız",
    teaser: "Nazik bir yürüyüş, bilge bir büyükanne ve ormanın sessizliği.",
    fullStory: `
Bir varmış bir yokmuş, küçük bir köyde annesiyle yaşayan sevimli bir kızmış. Herkes ona, annesinin ona ördüğü kıpkırmızı pelerinden ötürü "Kırmızı Başlıklı Kız" derlermiş.

Bir gün annesi taze çöreklerle dolu bir sepeti ona vermiş. "Büyükannene götür, yolda ormandan sapma; düz yoldan git ve kimseyle gereksizce uzun konuşma," demiş. Kız başını sallamış, sepeti kucaklamış ve yola çıkmış.

Orman yolu güneşte pırıl pırılmış; kuşlar şarkı söylüyor, yapraklar hışırdıyormuş. Bir süre sonra karşısına gülümseyen, kürkünü düzgünce giymiş bir kurt çıkmış. Kurt nazik bir sesle, "Nereye gidiyorsun küçük hanım?" diye sormuş. Kız büyükannesinin evinin yolunu tarif etmiş. Kurt içinden, "Bu bilgiyi iyi ki öğrendim," diye geçirmiş; ama kıza sert davranmamış, yol göstermiş gibi görünmüş.

Kurt daha kestirme bir patika bildiğini söyleyerek öne geçmiş. Kızı oyalayacak çiçekler toplaması için durdurmuş; kendisi ise büyükannenin evine varmış. İçeri girmiş ve yaşlı kadının şapkasına sarılarak yatağa uzanmış. Biraz sonra kapı çalmış: Kırmızı Başlıklı Kız gelmiş. "Büyükanne, sesin neden böyle kalın?" diye sormuş. Kurt tuhaf cevaplar vermiş. Sonunda kız gerçeği sezmiş ve bağırmış. Ormanda işini bitirmiş dönen oduncular, kapıyı çalmış; kurt çekingen bir hayvan olduğunu hatırlayıp pencereden kaçmış. Büyükanne kucaklanmış, çörekler paylaşılmış.

O günden sonra Kırmızı Başlıklı Kız, yabancılara fazla güvenmemeyi ve annesinin sözünü dinlemenin ne kadar değerli olduğunu anlamış. Ve hep birlikte, ışığı söndürmeden önce güvenli bir uyku uyumuşlar.
`.trim()
  },
  {
    taleId: "snow-white",
    title: "Pamuk Prenses",
    teaser: "Kıskançlığın gölgesinde bile iyilik ışık saçar.",
    fullStory: `
Kışın kar taneleri pencerenin dışında dans ederken, bir kraliçe bebeğini kucağına almış. Teni kar gibi açık, dudakları gül yaprağı gibi kırmızıymış; adını Pamuk Prenses koymuşlar.

Zaman geçmiş; annesini kaybeden Pamuk Prenses, üvey annesiyle yaşarmış. Ayna diye büyülü bir söz söylenir: "Bu evde en güzel kim?" Üvey anne bazen bu sorunun cevabından rahatsız olurmuş. Pamuk Prenses ise nezaketinden hiçbir şey kaybetmemiş.

Bir gün ormanda yedi cüce kardeşle tanışmış. Onların küçük evinde düzeni sevmiş, yemek pişirmiş, şarkı söylemiş. Cüceler ona sığınak olmuş. Kötü niyetli biri, elma sunarak onu uyutmak istemiş; Pamuk Prenses derin bir uykuya dalmış. Orman sessizleşmiş, kuşlar üzülmüş.

Uzun süre sonra, yolu oradan geçen nazik bir prens, sessiz bahçeyi görmüş. Pamuk Prenses'in elini nazikçe tutmuş; o anda sihir çözülmüş gibi nefes almış kız. Herkes sevinmiş. Üvey annenin kıskançlığı ise boşa çıkmış: çünkü gerçek güzellik, kalbin merhametindeymiş.

Pamuk Prenses cüceleri ziyaret etmeyi hiç bırakmamış. Masal da burada, sıcacık bir "iyi geceler" ile bitmiş.
`.trim()
  },
  {
    taleId: "sleeping-beauty",
    title: "Uyuyan Güzel",
    teaser: "Bir dilek, iğnenin ucu ve yüz yıllık sakin bir uyku.",
    fullStory: `
Uzak bir ülkede, çocuğu olmayan kral ile kraliçe yaşarmış. Sonunda minicik bir prenses dünyaya gelmiş; sarayda ziyafetler kurulmuş, peri misafirler dilekler sunmuş. Bir peri unutulduğu için üzülmüş ve şöyle demiş: "On altı yaşına geldiğinde bir iğneye dokunacak ve derin bir uykuya dalacak; ama bu uyku sonsuz keder değil, bekleyen bir bahar olacak."

Kral iğneleri saraydan toplatmış; yine de kader, sarayın kulesinde gizli bir odaya prensesi götürmüş. İnce bir iğneye dokunan prenses, gözlerini yummuş. Tüm saray da onunla birlikte zamanı durdurmuş: aşçılar sofrada, bahçıvanlar gül kokusunda kalmış.

Çevrede dikenli çalılar büyümüş; dışarıdan kimse içeri girememiş. Yıllar geçmiş, yüz yıl denmiş ama sayı önemli değilmiş aslında; önemli olan umutmuş.

Bir gün cesur ve nazik bir prens, çalıların arasından geçmeyi başarmış. Prensesin odasına varmış, ona sevgiyle bakmış. O anda sihir çözülmüş: prenses gözlerini açmış, saray neşeyle uyanmış. Dikenler çiçek açmış, müzik yankılanmış.

Uyku, korku değil; yeniden doğuşun kısa bir molasıymış. Ve o gece, herkes pencereleri açıp yıldızlara iyi dilekler göndermiş.
`.trim()
  },
  {
    taleId: "cinderella",
    title: "Külkedisi",
    teaser: "Nezaket ve sabır, gizli bir balonun kapısını aralar.",
    fullStory: `
Külkedisi diye anılan genç kız, annesini çok küçükken kaybetmiş. Babası yeniden evlenmiş; yeni annesi ve iki kız kardeşi ev işlerini ona bırakırmış. Külkedisi şikâyet etmezmiş; sobanın yanında hayaller kurar, kuşlara ekmek kırıntısı verirmiş.

Bir gece sarayda balo duyurulmuş. Üvey kardeşler ipek elbiseler giymiş, Külkedisi ise evde kalmış. Tam o sırada peri benzeri bir yardımcı çıkmış: "Git, ama gece yarısından önce dön," demiş. Balkabağı arabaya, fareler ata, fareleri koçuşluya dönüştürmüş. Külkedisi cam ayakkabılar ve ışıldayan bir elbiseyle baloya yetişmiş.

Prens onunla dans etmiş; kim olduğunu sormuş. Saat on ikiye yaklaşınca Külkedisi hatırlamış ve koşarak gitmiş; bir cam terlik merdivende kalmış.

Prens ülkeyi dolaşarak terliği denetmiş. Sonunda Külkedisi'nin evine gelmiş; terlik tam oturmuş. Prens tebessüm etmiş: "Kalbini tanıdım," demiş. Külkedisi artık kül masasında değil, sevgiyle karşılandığı bir masada oturmuş.

Masal, "içtenlik görülür" diye fısıldayıp bitmiş.
`.trim()
  },
  {
    taleId: "hansel-gretel",
    title: "Hansel ve Gretel",
    teaser: "İki kardeş, ormanda yolunu akıl ve dayanışmayla bulur.",
    fullStory: `
Hansel ile Gretel, küçük bir kulübede yaşarlarmış. Yiyecek azaldığında babaları üzülür, üvey anneleri ise çaresizlikten sertleşirmiş. Bir sabah çocukları ormana bırakmayı düşünmüşler. Hansel cebine küçük çakıl taşları doldurmuş; giderken yere düşürmüş. Gece olunca taşlar ay ışığında parlamış ve yolu eve göstermiş.

Bir kez daha ormana çıkmaları gerekmiş; bu kez Hansel yerine ekmek kırıntısı bırakmış, kuşlar kırıntıları yemiş. Çocuklar kaybolmuş. Derken ağaçların arasında şekerden pencereli minik bir ev görmüşler. İçeride yaşlı bir kadın onlara sıcak çorba ikram etmiş; ama aslında onları evde tutmak istiyormuş.

Gretel akıllıymış. Kadının dikkati dağılınca, kardeşinin zincirini çözmüş. Birlikte kapıyı aralamışlar ve ormanda bildikleri işaretlere dönerek yürümüşler. Uzun yolun sonunda babalarını bulmuşlar; eve ekmek getirmişler.

O günden sonra aile, konuşarak dertlerini paylaşmayı öğrenmiş. Hansel ile Gretel de birbirlerini hiç bırakmamış. Masal, "birlikteyken yol bulunur" diyerek usulca kapanmış.
`.trim()
  },
  {
    taleId: "rapunzel",
    title: "Rapunzel",
    teaser: "Yüksek bir kule, altın saçlar ve özgürlüğe uzanan bir merdiven.",
    fullStory: `
Bir bahçede, lambs ear otuna benzer "rapunzel" bitkileriymiş. Hamile bir kadın bu yeşilliklere özlem duymuş; kocası çalıların arasından bir demet koparmış. Bahçenin sahibi, güçlü büyücü kadın, bunu görünce çiftin çocuğunu büyütme sözü almış.

Kız doğunca ona Rapunzel adını vermişler. Zamanla saçları güneş rengi uzamış; büyücü kadın onu yüksek bir kulede saklamış. Merdiven yokmuş; sadece pencereden sesler iniyormuş.

Rapunzel şarkı söyleyerek günlerini yumuşatırmış. Bir gün oradan geçen genç bir prens, sesini duymuş. Kadın her zamanki gibi "Rapunzel, Rapunzel, saçlarını sarkıt" deyince uzun saçlar merdiven olmuş; prens de nazikçe konuşmayı öğrenmiş.

Birlikte kaçmayı planlamışlar: Rapunzel saçlarını örmüş, prens yumuşak bir ip bağlamış. Gece çökünce inmişler; ormanda yıldızlar yol göstermiş. Büyücü kadın pişmanlıkla ardından bakmış; çünkü sevgi, kule duvarlarından güçlüymüş.

Rapunzel özgürlüğü, prens ise sabrı öğrenmiş. Masal, "kalp dinlenince yol açılır" diyerek sona ermiş.
`.trim()
  },
  {
    taleId: "three-little-pigs",
    title: "Üç Küçük Domuz",
    teaser: "Saman, tahta ve tuğla; sabırla örülen ev en güvenlidir.",
    fullStory: `
Üç küçük domuz kardeş, annelerinden vedalaşıp kendi evlerini kurmaya gitmiş. Birincisi acele etmiş, samanla hızlıca bir kulübe yapmış. İkincisi biraz daha uğraşmış ama yine de tahtayı çabucak çakmış. Üçüncüsü tuğla taşımış, harç karıştırmış; günlerce çalışmış.

Ormanda kürkünü silkelenen bir kurt dolaşıyormuş. Önce saman eve üflemiş; kulübe yıkılmış, domuzcuk koşarak kardeşinin tahta evine sığınmış. Kurt yine üflemiş; tahta ev sallanmış, ikisi birlikte tuğla eve koşmuş.

Üçüncü domuz kapıyı açmış: "Burada her şey sağlam," demiş. Kurt üflemiş üflemiş; tuğla ev kımıldamamış. Sonunda yorgun düşmüş, başka ormanlara gitmiş.

Üç kardeş o gece sıcacık çorba içmiş. Anlamışlar ki emek, güvenliği getirirmiş. Masal da, "acele işe şeytan karışır" sözünü hatırlatarak bitmiş.
`.trim()
  }
];
