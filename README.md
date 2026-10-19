# 🍅 iOS Pomodoro — Minimalist Odak & Zaman Yönetimi Uygulaması

Modern **SwiftUI** ve **Observation (`@Observable`)** mimarisiyle iPhone için geliştirilmiş, sade ve akıcı animasyonlara sahip bir Pomodoro odaklanma uygulaması.

---

## ✨ Özellikler

- **⏱️ 3 Odak Modu ve Otomatik Döngü:**
  - **Odaklan (25 dk)**, **Kısa Mola (5 dk)** ve **Uzun Mola (15 dk)** modları.
  - Her 4 odak oturumu sonrasında otomatik olarak **Uzun Mola** fazına geçiş.
- **🎨 Akıcı SwiftUI Geçiş Animasyonları:**
  - Faz seçicide `matchedGeometryEffect` ile kayan aktif mod kapsülü.
  - Geri sayım sayacında `.contentTransition(.numericText(countsDown: true))` ile yumuşak rakam geçişleri.
  - İkonlarda `.symbolEffect(.replace)` geçişleri.
  - Sayaç çalışırken nefes alan (breathing pulse) ambiyans halkası ve `AngularGradient` ilerleme çubuğu.
- **📋 Görev Yönetimi (Tasks):**
  - Üzerinde çalışılan aktif görevi seçme, tahmini Pomodoro hedefi belirleyerek yeni görev ekleme.
  - Odak oturumu tamamlandığında seçili görevin ilerlemesini otomatik artırma ve hedefe ulaştığında tamamlandı olarak işaretleme.
- **📊 İstatistikler ve Günlük Hedef:**
  - Günlük odak hedefi ilerleme çubuğu (`%` göstergeli).
  - Bugünkü odak dakikası, toplam odak süresi, tamamlanan oturum sayısı ve geçmiş oturum kayıtları.
- **🔔 Arka Plan Desteği, Bildirim & Haptic:**
  - `Date` (`targetEndDate`) tabanlı süre hesaplaması sayesinde uygulama arka plana atılsa veya ekran kilitlense bile saniye kaybı olmadan doğru geri sayım.
  - Faz tamamlandığında yerel bildirim (`UNUserNotificationCenter`), ses uyarısı ve iPhone Haptic (`UIImpactFeedbackGenerator`) geri bildirimi.
- **⚙️ Özelleştirilebilir Ayarlar:**
  - Odak/mola sürelerini, uzun mola aralığını, günlük hedefi ve otomatik başlatma tercihlerini cihazda (`UserDefaults`) kalıcı olarak saklama.

---

## 📂 Proje Klasör Yapısı (MVVM)

```text
Pomodoro/
├── Pomodoro.xcodeproj
├── README.md
└── Pomodoro/
    ├── App/
    │   └── PomodoroApp.swift                  # Uygulama giriş noktası (@main)
    ├── Models/
    │   └── PomodoroModels.swift               # PomodoroPhase, PomodoroTask, PomodoroSession, PomodoroSettings
    ├── ViewModels/
    │   └── PomodoroViewModel.swift            # @Observable ana durum yönetimi, zamanlayıcı ve kalıcılık
    ├── Views/
    │   ├── ContentView.swift                  # Ana ekran, faz seçici ve kontrol butonları
    │   ├── TimerRingView.swift                # Dairesel ilerleme halkası ve animasyonlu sayaç
    │   ├── SheetsAndSubviews.swift            # Görevler, İstatistikler ve Ayarlar pencereleri
    │   └── PomodoroLogoAndBubblesView.swift   # Özel logo ve yüzen baloncuk ambiyans bileşenleri
    └── Resources/
        └── Assets.xcassets                    # Uygulama ikonları ve renk varlıkları
```

---

## 🚀 Kurulum ve Çalıştırma

1. Depoyu bilgisayarınıza klonlayın:
   ```bash
   git clone https://github.com/AidenVanya/Ios-Pomodoro.git
   cd Ios-Pomodoro
   ```
2. `Pomodoro.xcodeproj` dosyasını **Xcode** ile açın.
3. Üst çubuktan bir iPhone simülatörü (veya kendi iPhone cihazınızı) seçin.
4. **`⌘ + R`** tuşlarına basarak uygulamayı derleyin ve çalıştırın.

---

## 🛠️ Kullanılan Teknolojiler

- **Dil:** Swift 6 / Swift 5.10+
- **Arayüz:** SwiftUI
- **Mimari:** MVVM (`@Observable`, `@MainActor`, Swift Concurrency `Task`)
- **Kalıcılık:** `UserDefaults` + `Codable`
- **Sistem Çerçeveleri:** `UserNotifications`, `AudioToolbox`, `UIKit` (Haptics)
