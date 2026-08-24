#!/usr/bin/env python3
"""PostToolUse hook: mermaid ブロック内の <br> を検出して Claude に差し戻す。

CLAUDE.md / skill の「ノードラベルに <br> を使わない」は助言にすぎず、
委任先が生成した doc に <br> が混入する事故が繰り返し起きたため、
決定論的な検出をフックに昇格させたもの。ブロックはせず、
additionalContext で Claude に修正を促す(PostToolUse は編集後に走るため)。
"""
import json
import re
import sys

FENCE = re.compile(r"^\s*(```+|~~~+)\s*([A-Za-z0-9_-]*)")
BR = re.compile(r"<br\s*/?>", re.IGNORECASE)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    path = (payload.get("tool_input") or {}).get("file_path") or ""
    if not path.endswith((".md", ".markdown")):
        return 0

    try:
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except OSError:
        return 0

    hits = []
    fence_marker = None
    in_mermaid = False
    for lineno, line in enumerate(lines, start=1):
        m = FENCE.match(line)
        if m:
            marker, lang = m.group(1), m.group(2).lower()
            if fence_marker is None:
                fence_marker, in_mermaid = marker[0] * 3, lang == "mermaid"
            elif marker.startswith(fence_marker):
                fence_marker, in_mermaid = None, False
            continue
        if in_mermaid and BR.search(line):
            hits.append((lineno, line.strip()))

    if not hits:
        return 0

    detail = "\n".join(f"  {path}:{n}: {text}" for n, text in hits[:10])
    message = (
        f"mermaid ブロック内に <br> が {len(hits)} 件あります。"
        "HTML タグを解釈しないビューアではそのまま文字列として表示されます。"
        "ノードを分割してチェーンで繋ぐ形に直してください(mermaid-rules skill のルール7)。\n"
        f"{detail}"
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": message,
            },
            "systemMessage": f"mermaid の <br> を {len(hits)} 件検出しました",
        },
        sys.stdout,
        ensure_ascii=False,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
