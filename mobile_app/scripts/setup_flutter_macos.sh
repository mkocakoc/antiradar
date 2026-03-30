#!/usr/bin/env zsh
set -euo pipefail

# 1) Homebrew kontrol
if ! command -v brew >/dev/null 2>&1; then
  echo "[ERROR] Homebrew bulunamadı. Önce Homebrew kurun: https://brew.sh"
  exit 1
fi

# 2) Flutter kur
brew install --cask flutter

# 3) PATH önerisi
FLUTTER_BIN="/opt/homebrew/Caskroom/flutter/latest/flutter/bin"
if [[ -d "$FLUTTER_BIN" ]]; then
  if ! grep -q "$FLUTTER_BIN" "$HOME/.zshrc"; then
    echo "export PATH=\"$FLUTTER_BIN:\$PATH\"" >> "$HOME/.zshrc"
    echo "[INFO] PATH satırı .zshrc dosyasına eklendi. Yeni terminal açın veya source ~/.zshrc çalıştırın."
  fi
fi

# 4) Doctor
flutter doctor

echo "[OK] Flutter kurulumu tamamlandı."
