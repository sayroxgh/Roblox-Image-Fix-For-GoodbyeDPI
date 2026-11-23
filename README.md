# Roblox CDN Fix (Türkiye)

Roblox açılıyor (oyun da normal pingle çalışıyor) ama **site ve uygulamada avatar, küçük resim ve ikonlar yüklenmiyorsa** ve [GoodbyeDPI-Turkey](https://github.com/cagritaskn/GoodbyeDPI-Turkey) gibi bir DPI aracı çalışırken bile düzelmiyorsa bu araç işe yarayabilir.

> Bu araç DPI engelini **kendi başına aşmaz**. GoodbyeDPI / Zapret / SplitWire kullanmaya devam et. Bu sadece onun üstüne eksik bir DNS kaydını tamamlar.

## Belirtiler

- `roblox.com` açılıyor ama görseller yok ya da gri.
- Tarayıcıda F12 → Network sekmesinden bir görsel isteğini açınca `tr.rbxcdn.com` için `DNS_PROBE_POSSIBLE` / "DNS adresi bulunamadı" hatası çıkıyor.
- `nslookup tr.rbxcdn.com` bir isim döndürüyor ama **IP adresi göstermiyor**.

## Sebep

10 ekim 2026 itibarıyla `tr.rbxcdn.com` için Cloudflare (`1.1.1.1`), Google (`8.8.8.8`) ve bir ev modeminin DNS'i IP adresi döndürmüyordu. `t0.rbxcdn.com` ve diğer `tN.rbxcdn.com` adresleri ise normal çözülüyordu (Amazon CloudFront). Hiçbir DNS sunucusu cevap vermediği için DNS değiştirmek ya da DPI aracı kullanmak çözmüyor. Kaydın neden boş olduğu bilinmiyor.

## Ne yapıyor?

1. `t0.rbxcdn.com` adresini `1.1.1.1` üzerinden çözüp güncel bir CloudFront IP'si alır.
2. IP'yi `tr.rbxcdn.com` için gerçek bir HTTPS isteğiyle test eder (HTTP `404` cevabı sorun değil, bağlantının çalıştığını gösterir).
3. `C:\Windows\System32\drivers\etc\hosts` dosyasına `IP tr.rbxcdn.com # RobloxCDNFix` satırını yazar ve DNS önbelleğini temizler.

Yalnızca `tr.rbxcdn.com` geçen ya da `# RobloxCDNFix` işareti taşıyan satırlara dokunulur. Hosts dosyandaki diğer hiçbir şey değiştirilmez.

## Gereksinimler

- Windows 10 / 11
- PowerShell 5.1+ (Windows ile birlikte gelir)
- Çalışan bir DPI aracı (GoodbyeDPI-Turkey, Zapret, ...)

## Kullanım

1. Repoyu indir ya da klonla, tüm dosyaları aynı klasörde tut.
2. DPI aracını başlat.
3. **`Fix.bat`** dosyasına çift tıkla ve yönetici izni isteğini onayla.
4. **Tarayıcıyı tamamen kapatıp yeniden aç** (Roblox için de aynı). Sayfayı yenilemek yetmez, tarayıcılar DNS'i önbellekte tutar.

Geri almak için: **`Remove.bat`** çalıştır.

CloudFront IP'si zamanla değişebilir. Görseller bir gün yine kaybolursa `Fix.bat` dosyasını tekrar çalıştırman yeterli.

## Doğrulama

```bat
ping tr.rbxcdn.com
```

Cevapta betiğin yazdığı IP görünmeli. Ardından roblox.com'da görsellerin yüklendiğini kontrol et.

## Sorun giderme

| Sorun | Dene |
| --- | --- |
| Görseller hâlâ yok | Tarayıcıyı tamamen kapat (sistem tepsisine de bak) ve yeniden aç. |
| Brave / Chrome / Edge'de hâlâ `DNS_PROBE_POSSIBLE` | Tarayıcı ayarlarında "Güvenli DNS"i kapat, tarayıcının hosts dosyasını atlamadığından emin ol. |
| "Could not write the hosts file" | Hosts dosyasını açık tutan editörleri kapat, antivirüsünün hosts dosyasını koruyup korumadığına bak. |
| "No IP passed the connection test" | Önce DPI aracını başlat, sonra `Fix.bat` dosyasını tekrar çalıştır. |
| Görseller bir süre sonra yine kayboluyor | IP değişmiş olabilir. `Fix.bat` dosyasını yeniden çalıştır. |
| Roblox DNS kaydını düzeltirse | `Remove.bat` çalıştır, kayıt artık gereksiz. |

## Güvenlik

- Betikler düz metin, çalıştırmadan önce oku (tüm mantık `RobloxCDNFix.ps1` içinde).
- Yalnızca `1.1.1.1` (DNS sorgusu) ve Roblox CDN'iyle (bağlantı testi) iletişim kurar, sadece hosts dosyasını düzenler.
- Bunu yalnızca resmi repodan indir. Video yorumlarında paylaşılan benzer komutları körü körüne çalıştırma.

## Test edilenler

| Windows | Tarayıcı | DPI aracı | Operatör | Sonuç |
| --- | --- | --- | --- | --- |
| Windows 11 | Brave | GoodbyeDPI-Turkey (manuel) | TürkTelekom | Görseller yükleniyor |

Sonuçlar operatöre göre değişebilir. Kendi sonucunu eklemek için issue ya da pull request aç.

## Sorumluluk reddi

Resmi değildir, Roblox Corporation ile bağlantısı yoktur. Windows hosts dosyasını değiştirir, kullanım sorumluluğu sana aittir. Olduğu gibi, garantisiz sunulur.

## Teşekkürler

- [cagritaskn/GoodbyeDPI-Turkey](https://github.com/cagritaskn/GoodbyeDPI-Turkey) ve [SplitWire-Turkey](https://github.com/cagritaskn/SplitWire-Turkey)
- Technopat / Techolay forumlarındaki topluluk raporları
- Claude
