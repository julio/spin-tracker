#!/usr/bin/env python3
from pathlib import Path


PAGE_WIDTH = 612
PAGE_HEIGHT = 792
LEFT = 54
RIGHT = PAGE_WIDTH - 54
TOP = PAGE_HEIGHT - 54


def esc(text: str) -> str:
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def wrap(text: str, max_chars: int) -> list[str]:
    words = text.split()
    lines = []
    current = []
    count = 0
    for w in words:
        add = len(w) + (1 if current else 0)
        if count + add <= max_chars:
            current.append(w)
            count += add
        else:
            if current:
                lines.append(" ".join(current))
            current = [w]
            count = len(w)
    if current:
        lines.append(" ".join(current))
    return lines


def build_content() -> str:
    parts = []
    y = TOP

    def text_line(x: int, yy: int, font: str, size: int, text: str):
        parts.append(f"BT /{font} {size} Tf 1 0 0 1 {x} {yy} Tm ({esc(text)}) Tj ET")

    text_line(LEFT, y, "F2", 16, "Needl App Summary (Repo-Based)")
    y -= 20
    parts.append(f"{LEFT} {y} m {RIGHT} {y} l S")
    y -= 14

    sections = [
        ("What it is", [
            "Needl is a Flutter app for tracking vinyl collections, including owned and wanted albums.",
            "It uses Supabase for auth/data and includes Discogs and Spotify integrations.",
        ]),
        ("Who it's for", [
            "Primary persona: Not found in repo.",
            "Inferred from README and features: vinyl record collectors managing owned/wanted albums.",
        ]),
        ("What it does", [
            "Auth-gated app flow with Supabase Auth (email/password and Apple OAuth method).",
            "Stores and manages owned/wanted albums in Supabase with per-user RLS policies.",
            "Artist-based browsing/search with sort options, add/delete actions, and sync refresh.",
            "Fetches cover art via spotify-token Edge Function plus Spotify Web API search.",
            "Supports Discogs OAuth 1.0a connect flow, release search, and collection add/remove.",
            "Shows Sync Status and differences between Needl remote data and Discogs collection.",
            "Falls back to local JSON snapshot when Supabase is unavailable (offline read mode).",
        ]),
        ("How it works", [
            "Flutter UI in lib/ calls service layer (DataRepository, AuthService, DiscogsService).",
            "DataRepository loads Supabase first, caches in memory, and persists needl_snapshot.json.",
            "Write operations call SupabaseDataService, then refresh cache and save a new snapshot.",
            "Supabase tables: profiles, owned_albums, wanted_albums, discogs_tokens, discogs_oauth_temp.",
            "Supabase Edge Functions: spotify-token, discogs-request-token, discogs-access-token, discogs-api.",
        ]),
        ("How to run (minimal)", [
            "Create lib/config.dart from lib/config.dart.default and fill Supabase + Spotify values.",
            "Run flutter pub get",
            "Run flutter run",
            "Edge Function deployment commands beyond required env vars: Not found in repo.",
        ]),
    ]

    heading_size = 11
    body_size = 9
    leading = 11
    section_gap = 5
    max_chars = 95

    for heading, lines in sections:
        text_line(LEFT, y, "F2", heading_size, heading)
        y -= 12
        for item in lines:
            wrapped = wrap(item, max_chars)
            if not wrapped:
                continue
            text_line(LEFT + 2, y, "F1", body_size, "- " + wrapped[0])
            y -= leading
            for cont in wrapped[1:]:
                text_line(LEFT + 14, y, "F1", body_size, cont)
                y -= leading
        y -= section_gap

    text_line(
        LEFT,
        24,
        "F3",
        8,
        "Sources: README.md, lib/main.dart, lib/services/*, lib/*_view.dart, supabase/migrations, supabase/functions",
    )

    return "\n".join(parts) + "\n"


def write_pdf(path: Path, content: str) -> None:
    content_bytes = content.encode("latin-1", "replace")
    objs = []
    objs.append(b"1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n")
    objs.append(b"2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n")
    objs.append(
        f"3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 {PAGE_WIDTH} {PAGE_HEIGHT}] "
        f"/Resources << /Font << /F1 4 0 R /F2 5 0 R /F3 6 0 R >> >> /Contents 7 0 R >> endobj\n".encode(
            "ascii"
        )
    )
    objs.append(b"4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n")
    objs.append(b"5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> endobj\n")
    objs.append(b"6 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique >> endobj\n")
    objs.append(
        f"7 0 obj << /Length {len(content_bytes)} >> stream\n".encode("ascii")
        + content_bytes
        + b"endstream endobj\n"
    )

    out = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for obj in objs:
        offsets.append(len(out))
        out.extend(obj)

    xref_start = len(out)
    out.extend(f"xref\n0 {len(objs)+1}\n".encode("ascii"))
    out.extend(b"0000000000 65535 f \n")
    for off in offsets[1:]:
        out.extend(f"{off:010d} 00000 n \n".encode("ascii"))
    out.extend(
        f"trailer << /Size {len(objs)+1} /Root 1 0 R >>\nstartxref\n{xref_start}\n%%EOF\n".encode("ascii")
    )
    path.write_bytes(out)


def main():
    out_dir = Path("output/pdf")
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "needl-one-page-summary.pdf"
    content = build_content()
    write_pdf(out_path, content)
    print(out_path)


if __name__ == "__main__":
    main()
