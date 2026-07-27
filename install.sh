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

echo
echo "完了。次は: brew bundle --file=$DOTFILES/Brewfile"
