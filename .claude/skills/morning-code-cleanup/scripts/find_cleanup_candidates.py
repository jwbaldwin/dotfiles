#!/usr/bin/env python3
from __future__ import annotations

import os
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
EXCLUDED_DIR_PARTS = {
    ".git",
    ".turbo",
    "coverage",
    "dist",
    "node_modules",
}
EXCLUDED_FILE_NAMES = {
    "openapi.d.ts",
    "openapi.yaml",
    "pnpm-lock.yaml",
}


def is_excluded(path: Path) -> bool:
    rel_parts = path.relative_to(ROOT).parts
    if any(part in EXCLUDED_DIR_PARTS for part in rel_parts):
        return True
    if path.name in EXCLUDED_FILE_NAMES:
        return True
    if path.name.startswith("monolith-v4-"):
        return True
    if rel_parts[:2] == ("packages", "api-clients") and path.name == "types.ts":
        return True
    return False


def iter_code_files() -> list[Path]:
    exts = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"}
    return [
        path
        for path in ROOT.rglob("*")
        if path.is_file() and path.suffix in exts and not is_excluded(path)
    ]


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors="ignore")
    except OSError:
        return ""


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def rg(pattern: str, *extra: str, limit: int = 8) -> list[str]:
    cmd = [
        "rg",
        "--line-number",
        "--color",
        "never",
        pattern,
        str(ROOT),
        "--glob",
        "!node_modules",
        "--glob",
        "!dist",
        "--glob",
        "!coverage",
        "--glob",
        "!openapi.yaml",
        "--glob",
        "!openapi.d.ts",
        "--glob",
        "!pnpm-lock.yaml",
        "--glob",
        "!**/pnpm-lock.yaml",
        "--glob",
        "!**/monolith-v4-*",
        "--glob",
        "!packages/api-clients/**/types.ts",
        *extra,
    ]
    try:
        output = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
        ).stdout
    except FileNotFoundError:
        return ["ripgrep is required for detailed evidence"]

    lines = []
    for line in output.splitlines():
        try:
            path_part, rest = line.split(":", 1)
            lines.append(f"{rel(Path(path_part))}:{rest}")
        except ValueError:
            lines.append(line)
        if len(lines) >= limit:
            break
    return lines


def print_candidate(
    score: int,
    lane: str,
    review: str,
    why: str,
    evidence: list[str],
    probe: list[str],
    verify: list[str],
) -> None:
    print(f"\n[{score}] {lane}")
    print(f"Review shape: {review}")
    print(f"Why it matters: {why}")
    print("Evidence:")
    for item in evidence:
        print(f"  - {item}")
    print("Probe:")
    for item in probe:
        print(f"  - {item}")
    print("Verify:")
    for item in verify:
        print(f"  - {item}")


def line_count(path: Path) -> int:
    return read_text(path).count("\n") + 1


def large_file_candidates(files: list[Path]) -> None:
    large_files = sorted(
        ((line_count(path), path) for path in files if path.suffix in {".ts", ".tsx", ".js", ".jsx"}),
        reverse=True,
    )
    large_files = [(count, path) for count, path in large_files if count >= 750][:8]
    if not large_files:
        return

    evidence = [f"{rel(path)} ({count} lines)" for count, path in large_files]
    probe = [
        "Pick one file, then search within it for cohesive private helpers, parser/mapper blocks, repeated test setup, or nested functions.",
        "Use `rg -n \"^(function|async function|const .* =|class |describe\\()\" <file>` and inspect only one promising region.",
        "Prefer moving a cohesive private block verbatim into a well-named sibling file over redesigning the flow.",
    ]
    print_candidate(
        5,
        "Chip away at large files",
        "Good when the diff is mostly moved code plus imports and the original file reads easier.",
        "Large files accumulate unrelated concepts; extracting one named concept improves local reasoning without a broad rewrite.",
        evidence,
        probe,
        ["pnpm fmt", "pnpm types", "pnpm lint", "targeted test for the touched file/package"],
    )


def duplicated_test_setup_candidates(files: list[Path]) -> None:
    scored: list[tuple[int, Path, int, int]] = []
    for path in files:
        if not re.search(r"(\.test|\.spec|fixtures|mocks|assertions)", path.name):
            continue
        text = read_text(path)
        setup_count = len(re.findall(r"\b(beforeEach|vi\.fn|mockResolvedValue|mockRejectedValue|expect\.objectContaining)\b", text))
        if setup_count >= 12:
            scored.append((setup_count, path, line_count(path), text.count("describe(")))

    if not scored:
        return

    evidence = [
        f"{rel(path)} ({setup_count} setup/assertion signals, {lines} lines)"
        for setup_count, path, lines, _ in sorted(scored, reverse=True)[:8]
    ]
    print_candidate(
        4,
        "Collapse duplicated test setup",
        "Good when extracting a local helper or using `test-support/` makes test intent clearer.",
        "Repeated test ceremony hides behavior and is a common source of agent-generated cruft.",
        evidence,
        [
            "Read TESTING.md first.",
            "Search `test-support/{fixtures,mocks,assertions}.ts` and nearby test helpers before adding anything new.",
            "Only extract setup that is repeated in this file or already matches a shared helper taxonomy.",
        ],
        ["pnpm fmt", "pnpm types", "pnpm lint", "pnpm test -- <touched-test-file-or-package>"],
    )


