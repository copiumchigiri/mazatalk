#!/usr/bin/env python3
"""Pre-generate Mongolian TTS clips for every phrase in tools/tts_phrases.txt.

Free, no API key: uses Microsoft's Mongolian neural voices through the
`edge-tts` package (pip install edge-tts). Output file names are the first
12 hex chars of sha1(phrase) — the same key TtsService computes at runtime,
so a phrase edited here must match the string the app speaks exactly.

Usage:  python3 tools/generate_tts.py [--voice mn-MN-BataaNeural] [--force]
"""
import argparse
import asyncio
import hashlib
import pathlib

import edge_tts

ROOT = pathlib.Path(__file__).resolve().parent.parent
PHRASES = ROOT / "tools" / "tts_phrases.txt"
OUT = ROOT / "assets" / "audio" / "tts"


def key(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--voice", default="mn-MN-YesuiNeural")
    parser.add_argument("--rate", default="-10%", help="speaking rate, e.g. -10%%")
    parser.add_argument("--force", action="store_true", help="regenerate existing clips")
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    phrases = [
        line.strip()
        for line in PHRASES.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.startswith("#")
    ]
    wanted = set()
    for phrase in phrases:
        path = OUT / f"{key(phrase)}.mp3"
        wanted.add(path.name)
        if path.exists() and not args.force:
            continue
        print(f"generating {path.name}  {phrase}")
        await edge_tts.Communicate(phrase, args.voice, rate=args.rate).save(str(path))
    for stale in OUT.glob("*.mp3"):
        if stale.name not in wanted:
            print(f"removing stale {stale.name}")
            stale.unlink()
    print(f"done: {len(phrases)} phrases")


asyncio.run(main())
