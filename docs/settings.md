# 設定リファレンス

このリポジトリに入っている設定を、1項目ずつ「何をするか / なぜ入れたか」で説明する。
「これ何だっけ」となったときにここを引く。

- どこに何があるかは [structure.md](structure.md)
- 仕組み（リンクの張られ方・読み込み順序）は [how-it-works.md](how-it-works.md)

- [zsh/.zprofile](#zshzprofile)
- [zsh/.zshrc](#zshzshrc)
- [zsh/.gemrc](#zshgemrc)
- [git/.gitconfig](#gitgitconfig)
- [git/gitignore_global](#gitgitignore_global)
- [vscode/settings.json](#vscodesettingsjson)
- [karabiner/karabiner.json](#karabinerkarabinerjson)
- [Brewfile](#brewfile)
- [install.sh](#installsh)
- [.gitignore（リポジトリ自身）](#gitignoreリポジトリ自身)

---

## zsh/.zprofile

`~/.zprofile` は**ログインシェルの起動時に1回だけ**読まれる。
毎回のターミナル起動で読まれる `.zshrc` とは別物で、「一度決めれば変わらないもの」を置く。

```zsh
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```

Homebrew の環境変数をまとめて設定する。具体的には以下が入る。

| 変数 | 中身 | 用途 |
|---|---|---|
| `HOMEBREW_PREFIX` | `/opt/homebrew` | `.zshrc` から補完定義の場所を組み立てるのに使う |
| `HOMEBREW_CELLAR` | `/opt/homebrew/Cellar` | 実体のインストール先 |
| `HOMEBREW_REPOSITORY` | `/opt/homebrew` | brew 自身の git リポジトリ |
| `PATH` | 先頭に `/opt/homebrew/bin` `/opt/homebrew/sbin` | brew で入れたコマンドを優先する |
| `MANPATH` / `INFOPATH` | brew の man ページ | `man` が brew 版を引けるようにする |

Apple Silicon の Mac では Homebrew が `/opt/homebrew` に入るため、
`/usr/local` 前提の Intel Mac 用の手順とはパスが違う点に注意。

> **なぜ `.zshrc` ではなく `.zprofile` なのか**
> `PATH` の組み立ては1回で足りる。`.zshrc` に書くとシェルを入れ子で起動するたびに
> 実行され、`PATH` が伸びていく。

---

## zsh/.zshrc

`~/.zshrc` は**対話シェルを開くたびに毎回**読まれる。
補完・履歴・キーバインドなど「対話操作に関わるもの」を置く。

### 環境変数

```zsh
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
```

設定ファイルとキャッシュの置き場所を決める XDG Base Directory の標準変数。
`${VAR:-既定値}` は「すでに設定されていればそれを尊重し、無ければ既定値」という書き方。
このリポジトリでも `~/.config/git/ignore` や `~/.config/karabiner/` を使っている。

```zsh
typeset -U path PATH
```

`path` 配列から重複を自動的に取り除く（`-U` は unique）。
zsh では `path`（配列）と `PATH`（`:` 区切りの文字列）が連動しており、片方を変えると
もう片方も変わる。これを入れておくと、シェルを入れ子で起動しても `PATH` が伸びない。

```zsh
path=("$HOME/Library/Python/3.9/bin" $path)
```

macOS 標準の Python 3.9 に `pip install --user` で入れたコマンドを使えるようにする。
文字列連結 (`export PATH="...:$PATH"`) ではなく配列操作にしているのは、
上の `typeset -U` による重複除去を効かせるため。

```zsh
export EDITOR="code --wait"
export VISUAL="$EDITOR"
```

`git commit` などがエディタを開くときに VS Code を使う。
`--wait` は「エディタを閉じるまでコマンド側を待たせる」オプションで、
これが無いと VS Code が即座に制御を返すため git がメッセージ未入力のまま進んでしまう。

`VISUAL` は `EDITOR` より優先される変数で、両方見るツールがあるため揃えておく。

```zsh
export CLICOLOR=1
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"
```

macOS の `ls` は BSD 版で、GNU 版の `LS_COLORS` ではなく `CLICOLOR` / `LSCOLORS` を見る。
`CLICOLOR=1` で色付けを有効にし、`LSCOLORS` で配色を指定する。
11 組 22 文字で「ディレクトリ、シンボリックリンク、…」の順に前景色・背景色を指定する形式。

```zsh
export HOMEBREW_NO_ENV_HINTS=1
```

`brew install` のたびに出る「この環境変数も設定できます」というヒントを黙らせる。

### バージョン管理ツール

```zsh
eval "$(rbenv init -)"
```

rbenv を有効にする。実際には以下をまとめて行っている。

1. `~/.rbenv/shims` を `PATH` の先頭に入れる（`ruby` や `gem` を rbenv 経由にする）
2. `rbenv` をシェル関数として定義する（`rbenv shell` でバージョンを切り替えるため）
3. rbenv 用の補完を読み込む

`compinit`（後述）より前に置いているのは、rbenv が `fpath` に補完定義を追加するため。

### シェルの挙動（setopt）

| オプション | 効果 |
|---|---|
| `AUTO_CD` | `cd` を省略できる。`~/dotfiles` と打つだけで移動する |
| `AUTO_PUSHD` | `cd` した先をディレクトリスタックに積む |
| `PUSHD_IGNORE_DUPS` | スタックに同じディレクトリを重複させない |
| `PUSHD_SILENT` | `cd` のたびにスタックの中身を表示しない |
| `EXTENDED_GLOB` | `~` `^` `#` をグロブで使えるようにする |
| `INTERACTIVE_COMMENTS` | 対話シェルでも `#` 以降をコメント扱いにする |
| `NUMERIC_GLOB_SORT` | `file9` → `file10` の順に並べる（辞書順だと逆になる） |
| `NO_BEEP` | 補完の候補が無いときなどに鳴らさない |
| `NO_FLOW_CONTROL` | `Ctrl-S` / `Ctrl-Q` を端末のフロー制御から解放する |

**`AUTO_PUSHD` が効いてくる場面**: 積んだスタックは `cd -<Tab>` で一覧でき、
番号を選べば直接そこへ戻れる。深いディレクトリを行き来するときに効く。

**`EXTENDED_GLOB` が必要な理由**: `.zshrc` 内の `$HOME/.zcompdump(#qN.mh+24)` という
書き方（グロブ修飾子の明示形式）がこのオプションを必要とする。

**`NO_FLOW_CONTROL` の意味**: 端末はもともと `Ctrl-S` を「画面出力の一時停止」に
割り当てている。これを無効にしないと、`Ctrl-S` を押した瞬間にシェルが固まったように
見える（`Ctrl-Q` で復帰する）。無効化することでキー自体を別用途に使える。

### 履歴

```zsh
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000    # メモリ上に保持する件数
SAVEHIST=100000    # ファイルに保存する件数
```

`HISTSIZE` と `SAVEHIST` は別物で、`SAVEHIST` が小さいとシェル終了時に切り詰められる。
両方揃えておくのが安全。

| オプション | 効果 |
|---|---|
| `EXTENDED_HISTORY` | 実行時刻と所要時間も記録する（`history -i` で見える） |
| `SHARE_HISTORY` | 複数のターミナル間で履歴をリアルタイムに共有する |
| `HIST_IGNORE_ALL_DUPS` | 同じコマンドが再度実行されたら古い方を削除する |
| `HIST_IGNORE_SPACE` | 空白で始めたコマンドは履歴に残さない |
| `HIST_REDUCE_BLANKS` | 余分な空白を詰めてから保存する |
| `HIST_SAVE_NO_DUPS` | ファイルに書き出す時点でも重複を落とす |
| `HIST_VERIFY` | `!!` などの履歴展開を、実行前に一度コマンドラインへ展開して見せる |

**`SHARE_HISTORY` の効果**: 既定では各ターミナルが自分の履歴を持ち、終了時に書き出す。
そのため「隣のタブで打ったコマンド」が見えない。これを有効にすると、コマンドを打った
瞬間に共有され、どのタブからでも `↑` で辿れる。

**`HIST_IGNORE_SPACE` の使いどころ**: 先頭に空白を1つ入れて実行すれば履歴に残らない。
トークンを含むコマンドを一度だけ叩くときに使う。

**`HIST_VERIFY` の効果**: `!!`（直前のコマンド）や `!$`（直前の最後の引数）を
展開した結果がそのまま実行されず、コマンドラインに展開された状態で止まる。
`sudo !!` の中身を確認してから Enter を押せる。

### 補完

```zsh
setopt COMPLETE_IN_WORD   # 単語の途中からでも補完する
setopt ALWAYS_TO_END      # 補完したらカーソルを単語末尾へ移動する
```

既定では単語の末尾でしか補完が効かない。`COMPLETE_IN_WORD` があると
`foo|bar`（`|` はカーソル）の位置でも補完できる。

```zsh
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
fi
```

`fpath` は zsh が補完定義（`_gh`、`_terraform` など）を探すディレクトリのリスト。
Homebrew は各パッケージの補完定義を `share/zsh/site-functions` に置くため、
ここを追加しないと `gh pr <Tab>` のようなサブコマンド補完が効かない。

`HOMEBREW_PREFIX` は `.zprofile` の `brew shellenv` で設定される。
未設定でも壊れないよう `-n` で存在を確認している。

```zsh
autoload -Uz compinit
if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
  compinit -i
else
  compinit -i -C
fi
```

zsh の補完システムを初期化する。`compinit` は `fpath` 内の補完定義を全部走査して
`~/.zcompdump` にキャッシュを作るが、これが起動時間の大半を占める。

グロブ修飾子 `(#qN.mh+24)` の読み方:

| 部分 | 意味 |
|---|---|
| `(#q...)` | 以降をグロブ修飾子として解釈する（`EXTENDED_GLOB` が必要） |
| `N` | マッチしなければエラーではなく空にする |
| `.` | 通常ファイルのみ |
| `mh+24` | 最終更新が 24 時間より前 |

つまり「`.zcompdump` が 24 時間以上前のものなら」という条件になり、

- **古い（マッチする＝非空）** → `compinit -i` でフル再構築する
- **新しい / 存在しない** → `compinit -i -C` でチェックを省いて即読み込む

`-C` はキャッシュの妥当性検査をスキップするオプション。
`-i` は「安全でないディレクトリを警告せず無視する」オプションで、
Homebrew のディレクトリが group-writable なために出る
`zsh compinit: insecure directories` 警告を抑えるために付けている。

```zsh
zstyle ':completion:*' menu select
```

補完候補が複数あるとき、一覧を出したうえで**矢印キーで選べる**ようにする。

```zsh
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
```

補完のマッチ規則を段階的に緩めていく指定。前から順に試し、候補が無ければ次へ進む。

| 規則 | 意味 |
|---|---|
| `m:{a-zA-Z}={A-Za-z}` | 大文字小文字を区別しない（`down` で `Downloads` に当たる） |
| `r:\|=*` | 入力の後ろに任意の文字列があってよい（部分一致の右側） |
| `l:\|=* r:\|=*` | 入力の前後どちらにも任意の文字列があってよい（中間一致） |

```zsh
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
```

補完候補の一覧をファイル種別ごとに色分けする。
`${(s.:.)VAR}` は「`VAR` を `:` で分割して配列にする」という zsh のパラメータ展開。
`LS_COLORS` は macOS の既定では未設定なので、その場合は何も起きない
（GNU coreutils を入れたときに自動で効くようにしてある）。

```zsh
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
```

候補を「コマンド」「ファイル」「オプション」などの種類ごとにまとめ、
各グループに黄色の見出しを付ける。`%F{色}` … `%f` が色指定の開始と終了。

```zsh
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
```

補完結果をキャッシュする。インストール済みパッケージ一覧を引くような、
計算に時間のかかる補完（`brew` など）で効く。

```zsh
zstyle ':completion:*' rehash true
```

`brew install` で新しいコマンドを入れた直後でも、シェルを開き直さずに補完できる。
既定では zsh が起動時に `PATH` の内容をキャッシュするため、新しいコマンドを見つけられない。

### キーバインド

```zsh
bindkey -e
```

Emacs 風のキーバインドを使う（`Ctrl-A` 行頭、`Ctrl-E` 行末、`Ctrl-K` 行末まで削除など）。
zsh は `EDITOR` に `vi` が含まれると自動的に vi モードになるため、明示しておく。

```zsh
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^P'   up-line-or-beginning-search
bindkey '^N'   down-line-or-beginning-search
```

**この設定は日常の使い勝手が一番変わる。**

既定の `↑` は履歴を単純に1つずつ遡る。この設定を入れると、
**すでに入力した文字列で始まる履歴だけ**を遡るようになる。

例えば `git p` まで打ってから `↑` を押すと、`git push`、`git pull` … と
`git p` で始まる履歴だけが順に出る。プラグインを入れなくても zsh 標準機能で実現できる。

`zle -N` は「この関数を ZLE（zsh のライン編集機能）のウィジェットとして登録する」宣言。
`^[[A` は `↑` が送るエスケープシーケンス（`^[` = ESC）。
`^P` / `^N` にも同じ動作を割り当てているのは、`Ctrl-P` / `Ctrl-N` でも同じ操作をするため。

```zsh
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[3~' delete-char
```

`Home` / `End` / `Delete` キーを効くようにする。
これらは端末エミュレータによって送るシーケンスが違い、既定では効かないことがある。

### エイリアス

| エイリアス | 中身 | 意味 |
|---|---|---|
| `ll` | `ls -lhAF` | 詳細表示 + 人間が読めるサイズ + ドットファイル込み + 種別記号 |
| `la` | `ls -A` | ドットファイル込みの一覧（`.` と `..` は除く） |
| `grep` | `grep --color=auto` | マッチ部分に色を付ける |
| `reload` | `exec zsh -l` | 設定を編集したあとログインシェルを丸ごと起動し直す |

`ls -A` の `-A` は `-a` と違い `.`（カレント）と `..`（親）を出さない。
`-F` はディレクトリに `/`、実行ファイルに `*`、シンボリックリンクに `@` を付ける。

### ローカル設定の読み込み

```zsh
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

`~/.zshrc.local` があれば読む。無ければ何もしない。
業務用の環境変数やその機体だけの `PATH` をここに逃がすことで、
リポジトリ側に秘密情報を入れずに済む。**このファイルはリポジトリに入れない。**

---

## zsh/.gemrc

```yaml
gem: --no-document
```

`gem install` のたびに rdoc / ri のドキュメントを生成するのをやめる。
生成には時間がかかり、実際に `ri` でドキュメントを引く機会はほぼ無い。
`bundle install` が体感で速くなる。

> 移行前の `~/.gemrc` はこの行が3回重複していた。効果は同じなので1行に集約した。

---

## git/.gitconfig

ベースは [Git のコア開発者が使っている設定](https://blog.gitbutler.com/how-git-core-devs-configure-git)。

### `[user]`

```ini
name = kkoshi0209
email = doradorayuji@gmail.com
```

コミットに記録される名前とメールアドレス。
**仕事用など別のアドレスを使いたい場合は `~/.gitconfig.local` で上書きする**（後述）。

### `[core]`

| 設定 | 効果 |
|---|---|
| `excludesfile = ~/.config/git/ignore` | グローバル gitignore の場所。既定は `~/.config/git/ignore` だが明示している |
| `quotepath = false` | **日本語ファイル名をそのまま表示する** |
| `precomposeunicode = true` | **macOS の濁点分解問題を吸収する** |
| `untrackedCache = true` | 未追跡ファイルの走査結果をキャッシュし `git status` を速くする |

**`quotepath = false`**
既定では git が非 ASCII のファイル名を `\346\227\245...` のような8進エスケープで表示する。
`false` にすると `日本語.txt` とそのまま出る。日本語を扱うなら実質必須。

**`precomposeunicode = true`**
macOS のファイルシステムは「が」を「か」+「濁点」に分解した形（NFD）で保存する。
一方 Linux や Windows は合成済みの形（NFC）を使う。この差のせいで、
同じ名前のはずのファイルが git 上では別物として扱われることがある。
`true` にすると git が NFC に正規化してから記録するため、この食い違いが起きない。

### `[init]`

```ini
defaultBranch = main
```

`git init` で作られる最初のブランチ名。指定しないと `master` になり警告が出る。

### `[column]` / `[branch]` / `[tag]`

| 設定 | 効果 |
|---|---|
| `column.ui = auto` | `git branch` などの一覧を端末幅に合わせて多段組みで出す |
| `branch.sort = -committerdate` | ブランチを**最近コミットした順**に並べる（既定はアルファベット順） |
| `tag.sort = version:refname` | `v2` → `v10` の順に並べる（辞書順だと `v10` が `v2` より前に来る） |

`branch.sort = -committerdate` は、ブランチが増えたときに
「今週触っていたブランチ」が一覧の先頭に来るので探しやすい。

### `[push]`

| 設定 | 効果 |
|---|---|
| `default = simple` | 同名のリモートブランチにだけ push する（現在の既定値。明示している） |
| `autoSetupRemote = true` | **新規ブランチの初回 push で `-u` が不要になる** |
| `followTags = true` | コミットに紐づく注釈付きタグも一緒に push する |

**`autoSetupRemote = true`**
これが無いと、新しく切ったブランチを push するとき毎回
`fatal: The current branch xxx has no upstream branch` と言われ、
`git push -u origin xxx` を打ち直すことになる。
`true` にすると `git push` だけで upstream も設定される。

### `[fetch]`

| 設定 | 効果 |
|---|---|
| `prune = true` | リモートで削除済みのブランチをローカルの追跡参照からも消す |
| `pruneTags = true` | タグについても同様にする |
| `all = true` | `git fetch` ですべてのリモートを取りに行く |

`prune` が無いと、マージ済みで消されたブランチが `git branch -r` に延々と残り続ける。

### `[pull]`

```ini
rebase = false
```

`git pull` の挙動を「merge コミットを作る従来の動作」に固定する。

git は `pull.rebase` が未設定だと警告を出す。放置すると
「設定した覚えがないのにマシンによって挙動が違う」状態になるため、明示している。
rebase 派に転向するときはここを `true` にする。

### `[diff]`

| 設定 | 効果 |
|---|---|
| `algorithm = histogram` | 差分アルゴリズム。**関数を移動したときの差分が読みやすい** |
| `colorMoved = plain` | 移動しただけの行を、追加/削除とは別の色で示す |
| `mnemonicPrefix = true` | 差分のパス接頭辞を `a/` `b/` ではなく意味のある文字にする |
| `renames = true` | ファイル名の変更を「削除+追加」ではなく「リネーム」と認識する |

**`algorithm = histogram`**
既定の Myers アルゴリズムは「最小の差分」を求めるため、
関数を上下に入れ替えただけでも閉じ括弧の位置がずれて読みにくい差分になりがち。
histogram は行の出現頻度を考慮するため、人間が見て自然な塊で差分が出る。

**`mnemonicPrefix = true`**
`a/` `b/` の代わりに `i/`（index = ステージ）、`w/`（work tree = 作業ツリー）、
`c/`（commit）が使われる。何と何を比較しているのかが接頭辞だけで分かる。

### `[merge]`

```ini
conflictstyle = zdiff3
```

衝突時のマーカーの形式。既定の `merge` は「自分の変更」と「相手の変更」しか出さないが、
`zdiff3` は**共通の祖先（元の内容）も表示する**。

```
<<<<<<< HEAD
自分の変更
||||||| 共通の祖先
元の内容          ← zdiff3 だとこれが出る
=======
相手の変更
>>>>>>> branch
```

元が何だったか分かるので、「相手が何を消したのか」「自分が何を足したのか」を
推測せずに済む。git 2.35 以降で使える（`diff3` は同じ機能の旧形式）。

### `[rerere]`

```ini
enabled = true
autoupdate = true
```

**rerere = REuse REcorded REsolution**（記録した解決の再利用）。

一度解決した衝突の「どう解いたか」を記録しておき、同じ衝突に再び出会ったときに
自動で同じ解決を適用する。長命なブランチを繰り返し rebase するときに効く。
`autoupdate = true` は、自動解決した結果をステージまで済ませる指定。

### `[rebase]`

| 設定 | 効果 |
|---|---|
| `autoSquash = true` | `fixup!` / `squash!` で始まるコミットを自動で並べ替える |
| `autoStash = true` | 未コミットの変更を自動で stash し、終わったら戻す |
| `updateRefs = true` | 積み上げたブランチの参照もまとめて付け替える（git 2.38+） |

**`autoStash = true`**
既定では作業中の変更があると rebase が拒否される。この設定があると
git が自動で退避 → rebase → 復帰までやってくれる。

**`updateRefs = true`**
`feature-a` の上に `feature-b` を積んでいるとき、`feature-a` を rebase すると
既定では `feature-b` が古いコミットを指したまま取り残される。
この設定があると連動して付け替わる。

### `[commit]` / `[help]` / `[status]` / `[log]` / `[color]`

| 設定 | 効果 |
|---|---|
| `commit.verbose = true` | コミットメッセージの編集画面に、コミットされる差分を表示する |
| `help.autocorrect = prompt` | `git stauts` のような打ち間違いを、確認してから実行する |
| `status.showUntrackedFiles = all` | 未追跡ディレクトリの中身をファイル単位で表示する |
| `log.date = iso` | 日付を `2026-07-27 17:23:02 +0900` 形式で表示する |
| `color.ui = auto` | 端末に出力するときだけ色を付ける（パイプ時は付けない） |

**`help.autocorrect`**
数値を指定すると「その 1/10 秒後に自動実行」になるが、`prompt` にすると
`Run 'status' instead [y/N]?` と聞いてくれる。勝手に実行されないので安全。

**`status.showUntrackedFiles = all`**
既定（`normal`）では未追跡のディレクトリを `newdir/` とだけ表示する。
`all` にすると中のファイルまで出るので、追加し忘れに気付きやすい。

### `[alias]`

| エイリアス | 中身 | 用途 |
|---|---|---|
| `st` | `status --short --branch` | 短い形式の status |
| `co` | `checkout` | |
| `sw` | `switch` | ブランチ切り替え専用の新しいコマンド |
| `br` | `branch` | |
| `ci` | `commit` | |
| `ca` | `commit --amend` | 直前のコミットを編集する |
| `amend` | `commit --amend --no-edit` | メッセージはそのまま、内容だけ直前のコミットに足す |
| `unstage` | `restore --staged` | ステージから降ろす |
| `last` | `log -1 HEAD --stat` | 直前のコミットの内容を確認する |
| `lg` | グラフ付き1行ログ | 履歴の全体像を見る |
| `undo` | `reset --soft HEAD~1` | 直前のコミットを取り消す（**変更内容はステージに残る**） |
| `pushf` | `push --force-with-lease` | 安全な強制 push |
| `current` | `rev-parse --abbrev-ref HEAD` | 現在のブランチ名だけを出す（スクリプト用） |
| `merged` | `branch --merged` | マージ済みで消して良いブランチを探す |
| `aliases` | `config --get-regexp ^alias\.` | **このエイリアス一覧を出す** |

**`pushf` が `--force` ではなく `--force-with-lease` な理由**
`--force` は問答無用でリモートを上書きするため、他人が push した内容を消してしまう。
`--force-with-lease` は「自分が最後に取得した時点からリモートが変わっていないこと」を
確認してから上書きするので、他人の作業を消す事故を防げる。

**`undo` は安全**
`reset --soft` は HEAD を1つ戻すだけで、作業ツリーもステージも変更しない。
コミットを作り直したいときに使う。`--hard` と違い変更内容は消えない。

### `[include]`

```ini
[include]
	path = ~/.gitconfig.local
```

別のファイルの設定をこの位置に差し込む git の標準機能。
**ファイルが存在しなくてもエラーにならない。**

ファイル末尾に置いているため、`~/.gitconfig.local` の内容が
このファイルの設定を上書きする。仕事用のメールアドレスを使い分けるときはここを使う。

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
	email = work@example.com
EOF
```

---

## git/gitignore_global

`core.excludesfile` から読まれる、**すべてのリポジトリに効く** gitignore。

### 方針

ここに書くのは「どのプロジェクトでも絶対に追跡しないもの」だけ。

- macOS が撒くファイル（`.DS_Store` など）
- エディタの作業ファイル（`.idea/`、`*.swp` など）
- 秘密情報（`.env`、`*.pem` など）— 誤コミットの最後の砦
- 各種ツールがローカルに吐く作業ファイル（`tags`、`*.tfstate` など）

**`node_modules/` や `vendor/bundle/` のようなプロジェクト固有の除外は書かない。**
グローバルに隠すと、そのリポジトリをクローンした人の手元では無視されず、
「自分の環境では commit されないのに他人の環境では commit される」という
再現しない事故になる。プロジェクトの `.gitignore` に書くのが正しい。

### 主な項目

| パターン | 説明 |
|---|---|
| `.DS_Store` | Finder がフォルダを開くたびに作る表示設定ファイル |
| `._*` | AppleDouble。非 HFS ボリューム上でメタデータを保存するために作られる |
| `.Spotlight-V100` / `.Trashes` / `.fseventsd` | ボリューム直下に作られる macOS の管理用ディレクトリ |
| `Icon?` | カスタムフォルダアイコン。実際のファイル名は末尾に改行を含むため `?` で受ける |
| `.vscode/*` + `!.vscode/settings.json` など | **VS Code はチーム共有したい設定だけ通す**。`!` は除外の打ち消し |
| `.idea/` / `*.iml` | JetBrains 系 IDE のプロジェクト設定 |
| `*~` / `*.swp` / `.\#*` | Vim / Emacs の作業ファイル |
| `.env` / `.env.*` | 環境変数ファイル。`!.env.example` で雛形だけ通す |
| `*.pem` / `*.key` | 秘密鍵 |
| `.direnv/` | direnv がキャッシュを置くディレクトリ |
| `tags` / `TAGS` | ctags が生成するインデックス |
| `.terraform/` / `*.tfstate*` | Terraform のローカル作業ディレクトリと state |
| `.byebug_history` | Ruby のデバッガが残す入力履歴 |
| `*.log` / `*.bak` / `*.orig` / `*.rej` | 各種の作業残骸。`*.orig` と `*.rej` はマージ・パッチ失敗時に残るもの |

> 意図的に追跡したいファイルがこれらに当たってしまったときは
> `git add -f <ファイル>` で個別に強制追加できる。

---

## vscode/settings.json

`~/Library/Application Support/Code/User/settings.json` にリンクされる、
ユーザー全体の設定。JSONC 形式なのでコメントと末尾カンマが書ける。

### 移行前からある設定

| 設定 | 効果 |
|---|---|
| `window.newWindowDimensions: "inherit"` | 新規ウィンドウを直前のウィンドウと同じサイズで開く |
| `editor.tabSize: 2` | タブ幅を2に |
| `editor.renderWhitespace: "boundary"` | 空白を可視化。ただし単語間の単一スペースは表示しない |
| `workbench.colorCustomizations` | アクティブタブの背景を紫、文字を明るいグレーに |
| `workbench.iconTheme: "material-icon-theme"` | ファイルアイコンのテーマ |
| `editor.defaultFormatter: "esbenp.prettier-vscode"` | 既定のフォーマッタを Prettier に |
| `editor.formatOnSave: true` | 保存時に自動整形する |
| `[markdown] editor.formatOnSave: false` | Markdown だけは自動整形しない |
| `[html] editor.defaultFormatter` | HTML は VS Code 内蔵のフォーマッタを使う |
| `workbench.editor.pinnedTabsOnSeparateRow: true` | ピン留めしたタブを別の行に分けて表示する |
| `claudeCode.preferredLocation: "panel"` | Claude Code を下部パネルに開く |
| `editor.acceptSuggestionOnEnter: "off"` | **Enter で補完候補を確定しない**（改行と誤爆しない） |
| `explorer.confirmDragAndDrop: false` | ファイルのドラッグ移動時に確認しない |
| `files.insertFinalNewline: true` | ファイル末尾に改行を1つ入れる |
| `workbench.statusBar.visible: false` | 下部のステータスバーを隠す |
| `workbench.secondarySideBar.defaultVisibility: "hidden"` | 右サイドバーを既定で隠す |
| `explorer.fileNesting.patterns` | 関連ファイルをエクスプローラ上で入れ子表示する |

**`explorer.fileNesting.patterns`**
`package.json` の下に `yarn.lock` や `package-lock.json` をぶら下げる、
`*.ts` の下に生成された `*.js` をぶら下げる、といった表示にする。
ファイル一覧の見通しが良くなる。

### 今回追加した設定

#### 保存時の後始末

| 設定 | 効果 |
|---|---|
| `files.trimTrailingWhitespace: true` | 行末の余計な空白を落とす |
| `files.trimFinalNewlines: true` | ファイル末尾の余分な空行を落とす |
| `files.eol: "\n"` | 改行コードを LF に固定する |

行末空白が残っていると、他人がそれを消したときに「意味の無い差分」が
レビューに混ざる。保存のたびに落としておけばそもそも発生しない。

#### エディタの見やすさ

| 設定 | 効果 |
|---|---|
| `editor.guides.bracketPairs: "active"` | カーソルが今いる括弧のペアだけを線で結ぶ |
| `editor.linkedEditing: true` | HTML の開始タグを直すと終了タグも一緒に変わる |
| `editor.renderControlCharacters: true` | 目に見えない制御文字を表示する |
| `workbench.editor.highlightModifiedTabs: true` | 未保存のタブを色で区別する |
| `explorer.compactFolders: false` | 子が1つだけのフォルダをまとめて表示しない |

**`explorer.compactFolders: false`**
既定では `src/main/java` のように中身が1つしかないフォルダが1行にまとめて表示される。
省スペースだが、階層を取り違えてファイルを置いてしまうことがある。分けて表示させる。

**`editor.renderControlCharacters: true`**
Web からコピーしたコードにゼロ幅スペースなどが紛れ込んでいると、
見た目は正常なのに構文エラーになる。表示しておけば原因にすぐ気付ける。

#### 差分表示

```jsonc
"diffEditor.ignoreTrimWhitespace": false
```

**既定では VS Code の差分ビューが空白だけの変更を隠す。**
インデントを変えただけの行が「変更なし」に見えてしまい、
git 上では差分が出ているのに VS Code では見えないという食い違いが起きる。
`false` にして全部表示させる。

#### 検索とファイル監視から外す

```jsonc
"search.exclude": { "**/node_modules": true, ... }
"files.watcherExclude": { "**/node_modules/**": true, ... }
```

- `search.exclude` — 全文検索の対象から外す。検索結果が `node_modules` で埋まらなくなる
- `files.watcherExclude` — ファイル変更の監視対象から外す。**CPU 使用率とメモリが下がる**

`files.watcherExclude` の方が効果が大きい。VS Code は開いているフォルダ配下の
すべてのファイルを監視しており、`node_modules` のような巨大なディレクトリがあると
それだけでリソースを食う。

```jsonc
"search.useGlobalIgnoreFiles": true
```

グローバル gitignore（`git/gitignore_global`）の内容も検索から外す。

#### Git

| 設定 | 効果 |
|---|---|
| `git.autofetch: true` | 定期的に fetch して、リモートとの差をエディタ上に出す |
| `git.confirmSync: false` | sync のたびに確認ダイアログを出さない |
| `git.pruneOnFetch: true` | fetch のときに削除済みリモートブランチも掃除する |

`git.pruneOnFetch` は `.gitconfig` の `fetch.prune` と同じ効果を VS Code 側でも効かせるもの。

#### ターミナル

```jsonc
"terminal.integrated.scrollback": 10000
```

内蔵ターミナルの履歴保持行数。既定の 1000 行だと長いビルドログを遡れない。

### Ruby / Rails 向けの設定

#### フォーマッタの振り分け

```jsonc
"[ruby]": {
  "editor.defaultFormatter": "Shopify.ruby-lsp",
}
```

**これが無いと `.rb` の保存時整形が黙って失敗する。**
`editor.defaultFormatter` が Prettier になっているが、Prettier は Ruby を扱えない。
`formatOnSave` が有効でもエラーにならず何も起きないため、原因に気付きにくい。

```jsonc
"[erb]": {
  "editor.formatOnSave": false,
}
```

ERB も同じ問題を起こす。ただし ERB を整形できる拡張は現在入っていないため、
振り分け先が無い。**保存時整形そのものを止めて、黙って失敗する状態を解消している。**

整形もしたい場合は [`aliariff.vscode-erb-beautify`](https://marketplace.visualstudio.com/items?itemName=aliariff.vscode-erb-beautify)
を入れる（`htmlbeautifier` gem を Gemfile に足す必要がある）。入れたうえで
`"editor.formatOnSave": true` と `"editor.defaultFormatter": "aliariff.vscode-erb-beautify"`
に変える。

> `.html.erb` が `erb` として認識される仕組み: 拡張子は最後の `.erb` で判定されるため、
> `files.associations` を書かなくても `erb` 言語になる。
> `Gemfile` / `Rakefile` / `*.jbuilder` / `*.rake` などが `ruby` になるのも
> ruby-lsp 拡張が言語定義として登録しているため。

#### `editor.wordSeparators` — Ruby の記号を単語に含める

```jsonc
"[ruby]": {
  "editor.wordSeparators": "`~#%^&*()-=+[{]}\\|;:'\",.<>/",
}
```

VS Code の既定値は `` `~!@#$%^&*()-=+[{]}\|;:'",.<>/? `` で、
**`@` `$` `?` `!` が単語の区切り**として扱われる。そのため Ruby では:

| 対象 | 既定の挙動 | この設定を入れた後 |
|---|---|---|
| `@user` をダブルクリック | `user` だけ選択される | `@user` が選択される |
| `valid?` をダブルクリック | `valid` だけ選択される | `valid?` が選択される |
| `save!` をダブルクリック | `save` だけ選択される | `save!` が選択される |
| `$stdout` をダブルクリック | `stdout` だけ選択される | `$stdout` が選択される |

既定値から `@` `$` `?` `!` の4文字を取り除いている。
`#` は残してある（コメントと文字列展開 `#{}` の区切りとして機能させるため）。

ダブルクリックだけでなく、`Ctrl-D`（同じ単語を選択）や `Option-←/→`（単語移動）にも効く。
`[erb]` にも同じ設定を入れている。

#### rubyLsp — Ruby のバージョンマネージャ

```jsonc
"rubyLsp.rubyVersionManager": {
  "identifier": "rbenv",
}
```

ruby-lsp が Ruby をどう見つけるかの指定。
`asdf` / `chruby` / `rbenv` / `rvm` / `mise` / `shadowenv` / `none` / `custom` / `auto` から選ぶ。

既定は `auto` で自動判別を試みるが、外れると
「Ruby が見つからない」で LSP が起動せず、補完も定義ジャンプも効かなくなる。
このマシンは rbenv なので明示している。

> **値の形式に注意**: 古い記事では `"rubyLsp.rubyVersionManager": "rbenv"` という
> 文字列形式で書かれていることがあるが、現在は `{ "identifier": "rbenv" }` という
> オブジェクト形式が正しい。

#### rubyLsp.formatter は既定のままにしてある

`rubyLsp.formatter` は設定していない（既定値 `auto`）。

`auto` はプロジェクトの Gemfile を見て `rubocop` / `standard` / `syntax_tree` を
自動で選ぶ。ここで `"rubocop"` と固定すると、**rubocop を使っていないリポジトリを開いた
ときにエラーになる**（`RuboCop was not found in the Gemfile or gemspec`）。
ユーザー全体の設定に書くものなので、プロジェクトごとに変わるものは固定しない。

プロジェクト単位で固定したい場合は、そのリポジトリの `.vscode/settings.json` に書く。

#### 知っておくと良い rubyLsp の設定（今回は未設定）

| 設定 | 使いどころ |
|---|---|
| `rubyLsp.pullDiagnosticsOn: "save"` | 大きなファイルで rubocop の診断が重いとき。既定の `both`（変更時＋保存時）から保存時だけに減らす |
| `rubyLsp.indexing.excludedPatterns` | `**/test/**/*.rb` などを索引から外して起動を速くする |
| `rubyLsp.bundleGemfile` | Gemfile がリポジトリ直下に無い構成のとき |
| `rubyLsp.featuresConfiguration.codeLens.enableTestCodeLens` | テストの上に出る「Run」リンク。既定で有効 |

#### `editor.semanticHighlighting.enabled`

```jsonc
"editor.semanticHighlighting.enabled": true
```

ruby-lsp は構文だけでなく**意味を解析した色分け**（ローカル変数とメソッド呼び出しを
別の色にする、など）を提供する。既定値は `configuredByTheme` で、
テーマ側が対応していないと無効になる。明示的に有効化している。

#### `emmet.includeLanguages` — ERB で Emmet を使う

```jsonc
"emmet.includeLanguages": {
  "erb": "html",
}
```

`.html.erb` の中で Emmet の略記が使えるようになる。
`div.card>ul>li*3` と打って `Tab` を押すと HTML に展開される。
既定では `erb` は Emmet の対象外。

#### `workbench.editor.customLabels.patterns` — タブでファイルを見分ける

```jsonc
"workbench.editor.customLabels.patterns": {
  "**/app/views/**/*": "${dirname}/${filename}.${extname}",
  "**/spec/**/*_spec.rb": "${dirname}/${filename}.${extname}",
  "**/test/**/*_test.rb": "${dirname}/${filename}.${extname}",
}
```

**Rails で一番効く設定かもしれない。**

Rails は規約でファイル名が決まるため、`index.html.erb` や `show.html.erb` が
プロジェクト中に大量にある。タブを何枚か開くと、どれがどのリソースの
ビューなのか区別がつかなくなる。

この設定を入れると、タブの表示が `index.html.erb` から
**`users/index.html.erb`** に変わる。

使える変数:

| 変数 | 意味 |
|---|---|
| `${filename}` | 拡張子を除いたファイル名。`index.html.erb` なら `index.html` |
| `${extname}` | 拡張子。`erb` |
| `${extname(N)}` | N 番目の拡張子 |
| `${dirname}` | 親ディレクトリ名。`users` |
| `${dirname(N)}` | N 個上のディレクトリ名 |

対象は `app/views/` と `spec/` `test/` に絞ってある。
すべてのファイルに適用するとタブが長くなりすぎるため。

#### `explorer.fileNesting.patterns` — Rails 向けの追加

| 親 | 子 |
|---|---|
| `Gemfile` | `Gemfile.lock`, `.ruby-version`, `.ruby-gemset`, `.tool-versions` |
| `.rubocop.yml` | `.rubocop_todo.yml` |
| `docker-compose.yml` | `docker-compose.*.yml`, `Dockerfile*`, `.dockerignore` |
| `.env` | `.env.*` |
| `README.md` | `LICENSE*`, `CHANGELOG*`, `CONTRIBUTING*`, `CODE_OF_CONDUCT*` |

リポジトリ直下に並ぶ設定ファイル群がまとまり、`app/` や `config/` が見つけやすくなる。

> ファイル入れ子は**同じディレクトリ内**でしか働かない。
> `app/models/user.rb` の下に `spec/models/user_spec.rb` をぶら下げることはできない。

#### 検索とファイル監視の Rails 向け除外

`search.exclude` に追加したもの:

| パターン | 理由 |
|---|---|
| `**/vendor/bundle` `**/.bundle` | bundle install したgemの実体。検索結果を埋め尽くす |
| `**/storage` | Active Storage がアップロードファイルを置く |
| `**/public/assets` `**/public/packs` | プリコンパイル済みのアセット。元ファイルと二重にヒットする |
| `**/app/assets/builds` | jsbundling / cssbundling のビルド結果 |
| `**/db/*.sqlite3*` | SQLite のデータベース本体 |
| `**/Gemfile.lock` | gem 名を検索したときに必ずヒットして邪魔になる |

`files.watcherExclude` に追加したもの:

| パターン | 理由 |
|---|---|
| **`**/log/**`** | **効果が一番大きい。** `development.log` は開発中ずっと書き込まれ続けるため、監視したままだと VS Code が反応し続けて CPU を食う |
| `**/vendor/bundle/**` `**/.bundle/**` | ファイル数が非常に多い |
| `**/storage/**` | アップロードのたびに増える |
| `**/public/assets/**` `**/public/packs/**` `**/app/assets/builds/**` | アセットのビルドのたびに大量に書き換わる |

#### `files.associations`

```jsonc
"files.associations": {
  "Brewfile": "ruby",
  ".simplecov": "ruby",
}
```

ruby-lsp が `Gemfile` / `Rakefile` / `*.rake` / `*.jbuilder` / `*.gemspec` などは
すでに `ruby` として登録しているが、`Brewfile`（Homebrew）と `.simplecov` は
対象外なので補っている。どちらも中身は Ruby の DSL。

#### 検討したが入れなかったもの

| 設定 | 入れなかった理由 |
|---|---|
| `editor.rulers: [120]` | rubocop の `Layout/LineLength` の既定は 120 だが、Rails 8 標準の `rubocop-rails-omakase` はこの cop 自体を無効にしている。プロジェクトによって正解が違う |
| `"rubyLsp.formatter": "rubocop"` | rubocop を使っていないリポジトリでエラーになる（上述） |
| `files.associations` で `*.html.erb` → `erb` | 拡張子の判定で既に `erb` になるため不要 |
| `editor.codeActionsOnSave` で rubocop 自動修正 | ruby-lsp の formatOnSave が既に rubocop の整形を通す。二重にかけると保存が重くなる |

---

## karabiner/karabiner.json

Karabiner-Elements（キーボードのカスタマイズツール）の設定。
`~/.config/karabiner/karabiner.json` にリンクされる。

現在の内容は**特定の外付けキーボードを使うときに内蔵キーボードを止める**設定になっている。

```jsonc
"devices": [
  {
    "identifiers": { "is_keyboard": true },
    "ignore": true                          // ← まずすべてのキーボードを対象外にする
  },
  {
    "disable_built_in_keyboard_if_exists": true,
    "identifiers": {
      "is_keyboard": true,
      "is_pointing_device": true,
      "product_id": 24926,
      "vendor_id": 7504
    },
    "ignore": false                         // ← この1台だけを対象にする
  }
]
```

| 項目 | 意味 |
|---|---|
| 1つ目のエントリ | すべてのキーボードを Karabiner の処理対象から外す（既定を「触らない」にする） |
| 2つ目のエントリ | `vendor_id: 7504` / `product_id: 24926` のデバイスだけを対象に戻す |
| `is_pointing_device: true` | そのデバイスがポインティング機能も持つ（トラックボール等を内蔵している） |
| `disable_built_in_keyboard_if_exists: true` | **そのデバイスが接続されている間、Mac 内蔵キーボードを無効にする** |

`disable_built_in_keyboard_if_exists` は、外付けキーボードを本体の上に重ねて
置くタイプの使い方で、内蔵キーが誤爆するのを防ぐためのもの。

```jsonc
"virtual_hid_keyboard": { "keyboard_type_v2": "ansi" }
```

Karabiner が OS に見せる仮想キーボードの種類を ANSI（US 配列）にする。

> `vendor_id: 7504` は 16 進で `0x1D50`。自作キーボードや小規模メーカーの製品で
> 広く使われている ID のため、機種名からは特定できない。
> 新しいキーボードに買い替えたときはこの ID を書き換える必要がある。
> 現在の ID は Karabiner-Elements の「Devices」タブで確認できる。

---

## Brewfile

`brew bundle` が読むパッケージ一覧。`brew bundle --file=~/dotfiles/Brewfile` で一括インストールできる。

### tap

```ruby
tap "hashicorp/tap"
```

HashiCorp の公式リポジトリを追加する。`terraform` はここから入る
（Homebrew 本体の terraform は BUSL ライセンス変更に伴い削除されたため）。

### formula（コマンドラインツール）

| パッケージ | 説明 |
|---|---|
| `gh` | GitHub の CLI。PR の作成やレビューをターミナルからできる |
| `mysql` | MySQL サーバ / クライアント |
| `node` | Node.js |
| `openjdk@21` | Java 21 の開発キット |
| `rbenv` | Ruby のバージョン管理。`.zshrc` で初期化している |
| `yarn` | JavaScript のパッケージマネージャ |
| `hashicorp/tap/terraform` | インフラをコードで管理するツール |

### cask（GUI アプリ）

| パッケージ | 説明 |
|---|---|
| `claude-code` | ターミナルで動く AI コーディングアシスタント |

### vscode（拡張機能）

18 個。`brew bundle` が `code --install-extension` を呼んで一括で入れる。

| 拡張 | 用途 |
|---|---|
| `anthropic.claude-code` | Claude Code の VS Code 統合 |
| `esbenp.prettier-vscode` | コードフォーマッタ。`editor.defaultFormatter` に指定している |
| `shopify.ruby-lsp` | Ruby の言語サーバ。`[ruby]` のフォーマッタに指定している |
| `pkief.material-icon-theme` | ファイルアイコン。`workbench.iconTheme` に指定している |
| `mhutchie.git-graph` | コミット履歴をグラフで見る |
| `hediet.vscode-drawio` | VS Code 内で draw.io の図を編集する |
| `ms-ceintl.vscode-language-pack-ja` | UI の日本語化 |
| `ecmel.vscode-html-css` | HTML から CSS のクラス名を補完する |
| `formulahendry.auto-rename-tag` | HTML タグの開始/終了をまとめてリネームする |
| `kaiwood.endwise` | Ruby で `def` を書くと `end` を自動補完する |
| `oderwat.indent-rainbow` | インデントの深さを色分けする |
| `ionutvmi.path-autocomplete` | ファイルパスを補完する |
| `qwtel.sqlite-viewer` | SQLite のファイルを VS Code 上で開く |
| `repreng.csv` | CSV を色分け表示する |
| `shd101wyy.markdown-preview-enhanced` | 高機能な Markdown プレビュー |
| `yzhang.markdown-all-in-one` | Markdown の表整形や目次生成 |
| `streetsidesoftware.code-spell-checker` | コード中の英単語のスペルチェック |
| `ms-vscode.live-server` | ローカルの HTML をライブリロード付きで配信する |

### 更新のしかた

```bash
cd ~/dotfiles && brew bundle dump --vscode --force
```

現在の状態で Brewfile を作り直す。`--force` は既存ファイルの上書きを許可する指定。
差分を確認してからコミットする。

### GitHub Copilot について

**意図的に管理対象から外している。**

以前は `github.copilot-chat` を入れたうえで `settings.json` 側で
`github.copilot.enable: {"*": false}` により補完を無効化していたが、以下の理由で
拡張ごと削除する構成に変えた。

- 補完本体の `github.copilot` 拡張は**そもそもインストールされていなかった**ため、
  `github.copilot.enable` と `github.copilot.nextEditSuggestions.enabled` は
  効いていない設定だった
- 実際に動いていたのは Copilot Chat（サイドバー、`Cmd-I` のインラインチャット、
  タイトルバーのボタン）で、これらは上記の設定では止まらない

`brew bundle dump` は今インストールされているものをそのまま書き出すため、
**手元に拡張が残っていると Brewfile に復活する**。差分に出てきたら削除する。

再び有効にしたくなったら:

```bash
code --install-extension github.copilot-chat
```

> VS Code 内蔵の AI 機能（チャット UI、インラインチャット、AI コードアクション）まで
> まとめて止めたい場合は `"chat.disableAIFeatures": true`（VS Code 1.104 以降）を使う。
> ただしこれは VS Code の AI 基盤そのものを無効化するため、
> Claude Code 拡張への影響は未検証。

---

## install.sh

シンボリックリンクを張るスクリプト。

### 設計

```bash
set -euo pipefail
```

| フラグ | 効果 |
|---|---|
| `-e` | コマンドが1つでも失敗したらその場で終了する |
| `-u` | 未定義の変数を参照したらエラーにする |
| `-o pipefail` | パイプの途中で失敗しても検知する |

途中で失敗したまま処理を続けて中途半端な状態になるのを防ぐ。

```bash
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

スクリプト自身の場所を絶対パスで求める。
これにより `~/dotfiles` 以外の場所にクローンしても動く。

```bash
LINKS=(
  "zsh/.zshrc:$HOME/.zshrc"
  ...
)
```

「リポジトリ内の相対パス : リンクを作る場所」の対応表。
区切りに `:` を使っているのは、リンク先のパスに空白は含まれうる
（`Application Support`）が `:` は含まれないため。

### 処理の流れ

各エントリについて:

1. 実体（リポジトリ側）が無ければスキップして次へ
2. リンク先の**親ディレクトリ**を `mkdir -p` で作る（`~/.config/karabiner/` など）
3. リンク先の状態で分岐する
   - **すでに正しいリンク** → 何もしない（`ok`）
   - **別の場所を指すリンク** → 退避せず張り替える（`relink`）。リンクは中身を持たないため
   - **実ファイル / 実ディレクトリ** → `<名前>.<日時>.bak` に退避する（`backup`）
4. `ln -sfn` でリンクを張る

`ln` のオプション:

| フラグ | 効果 |
|---|---|
| `-s` | シンボリックリンクを作る（ハードリンクではない） |
| `-f` | すでにあれば消してから作る |
| `-n` | リンク先がディレクトリへのリンクだった場合、**その中に入らず**リンク自身を置き換える |

`-n` が無いと、`~/.config` のようなディレクトリへのシンボリックリンクがあったときに
その中にリンクを作ってしまう。

### 冪等性

何度実行しても同じ結果になる。2回目以降はすべて `ok` と表示され、
`.bak` ファイルが増えない。

退避ファイル名に日時を入れているのは、すでに `.bak` がある状態で
もう一度退避が発生したときに前回の退避を上書きしてしまわないため。

### 対応表

| リポジトリ内 | リンク先 |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.zprofile` | `~/.zprofile` |
| `zsh/.gemrc` | `~/.gemrc` |
| `git/.gitconfig` | `~/.gitconfig` |
| `git/gitignore_global` | `~/.config/git/ignore` |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` |

---

## .gitignore（リポジトリ自身）

このリポジトリ自体で追跡しないもの。**主目的はトークンの混入防止。**

| パターン | 理由 |
|---|---|
| `*.bak` | `install.sh` が退避した元ファイル。中身に秘密情報が入っている可能性がある |
| `*.local` | マシン固有・秘密情報の逃がし先。**これが commit されたら意味が無い** |
| `.DS_Store` | macOS が撒くファイル |
| `**/hosts.yml` | **`gh` の OAuth トークンが入るファイル**。将来 `gh` の設定を足しても事故らないように先回りしている |
| `**/automatic_backups/` | Karabiner が設定変更のたびに作るバックアップ。ノイズになる |
| `.zcompdump*` | zsh が自動生成する補完キャッシュ |
| `**/.claude/.cc-writes/` `**/.claude/settings.local.json` | Claude Code の作業ファイルとローカル設定 |

### push 前の確認

```bash
git ls-files | xargs grep -lEI 'gho_|ghp_|github_pat_|BEGIN .*PRIVATE KEY|AKIA[0-9A-Z]{16}'
```

何も出力されなければトークン類は含まれていない。