def helper_reuse_candidates(files: list[Path]) -> None:
    helper_files = [
        path
        for path in files
        if re.search(r"(helper|helpers|utils|fixture|fixtures|mock|mocks|assertion|assertions)", path.name)
    ]
    if not helper_files:
        return

    base_names = Counter(path.stem.replace(".test", "") for path in helper_files)
    repeated = [name for name, count in base_names.items() if count > 1]
    evidence = [rel(path) for path in helper_files[:30]]
    if repeated:
        evidence.insert(0, f"Repeated helper-ish basenames: {', '.join(sorted(repeated)[:8])}")

    print_candidate(
        4,
        "Reuse canonical helpers or consolidate helper drift",
        "Good when a local helper duplicates an existing helper and the replacement is obvious.",
        "Agentic code often creates local `utils` and `helpers` instead of using the repo's shared helper taxonomy.",
        evidence[:12],
        [
            "Compare local helpers against `test-support/` and package-level helper files.",
            "Prefer deleting a local helper in favor of a canonical helper over creating another helper.",
            "Do not consolidate helpers with different semantics just because their names look similar.",
        ],
        ["pnpm fmt", "pnpm types", "pnpm lint", "targeted tests if helper behavior is touched"],
    )


def type_hatch_candidates() -> None:
    evidence = rg(
        r"(:\s*any\b|\bas any\b|as unknown as|@ts-ignore|@ts-expect-error|eslint-disable)",
        "--glob",
        "*.{ts,tsx,js,jsx}",
        limit=12,
    )
    if not evidence:
        return
    print_candidate(
        3,
        "Tighten obvious type escape hatches",
        "Good when the stronger type follows from an existing schema, helper return type, or local mock type.",
        "Type escape hatches make invariants harder to see and encourage future defensive branches.",
        evidence,
        [
            "Look for an existing exported type, schema-derived type, or test helper type before inventing one.",
            "Skip casts around broken generated types or SDK edges unless the fix is already obvious.",
        ],
        ["pnpm fmt", "pnpm types", "pnpm lint", "targeted tests if touched"],
    )


def logging_candidates() -> None:
    pino_order = rg(
        r"log\.(debug|info|warn|error|fatal)\(\"[^\"]+\",\s*\{",
        "--glob",
        "*.{ts,tsx,js,jsx}",
        limit=8,
    )
    req_log = rg(
        r"\b(req\.log|request\.log)\.(debug|info|warn|error|fatal)\(",
        "--glob",
        "apps/api/src/**/*.ts",
        limit=8,
    )
    evidence = pino_order + req_log
    if not evidence:
        return
    print_candidate(
        3,
        "Clean behavior-adjacent logging",
        "Good when the repo logging guide clearly defines the desired structured shape.",
        "Correct structured logging improves debugging and prevents useful fields from disappearing in Datadog/Graylog.",
        evidence[:12],
        [
            "Read AGENTS.md logging guidance before editing.",
            "Prefer `createMcpLogger()` in MCP request/tool flows.",
            "Keep event meaning the same; change only structure, binding, or vague wording.",
        ],
        ["pnpm fmt", "pnpm types", "pnpm lint", "targeted tests if logger expectations exist"],
    )


def style_candidates() -> None:
    import_evidence = rg(r"from ['\"]\.\./", "--glob", "apps/api/src/**/*.{ts,tsx}", limit=10)
    todo_evidence = rg(
        r"\b(TODO|FIXME|HACK|XXX|temporary|workaround)\b",
        "--glob",
        "*.{ts,tsx,js,jsx,mjs,cjs}",
        limit=10,
    )
    evidence = import_evidence + todo_evidence
    if not evidence:
        return
    print_candidate(
        2,
        "Clean local style, imports, names, or stale comments",
        "Good as a fallback or when one file has obvious clustered drift.",
        "Small consistency fixes are worthwhile, but should not crowd out deeper readability work every morning.",
        evidence[:16],
        [
            "Prefer clustered fixes in one file or one convention over repo-wide churn.",
            "For TODOs, remove only stale comments or convert comments into clearer code; do not delete live product context.",
            "For names, rename only when the new name is obviously domain-specific and all call sites are easy to inspect.",
        ],
        ["pnpm fmt", "pnpm types", "pnpm lint"],
    )


def main() -> int:
    if not ROOT.exists():
        print(f"Root does not exist: {ROOT}", file=sys.stderr)
        return 1

    if not (ROOT / "pnpm-workspace.yaml").exists():
        print(f"Warning: {ROOT} does not look like the MCP repo root.", file=sys.stderr)

    files = iter_code_files()
    print(f"# MCP morning cleanup candidates for {ROOT}")
    print("Use these as leads. Confirm by reading code before editing.")

    large_file_candidates(files)
    duplicated_test_setup_candidates(files)
    helper_reuse_candidates(files)
    type_hatch_candidates()
    logging_candidates()
    style_candidates()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
