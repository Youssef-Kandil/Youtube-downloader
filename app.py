import os
import sys
import threading
import uuid
from pathlib import Path

from flask import Flask, jsonify, render_template, request

import yt_dlp


def _resource_path(rel: str) -> str:
    """Resolve a path relative to the script — or to the PyInstaller bundle when frozen."""
    base = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, rel)


app = Flask(
    __name__,
    template_folder=_resource_path("templates"),
    static_folder=_resource_path("static"),
)

jobs = {}
jobs_lock = threading.Lock()

QUALITY_FORMATS = {
    "best":  "bv*[ext=mp4]+ba[ext=m4a]/bv*+ba/b",
    "1080p": "bv*[ext=mp4][height<=1080]+ba[ext=m4a]/bv*[height<=1080]+ba/b[height<=1080]/b",
    "720p":  "bv*[ext=mp4][height<=720]+ba[ext=m4a]/bv*[height<=720]+ba/b[height<=720]/b",
    "480p":  "bv*[ext=mp4][height<=480]+ba[ext=m4a]/bv*[height<=480]+ba/b[height<=480]/b",
    "360p":  "bv*[ext=mp4][height<=360]+ba[ext=m4a]/bv*[height<=360]+ba/b[height<=360]/b",
    "audio": "ba/b",
}

DEFAULT_DOWNLOAD_DIR = str(Path.home() / "Downloads")

FFMPEG_DIR = _resource_path("bin")
if os.path.isdir(FFMPEG_DIR):
    os.environ["PATH"] = FFMPEG_DIR + os.pathsep + os.environ.get("PATH", "")


@app.route("/")
def index():
    return render_template("index.html", default_folder=DEFAULT_DOWNLOAD_DIR)


@app.route("/pick-folder", methods=["POST"])
def pick_folder():
    """Open a native folder-picker on the server (works because the app runs locally)."""
    try:
        from tkinter import Tk, filedialog

        root = Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        folder = filedialog.askdirectory(title="اختر فولدر التحميل")
        root.destroy()
        return jsonify({"folder": folder or ""})
    except Exception as e:
        return jsonify({"folder": "", "error": str(e)})


@app.route("/download", methods=["POST"])
def start_download():
    data = request.get_json(force=True) or {}
    raw_urls = data.get("urls", "")
    quality = data.get("quality", "best")
    folder = (data.get("folder") or "").strip()

    if isinstance(raw_urls, str):
        urls = [u.strip() for u in raw_urls.splitlines() if u.strip()]
    else:
        urls = [u.strip() for u in raw_urls if u.strip()]

    if not urls:
        return jsonify({"error": "أدخل رابطًا واحدًا على الأقل"}), 400
    if not folder:
        return jsonify({"error": "اختر فولدر التحميل"}), 400

    try:
        os.makedirs(folder, exist_ok=True)
    except Exception as e:
        return jsonify({"error": f"تعذر استخدام الفولدر: {e}"}), 400

    if quality not in QUALITY_FORMATS:
        quality = "best"

    job_id = str(uuid.uuid4())
    job = {
        "status": "running",
        "folder": folder,
        "quality": quality,
        "total": len(urls),
        "completed": 0,
        "items": [
            {
                "url": u,
                "title": "",
                "status": "pending",
                "progress": 0,
                "speed": "",
                "eta": "",
                "size": "",
                "error": None,
            }
            for u in urls
        ],
    }
    with jobs_lock:
        jobs[job_id] = job

    t = threading.Thread(target=_run_job, args=(job_id, urls, quality, folder), daemon=True)
    t.start()

    return jsonify({"job_id": job_id})


def _run_job(job_id, urls, quality, folder):
    fmt = QUALITY_FORMATS[quality]
    job = jobs[job_id]

    for idx, url in enumerate(urls):
        item = job["items"][idx]
        item["status"] = "downloading"

        def hook(d, item=item):
            if d.get("status") == "downloading":
                total = d.get("total_bytes") or d.get("total_bytes_estimate") or 0
                done = d.get("downloaded_bytes") or 0
                item["progress"] = round(done / total * 100, 1) if total else 0
                item["speed"] = (d.get("_speed_str") or "").strip()
                item["eta"] = (d.get("_eta_str") or "").strip()
                if total:
                    item["size"] = f"{total / (1024*1024):.1f} MB"
            elif d.get("status") == "finished":
                item["progress"] = 100
                item["status"] = "processing"

        ydl_opts = {
            "format": fmt,
            "outtmpl": os.path.join(folder, "%(title)s.%(ext)s"),
            "progress_hooks": [hook],
            "noplaylist": False,
            "quiet": True,
            "no_warnings": True,
            "ignoreerrors": False,
            "ffmpeg_location": FFMPEG_DIR,
        }
        if quality == "audio":
            ydl_opts["postprocessors"] = [{
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "192",
            }]
        else:
            ydl_opts["merge_output_format"] = "mp4"

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                item["title"] = info.get("title") or url
                ydl.download([url])
            item["status"] = "completed"
            item["progress"] = 100
        except Exception as e:
            item["status"] = "error"
            item["error"] = str(e)

        job["completed"] = idx + 1

    job["status"] = "completed"


@app.route("/status/<job_id>")
def job_status(job_id):
    job = jobs.get(job_id)
    if not job:
        return jsonify({"error": "Job not found"}), 404
    return jsonify(job)


def _open_browser():
    import webbrowser
    webbrowser.open_new("http://127.0.0.1:5000")


if __name__ == "__main__":
    print("\n  YouTube Downloader running at  http://127.0.0.1:5000")
    print("  (Close this window to stop the app)\n")
    threading.Timer(1.2, _open_browser).start()
    app.run(host="127.0.0.1", port=5000, debug=False, use_reloader=False)
