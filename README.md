# 🛒 Gross: Otonom (Agentic) İşletme & Finans Asistanı

> Küçük ve orta ölçekli perakende işletmelerinin (Bakkal, Gross, Mini Market) finansal yükünü ve operasyonel stresini omuzlayan, **Yapay Zeka destekli yeni nesil dijital defter.**

## 🚀 Projenin Amacı ve Vizyonu
Geleneksel perakende esnafı, veresiye defterleri ve dağınık faturalar arasında kaybolmakta, nakit akışını yönetmekte zorlanmaktadır. **Gross**, sadece geçmişi raporlayan klasik bir muhasebe uygulaması değildir. Kasa, stok, veresiye ve görevleri tek bir merkezde toplayarak işletme sahibine **"Gelecekte ne yapması gerektiğini"** söyleyen proaktif bir asistandır.

## 🧠 Agentic (Otonom) Yapay Zeka Entegrasyonu

* **Bağlamsal Analiz (Context Awareness):** Arayüzde seçilen tarih aralığına göre, arka planda gizlice **Kasadaki Nakit**, **Bekleyen Faturalar**, **Veresiye Alacakları** ve **Kritik Stokları** (10 adet altı) tarar.
* **Risk Tahmini:** Kasa bakiyesi, yaklaşan faturaları karşılamıyorsa işletmeciyi esnaf diliyle doğrudan uyarır.
* **Otonom Aksiyon (Action Taking):** Nakit açığı tespit ettiğinde, en yüksek borcu olan müşteriyi veri tabanından otonom olarak bulur ve tahsilat için hazır bir WhatsApp mesajı oluşturup tek tıkla gönderilmesini sağlar.

## ✨ Temel Özellikler
1. **Holding Konsolu (Patron Raporu):** Tek ekranda ciro, gider ve net kâr analizi (Fl_Chart ile görselleştirilmiş). Şube bazlı veya konsolide (tüm şubeler) finansal görünüm.
2. **Akıllı Veresiye (Cari) Takibi:** Müşteri borç/alacak yönetimi ve geçmiş işlemlerin dijital ekstresi.
3. **Görev ve Fatura Ajandası:** Bekleyen ödemeler, faturalar ve acil tamamlanması gereken görevler.
4. **Agentic Tahsilat Modülü:** Yapay Zeka yönlendirmesi ile en borçlu müşteriye WhatsApp üzerinden tek tıkla kibar tahsilat hatırlatması.

## 🛠️ Kullanılan Teknolojiler
* **UI/UX:** Flutter / Dart (Dumb UI Prensiplerine uygun, State odaklı mimari)
* **State Management:** Provider
* **Veritabanı & Backend:** Firebase Cloud Firestore
* **Yapay Zeka:** Google Gemini AI API (Otonom Finansal Analiz için)
* **Veri Görselleştirme:** fl_chart
* **Dış Bağlantılar:** url_launcher (Otonom WhatsApp Entegrasyonu)

## ⚙️ Kurulum ve Çalıştırma
Projeyi kendi ortamınızda çalıştırmak için:
1. Repoyu klonlayın: `git clone https://github.com/kullanici-adiniz/gross-app.git`
2. Gerekli paketleri indirin: `flutter pub get`
3. Projenin kök dizinine `.env` adında bir dosya oluşturun ve Google Gemini API anahtarınızı ekleyin:
   `GEMINI_API_KEY=sizin_api_anahtariniz_buraya`
4. Uygulamayı başlatın: `flutter run`

5. ## Lisans

Bu proje tescilli bir yazılımdır.

İzinsiz kullanım, kopyalama, değiştirme, dağıtım veya ticari kullanım kesinlikle yasaktır.

Daha fazla ayrıntı için LICENSE dosyasına bakın.
