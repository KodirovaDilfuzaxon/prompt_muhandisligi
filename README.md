# Prompt muhandisligi — ilmiy-metodik qo‘llanma (Android ilova)

Qo‘llanma HTML ko‘rinishida `assets/www/` ichida saqlanadi va ilova internetsiz ishlaydi. Flutter qismi (`lib/main.dart`) orqaga tugmasi, tashqi havolalar, nusxalash va status bar rangini boshqaradi.

## Yig‘ish (GitHub Actions)
Har safar `main` tarmog‘iga kod yuklanganda yig‘ish o‘zi boshlanadi. Qo‘lda boshlash uchun: **Actions → «Android yig‘ish (APK + AAB)» → Run workflow**.

Natijalarni ikki joydan olish mumkin:
- yig‘ma sahifasidagi **Artifacts** bo‘limidan (zip);
- **natijalar** tarmog‘idan: `prompt_muhandisligi.apk` va `prompt_muhandisligi.aab`.

## Google Play uchun imzolash
Kalit berilmasa, fayllar debug kaliti bilan imzolanadi: APK’ni sinash mumkin, lekin Play bu AAB’ni qabul qilmaydi.

Kalitni ulash: **Settings → Secrets and variables → Actions → New repository secret** bo‘limiga to‘rtta qiymat qo‘shiladi:

| Secret | Qiymati |
|---|---|
| `KEYSTORE_BASE64` | `.jks` faylining base64 ko‘rinishi |
| `KEYSTORE_PASSWORD` | kalit ombori paroli |
| `KEY_ALIAS` | kalit nomi (masalan `upload`) |
| `KEY_PASSWORD` | kalit paroli |

Windows’da base64 olish: `certutil -encodehex -f upload-keystore.jks kalit.txt 0x40000001`

**Diqqat:** `.jks` fayli va parollar hech qachon repozitoriyga yuklanmasin (`.gitignore` ularni to‘sadi). Kalitni yo‘qotsangiz, ilovani yangilab bo‘lmaydi; zaxira nusxasini xavfsiz joyda saqlang.

## Kontentni yangilash
`assets/www/index.html` faylini almashtiring, `pubspec.yaml`dagi `version`ni oshiring (masalan `1.0.1+2`) va yuklang.
