#!/usr/bin/env bash

ROOT_FOLDER="$1"

if [[ -z "$ROOT_FOLDER" || ! -d "$ROOT_FOLDER" ]]; then
  echo "Uso: $0 <root_folder>"
  exit 1
fi

shopt -s nullglob

for FILE in "$ROOT_FOLDER"/*; do
  [[ -f "$FILE" ]] || continue

  BASENAME="$(basename "$FILE")"

  if [[ "$BASENAME" =~ [Aa]ula[[:space:]]*([0-9]+) ]]; then
    NUMBER="${BASH_REMATCH[1]}"
    DIR="${NUMBER}_aula"

    mkdir -p "$ROOT_FOLDER/$DIR"
    mv "$FILE" "$ROOT_FOLDER/$DIR/"

    echo "✔ Movido: $BASENAME → $DIR/"
  else
    echo "⚠ Ignorado (sem 'Aula X'): $BASENAME"
  fi
done
