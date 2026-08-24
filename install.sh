#!/usr/bin/env bash
#
# dotfiles のシンボリックリンクを張る。
# 何度実行しても同じ結果になる（冪等）。
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

# "リポジトリ内の相対パス:リンクを作る場所"
# リンク先に空白は含まれうるが : は含まれないので : を区切りに使う
LINKS=(
  "zsh/.zshrc:$HOME/.zshrc"
  "zsh/.zprofile:$HOME/.zprofile"
  "zsh/.gemrc:$HOME/.gemrc"
  "git/.gitconfig:$HOME/.gitconfig"
  "git/gitignore_global:$HOME/.config/git/ignore"
  "vscode/settings.json:$HOME/Library/Application Support/Code/User/settings.json"
  "karabiner/karabiner.json:$HOME/.config/karabiner/karabiner.json"
  ".claude/settings.json:$HOME/.claude/settings.json"
  ".claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
  ".claude/skills/herdr-delegate:$HOME/.claude/skills/herdr-delegate"
  ".claude/skills/mermaid-rules:$HOME/.claude/skills/mermaid-rules"
  ".claude/agents:$HOME/.claude/agents"
  "ghostty/config:$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  "herdr/config.toml:$HOME/.config/herdr/config.toml"
)

for entry in "${LINKS[@]}"; do
  src="$DOTFILES/${entry%%:*}"
  dest="${entry#*:}"

  if [ ! -e "$src" ]; then
    echo "skip    $dest (実体が無い: $src)"
    continue
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      echo "ok      $dest"
      continue
    fi
    # 別の場所を指すリンクは中身を持たないので退避せず張り替える
    echo "relink  $dest"
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.$STAMP.bak"
    echo "backup  $dest -> $(basename "$dest").$STAMP.bak"
  fi

  ln -sfn "$src" "$dest"
  echo "link    $dest -> $src"
done

# VS Code の "code" コマンドを PATH に通す。
# 手動インストールした VS Code はこのコマンドが無いことがあり、そのまま
# brew bundle を実行すると code を探しに行って visual-studio-code の cask を
# 勝手に入れようとし、既存アプリと衝突して失敗する。事前にリンクしておくことで防ぐ。
BREW_PREFIX="$(command -v brew >/dev/null 2>&1 && brew --prefix || echo /usr/local)"
CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
CODE_LINK="$BREW_PREFIX/bin/code"

if command -v code >/dev/null 2>&1; then
  echo "ok      code ($(command -v code))"
elif [ -x "$CODE_BIN" ]; then
  mkdir -p "$(dirname "$CODE_LINK")"
  ln -sfn "$CODE_BIN" "$CODE_LINK"
  echo "link    $CODE_LINK -> $CODE_BIN"
else
  echo "skip    code (VS Code 本体が無い: $CODE_BIN)"
fi

echo
echo "完了。次は: brew bundle --file=$DOTFILES/Brewfile"
