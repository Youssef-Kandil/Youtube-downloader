# YouTube Downloader

برنامج بسيط لتحميل فيديوهات YouTube بجودات مختلفة (1080p / 720p / 480p / 360p / mp3) — يشتغل في المتصفح على جهازك.

<p align="center">
  <a href="https://github.com/Youssef-Kandil/Youtube-downloader/releases/latest/download/YouTube-Downloader.exe">
    <img src="https://img.shields.io/badge/⬇%20تحميل%20البرنامج-Windows%20.exe-ff3d57?style=for-the-badge&labelColor=11121e" alt="Download YouTube Downloader" height="48" />
  </a>
</p>

<p align="center">
  ملف واحد · مفيش تثبيت · مفيش إعدادات · دبل-كليك واشتغل
</p>

---

## طريقة الاستخدام (للمستخدم العادي)

### 1) حمّل البرنامج
اضغط على زرار **⬇ تحميل البرنامج** فوق (أو [اللينك المباشر](https://github.com/Youssef-Kandil/Youtube-downloader/releases/latest/download/YouTube-Downloader.exe)).

### 2) دبل-كليك على `YouTube-Downloader.exe`
البرنامج هيفتح في المتصفح تلقائياً على http://127.0.0.1:5000

### 3) لإيقاف البرنامج
اقفل النافذة السوداء اللي ظهرت معاه.

> 💡 ممكن تنقل الملف لأي مكان (Desktop مثلاً) ويشتغل من هناك على طول.

---

## ملاحظات

- لو **Windows SmartScreen** ظهر تنبيه ("Windows protected your PC")، اضغط **More info** ← **Run anyway**. ده طبيعي لأن البرنامج مش signed بشهادة رقمية مدفوعة.
- لو الأنتي-فايرس عمل تنبيه (false positive)، ضيفه للاستثناءات.
- البرنامج بيشتغل محلياً 100% — مفيش بيانات بتترفع لأي حد.

---

## للمطورين — البناء من الكود المصدري

لو حابب تعدّل في الكود وتبني الـ exe بنفسك:

### الطريقة السهلة (أوتوماتيكي)
دبل-كليك على `setup.bat` — هيعمل كل حاجة:
- ✓ يثبّت Python لو مش موجود
- ✓ يثبّت المكتبات (Flask, yt-dlp, PyInstaller)
- ✓ ينزّل ffmpeg
- ✓ يبني `YouTube-Downloader.exe`

(حوالي 5-10 دقايق المرة الأولى. لإعادة البناء بعد تعديل الـ UI: شغّل `rebuild.bat` — أسرع بكتير.)

### الطريقة اليدوية
```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt pyinstaller
# ضع ffmpeg.exe و ffprobe.exe في bin/
python app.py
```

---

<p align="center">
  developed by <a href="https://github.com/Youssef-Kandil">Youssef Kandil</a>
</p>
