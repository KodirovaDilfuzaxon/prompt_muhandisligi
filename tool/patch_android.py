#!/usr/bin/env python3
"""
android/app/build.gradle.kts fayliga Google Play uchun imzolash (release signing)
sozlamasini qo'shadi. `flutter create` dan keyin bir marta ishga tushiriladi.

Ishlatish (loyiha ildizida):  python3 tool/patch_android.py

Natija:
  - android/key.properties mavjud bo'lsa — release yig'ma shu kalit bilan imzolanadi;
  - mavjud bo'lmasa — debug kaliti bilan (faqat sinov uchun, Google Play qabul qilmaydi).
Skript qayta ishga tushirilsa, ikkinchi marta qo'shmaydi.
"""
import re
import sys
from pathlib import Path

GRADLE = Path("android/app/build.gradle.kts")

IMPORTS = "import java.io.FileInputStream\nimport java.util.Properties\n\n"

PROPS = '''
// Imzolash kaliti ma'lumotlari (android/key.properties)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
'''

SIGNING = '''    // Ichki (.so) kutubxonalar siqilib saqlanadi — APK fayli ancha kichik bo'ladi
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

'''

RELEASE_SIGN = ('signingConfig = if (keystorePropertiesFile.exists()) '
                'signingConfigs.getByName("release") else signingConfigs.getByName("debug")')


def fail(msg: str) -> None:
    print("XATO: " + msg, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not GRADLE.exists():
        groovy = Path("android/app/build.gradle")
        if groovy.exists():
            fail("Loyiha eski Groovy (build.gradle) shablonida. Flutter'ni yangilang "
                 "yoki imzolashni README'dagi qo'lda usul bilan qo'shing.")
        fail(f"{GRADLE} topilmadi. Avval `flutter create` buyrug'ini bajaring.")

    text = GRADLE.read_text(encoding="utf-8")
    if "keystorePropertiesFile" in text:
        print("Imzolash sozlamasi allaqachon qo'shilgan — o'zgarish yo'q.")
        return

    # 1) Importlar — fayl boshiga
    text = IMPORTS + text

    # 2) Kalit xususiyatlari — plugins { ... } blokidan keyin
    m = re.search(r"^plugins\s*\{.*?^\}\s*$", text, flags=re.S | re.M)
    if not m:
        fail("plugins { } bloki topilmadi.")
    text = text[: m.end()] + "\n" + PROPS + text[m.end():]

    # 3) signingConfigs — android { } ichida, buildTypes dan oldin
    m = re.search(r"^[ \t]*buildTypes\s*\{", text, flags=re.M)
    if not m:
        fail("buildTypes { } bloki topilmadi.")
    text = text[: m.start()] + SIGNING + text[m.start():]

    # 4) release'da imzolash kalitini almashtirish
    new, n = re.subn(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', RELEASE_SIGN, text, count=1)
    if n == 0:
        # Shablon o'zgargan bo'lsa — release blokiga qo'shamiz
        m = re.search(r"release\s*\{", new)
        if not m:
            fail("buildTypes ichida release { } bloki topilmadi.")
        new = new[: m.end()] + "\n            " + RELEASE_SIGN + new[m.end():]
    text = new

    # Google Play talabi: compileSdk va targetSdk = 36
    text = re.sub(r"compileSdk\s*=\s*[^\n]+", "compileSdk = 36", text, count=1)
    text = re.sub(r"targetSdk\s*=\s*[^\n]+", "targetSdk = 36", text, count=1)
    GRADLE.write_text(text, encoding="utf-8")
    print("Tayyor: imzolash sozlamasi qo'shildi -> " + str(GRADLE))


if __name__ == "__main__":
    main()
