#!/usr/bin/env bash
set -euo pipefail

adapters_dir="$(cd "$(dirname "$0")" && pwd)"
swiftui_dir="$adapters_dir/swiftui"
index_file="$adapters_dir/INDEX.md"
failed=0

for file in "$swiftui_dir"/*.swift; do
  name="$(basename "$file")"
  if ! grep -Fq "swiftui/$name" "$index_file"; then
    echo "missing INDEX.md entry: $name" >&2
    failed=1
  fi
done

while IFS= read -r indexed_path; do
  if [[ ! -f "$adapters_dir/$indexed_path" ]]; then
    echo "INDEX.md points to missing adapter: $indexed_path" >&2
    failed=1
  fi
done < <(
  grep -oE '\(swiftui/[^)]+\.swift\)' "$index_file" |
    tr -d '()' |
    sort -u
)

if grep -En 'MARK: - Unfinished|wanted at|<Type>|<value>|Damus|IceCubes|Yattee|AppAccount|SupportAppView|TimelineCache|[Ff]resh draft|[Cc]ompiler asked|repair:' "$swiftui_dir"/*.swift; then
  echo "generated diagnostics or application-owned names found" >&2
  failed=1
fi

if command -v swiftc >/dev/null 2>&1; then
  for file in "$swiftui_dir"/*.swift; do
    if ! swiftc -frontend -parse "$file"; then
      echo "Swift parse failed: $(basename "$file")" >&2
      failed=1
    fi
  done
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "validated $(find "$swiftui_dir" -maxdepth 1 -name '*.swift' | wc -l | tr -d ' ') SwiftUI adapters"
