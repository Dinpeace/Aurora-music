from fastapi import FastAPI, Query
from ytmusicapi import YTMusic

app = FastAPI(
    title="Aurora Music API",
    version="0.1.0",
)

ytmusic = YTMusic()


@app.get("/")
def root():
    return {
        "name": "Aurora Music API",
        "status": "online",
        "version": "0.1.0",
    }


@app.get("/search")
def search(q: str = Query(..., min_length=1)):
    results = ytmusic.search(
        q.strip(),
        filter="songs",
    )

    songs = []

    for item in results:
        video_id = item.get("videoId")

        if not video_id:
            continue

        artists = item.get("artists") or []
        artist = ", ".join(
            artist.get("name", "")
            for artist in artists
            if artist.get("name")
        )

        album = item.get("album") or {}
        thumbnails = item.get("thumbnails") or []

        artwork = (
            thumbnails[-1].get("url")
            if thumbnails
            else ""
        )

        songs.append({
            "id": video_id,
            "title": item.get("title", "Unknown Title"),
            "artist": artist or "Unknown Artist",
            "album": album.get("name", "Unknown Album"),
            "artwork": artwork,
            "streamUrl": "",
            "duration": item.get("duration", "0:00"),
        })

    return {
        "songs": songs,
    }


@app.get("/trending")
def trending():
    return {
        "songs": []
    }
