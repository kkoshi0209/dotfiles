# ==================================================================
# 環境変数
# ==================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# path に同じ要素が二度入らないようにする（シェルを入れ子で起動しても伸びない）
typeset -U path PATH

path=("$HOME/Library/Python/3.9/bin" $path)

export EDITOR="code --wait"
export VISUAL="$EDITOR"

# ls / grep の色付け（macOS の BSD 版向け）
export CLICOLOR=1
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"

# brew の「この環境変数も設定できます」ヒントを抑制
export HOMEBREW_NO_ENV_HINTS=1

# ==================================================================
# バージョン管理ツール
# ==================================================================
eval "$(rbenv init -)"

# ==================================================================
# シェルの挙動
# ==================================================================
setopt AUTO_CD              # ディレクトリ名だけ打てば cd する
setopt AUTO_PUSHD           # cd した先をスタックに積む（cd -<Tab> で戻れる）
setopt PUSHD_IGNORE_DUPS    # スタックに同じディレクトリを重複させない
setopt PUSHD_SILENT         # cd のたびにスタックを表示しない
setopt EXTENDED_GLOB        # ~ ^ # をグロブで使えるようにする
setopt INTERACTIVE_COMMENTS # 対話シェルでも # 以降をコメント扱いにする
setopt NUMERIC_GLOB_SORT    # file10 が file9 の後に来るように並べる
setopt NO_BEEP
setopt NO_FLOW_CONTROL      # Ctrl-S / Ctrl-Q を他の用途に開放する

# ==================================================================
# 履歴
# ==================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000             # メモリ上に保持する件数
SAVEHIST=100000             # ファイルに保存する件数

setopt EXTENDED_HISTORY     # 実行時刻と所要時間も記録する
setopt SHARE_HISTORY        # 複数のターミナル間で履歴を共有する
setopt HIST_IGNORE_ALL_DUPS # 同じコマンドは古い方を捨てる
setopt HIST_IGNORE_SPACE    # 空白で始めたコマンドは履歴に残さない
setopt HIST_REDUCE_BLANKS   # 余分な空白を詰めてから保存する
setopt HIST_SAVE_NO_DUPS    # 保存時にも重複を落とす
setopt HIST_VERIFY          # !! などの展開結果を実行前に一度見せる

# ==================================================================
# 補完
# ==================================================================
setopt COMPLETE_IN_WORD     # 単語の途中からでも補完する
setopt ALWAYS_TO_END        # 補完したらカーソルを単語末尾へ移動する

# Homebrew が入れた補完定義（gh, terraform など）を読めるようにする
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
fi

autoload -Uz compinit
# zcompdump が 24 時間以内に更新されていれば再検査を省いて起動を速くする。
# -i は Homebrew のディレクトリが group-writable なことによる警告を黙らせる。
if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
  compinit -i
else
  compinit -i -C
fi

[ -d "$XDG_CACHE_HOME/zsh" ] || mkdir -p "$XDG_CACHE_HOME/zsh"

zstyle ':completion:*' menu select                  # 候補を矢印キーで選べるようにする
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''                # 候補を種類ごとにまとめる
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zstyle ':completion:*' rehash true                  # PATH に増えたコマンドを即補完する

# ==================================================================
# キーバインド
# ==================================================================
bindkey -e                                          # Emacs キーバインド

# ↑↓ で「今打ちかけの文字列で始まる履歴」だけを辿る
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^P'   up-line-or-beginning-search
bindkey '^N'   down-line-or-beginning-search

bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[3~' delete-char

# ==================================================================
# エイリアス
# ==================================================================
alias ll='ls -lhAF'
alias la='ls -A'
alias grep='grep --color=auto'
alias reload='exec zsh -l'

# ==================================================================
# マシン固有・秘密情報（リポジトリ管理外）
# ==================================================================
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# ==================================================================
# PostgreSQL
# ==================================================================
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
