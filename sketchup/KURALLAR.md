# SketchUp + Claude çalışma kuralları (862 ADA Opsiyon 2)

Son güncelleme: 09.10.2026

## 1. Bağlantı (Ruby watcher)
- SketchUp'ı kapatma. Açık modelde **Window > Ruby Console**'a şunu yaz:
  ```
  load 'C:/Users/emrek/AppData/Local/Temp/cl_su/cl_watch.rb'
  ```
  Konsolda `true` görünce bağlantı hazırdır.
- Claude kodu `%TEMP%\cl_su\cl_cmd.rb` dosyasına yazar, sonuç `cl_out.txt`'ye düşer. Uzun işler kendi log dosyasına (`*_log.txt`) yazar.
- Her yeni SketchUp açılışında (çökme sonrası dahil) bağlantı yeniden yüklenmelidir.
- Birden fazla SketchUp penceresi açıksa yanlış modele komut gitmemesi için önce `Sketchup.active_model.path` ile kontrol edilir; boş "Welcome" pencereleri kapatılır.
- Ekran/fare kontrolü yerine Ruby kullanılır. Ekran görüntüsü yerine `view.write_image` + `raytest` ile kontrol edilir (hızlı ve ucuz).

## 2. Çökmeyi önleme (EN KRİTİK)
SketchUp bu oturumda iki kez çöktü. Sebepler ve kurallar:
- **Scriptten `Sketchup.undo` ASLA çağrılmaz.** Geri alma sadece kullanıcı tarafından Ctrl+Z ile yapılır.
- **Toplu sil–yeniden kur yapılmaz.** Yüzlerce grubu silip baştan oluşturmak yerine sadece değişen parçalar taşınır/düzenlenir (`transform_by_vectors`, `transform!`, malzeme değişimi).
- Aynı ağır script art arda tekrar tekrar çalıştırılmaz.
- **Her komutun sonucu beklenir**, sonra sıradaki gönderilir. İki işlem üst üste gönderilmez.
- Her işlem tek `start_operation ... commit_operation` içinde yapılır; hata olursa `abort_operation` (Ctrl+Z ile tek adımda geri alınabilsin).
- Onaylanan her aşamadan sonra **kaydet**.

## 3. Çökme sonrası kurtarma
1. Hiçbir şey yapmadan önce kurtarma dosyasını proje klasörüne kopyala:
   `%LOCALAPPDATA%\SketchUp\SketchUp 2020\SketchUp\working\SKETCHUP\RecoveredFiles\<dosya>.skp`
   → `Masaüstü\862 ADA opsiyon2\862 ADA opsiyon2 - kurtarilan <tarih saat>.skp`
2. Kurtarılan dosyayı aç, bağlantıyı yükle, içeriği kontrol et (bantlar, lameller, tabelalar vb.).
3. Kullanıcı onayıyla `862 ADA opsiyon2.skp` üstüne kaydet.

## 4. Kaydetme
- Asıl dosya: `Masaüstü\862 ADA opsiyon2\862 ADA opsiyon2.skp`
- Kaydetme kullanıcının onayıyla yapılır (`Sketchup.active_model.save`).
- Versiyon/kopya dosyası açılmaz; gerekirse kurtarma kopyası alınır.

## 5. Modelleme kuralları
- Birim: cm (Ruby içinde inç → `*2.54` / `/2.54`).
- **Aynalı binalar** (`... (ayna)`) orijinalle aynı tanımı paylaşır: orijinale yapılan değişiklik aynaya otomatik geçer. Ayna ekseni y = 13542.
- Mevcut malzemeler değiştirilmez; yeni malzeme (`Ref_*`, `LP_*`) oluşturulup sadece ilgili gruba atanır (başka yerler etkilenmesin).
- Yeni eklenen parçalar adlandırılmış gruplara konur: `Cephe tasarim`, `Spotlar`, `Bakir bant`, `Alt ince bar`, `Tabela`, `Peyzaj bitkileri (low poly)`, `Malc yataklari`.
- Simetri istenince **hangi tarafın esas alınacağı** netleştirilir (bir keresinde yanlış taraf esas alındı).
- Kullanıcının gösterdiği yere/çizime birebir uyulur; yorum yapılacaksa önce sorulur.
- Sadece istenen alanda çalışılır (ör. "sadece arazi içindeki peyzaj").

## 6. Cephe tasarımı (referans görsel)
- Renk paleti referanstan alındı, bozulmaz: traverten #D8C7AE, bej sıva #D9D0C1, ahşap #A9734A, antrasit #3C3936, doğrama #3A3A3C, cam #8C99A3, bakır #96603E.
- Orta bant (her iki bina aynı, 4 dükkan ölçüsü): traverten 425–470, bakır çizgi 470–477, bej sıva 477–512 cm; altında 8 cm geri çekilmiş traverten ince bar 413–425.
- Üst bant altında: 16 cm bakır bar (önde), arkasında pencereye kadar traverten dolgu.
- Spotlar sadece üst bakır barın altında, bina çevresini dolanır. **Alt katta spot yok.**
- Lameller 9×20 cm; alt kat lamelleri ve traverten sütunlar bant altına (413) kadar uzanır. Sütunlar ikili (aralarında 10 cm boşluk).
- Dış duvarlar (arka, yan, üst kat araları) koyu Wool malzemesi — 4 dükkanlı binadaki gibi.

## 7. Peyzaj
- Bitkiler SketchUp içinde üretilir, bileşen olarak çoğaltılır (model şişmez), rastgele ama çakışmasız yerleşir.
- Çok köşeli (aşırı low poly) olmayacak, **mor renk yok**.
- Şimşir kümelerinin altında koyu malç yatağı.
- Uzun gölge ağaçları istenmedi; kısa gövdeli top ağaçlar kalır.

## 8. İletişim
- Kısa konuş, işi yap; ne yapıldığını sonunda özetle.
- Kullanıcı "soru sorma" dediyse varsayılanla ilerle; tasarım konuşması istendiyse önce sor.
- Sol ekran çalışma ekranıdır; sağ ekrana ve Chrome'a dokunulmaz.
