#!/usr/bin/env python3
"""Validate the visual-novel story files without needing Godot.

Checks:
  * every chapter JSON parses
  * every block referenced by goto / choice.goto / if.goto / if.else exists
    within its chapter
  * every next_chapter target file exists
  * every bg / show asset has a placeholder file (warning only)
  * at least one reachable terminal (end / next_chapter) per chapter

Exit code is non-zero if any hard error is found. Run from repo root:
    python3 tools/validate_story.py
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORY = os.path.join(ROOT, "game", "story")
BG = os.path.join(ROOT, "game", "assets", "bg")
CHAR = os.path.join(ROOT, "game", "assets", "char")

errors = []
warnings = []


def asset_exists(folder, name):
    for ext in (".png", ".webp", ".jpg", ".jpeg"):
        if os.path.exists(os.path.join(folder, name + ext)):
            return True
    return False


def check_chapter(path):
    cid = os.path.splitext(os.path.basename(path))[0]
    with open(path, encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            errors.append(f"{cid}: JSON parse error: {e}")
            return
    blocks = data.get("blocks", {})
    if not blocks:
        errors.append(f"{cid}: no blocks")
        return
    start = data.get("start", "start")
    if start not in blocks:
        errors.append(f"{cid}: start block '{start}' missing")

    has_terminal = False
    for bname, cmds in blocks.items():
        for cmd in cmds:
            for key in ("goto", "else"):
                if key in cmd and cmd[key] not in blocks:
                    errors.append(f"{cid}.{bname}: {key} -> unknown block '{cmd[key]}'")
            if "choice" in cmd:
                for opt in cmd["choice"]:
                    if "goto" in opt and opt["goto"] not in blocks:
                        errors.append(f"{cid}.{bname}: choice goto -> unknown block '{opt['goto']}'")
                    if "next_chapter" in opt:
                        has_terminal = True
                        if not os.path.exists(os.path.join(STORY, opt["next_chapter"] + ".json")):
                            errors.append(f"{cid}.{bname}: choice next_chapter -> missing file '{opt['next_chapter']}'")
            if "next_chapter" in cmd:
                has_terminal = True
                if not os.path.exists(os.path.join(STORY, cmd["next_chapter"] + ".json")):
                    errors.append(f"{cid}.{bname}: next_chapter -> missing file '{cmd['next_chapter']}'")
            if "end" in cmd:
                has_terminal = True
            if "bg" in cmd and not asset_exists(BG, cmd["bg"]):
                warnings.append(f"{cid}.{bname}: missing bg asset '{cmd['bg']}'")
            if "show" in cmd and not asset_exists(CHAR, cmd["show"]):
                warnings.append(f"{cid}.{bname}: missing char asset '{cmd['show']}'")
    if not has_terminal:
        errors.append(f"{cid}: no terminal command (end / next_chapter) found")


def main():
    files = sorted(f for f in os.listdir(STORY)
                   if f.startswith("chapter") and f.endswith(".json"))
    if not files:
        print("No chapter files found.")
        sys.exit(1)
    for f in files:
        check_chapter(os.path.join(STORY, f))

    for w in warnings:
        print("WARN:", w)
    for e in errors:
        print("ERROR:", e)
    print(f"\n{len(files)} chapters | {len(errors)} errors | {len(warnings)} warnings")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
