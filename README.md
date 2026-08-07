# dotfiles

macOS の環境設定をまとめたもの。`git clone` して `./install.sh` を叩けば環境が戻る。

> ドキュメントは3本立て:
> **[docs/structure.md](docs/structure.md)**（フォルダ構成・図解）、
> **[docs/settings.md](docs/settings.md)**（設定を1項目ずつ解説）、
> **[docs/how-it-works.md](docs/how-it-works.md)**（仕組みを図で追う）。

## 構成

| ディレクトリ | 中身 | リンク先 |
|---|---|---|
| `zsh/` | `.zshrc` / `.zprofile` / `.gemrc` | `~/` |
| `git/` | `.gitconfig` / `gitignore_global` | `~/.gitconfig` / `~/.config/git/ignore` |
| `vscode/` | `settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `karabiner/` | `karabiner.json` | `~/.config/karabiner/karabiner.json` |
| `Brewfile` | Homebrew の formula / cask / VS Code 拡張 18 個 | — |
| `install.sh` | 上記のシンボリックリンクを張る | — |
| `docs/` | 解説（[structure.md](docs/structure.md) / [settings.md](docs/settings.md) / [how-it-works.md](docs/how-it-works.md)） | — |

## 新しいマシンでの復元手順

1. **Homebrew を入れる**

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **クローンする**

   ```bash
   git clone https://github.com/kkoshi0209/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

3. **シンボリックリンクを張る**

   ```bash
   ./install.sh
   ```

   既存の実ファイルがあれば `<元のファイル名>.<日時>.bak` に退避してからリンクを張る。
   何度実行しても結果は同じ（冪等）。

4. **パッケージを入れる**

   ```bash
   brew bundle --file=~/dotfiles/Brewfile
   ```

   VS Code 拡張も一緒に入る。事前に VS Code 本体が必要（`code` コマンドは `install.sh` が自動でリンクする）。

5. **Ruby を入れる**

   rbenv は Brewfile で入るが、Ruby 本体はバージョンを選んで個別に入れる。

   ```bash
   rbenv install 3.4.9
   rbenv global 3.4.9
   ```

   移行元で使っていたバージョン: `3.1.2` / `3.2.6` / `3.2.9` / `3.2.11` / `3.3.11` / `3.4.9`

6. **GitHub にログインする**

   認証トークンはリポジトリに入れていないので手動で行う。

   ```bash
   gh auth login
   ```

7. **必要ならマシン固有の設定を置く**（次節）

## マシン固有・秘密情報の置き場所

公開したくない設定（業務用のメールアドレス、トークン、その機体だけの PATH など）は
`*.local` ファイルに逃がす。`.gitignore` 済みなのでコミットされない。

- `~/.zshrc.local` — `zsh/.zshrc` の末尾から `source` される
- `~/.gitconfig.local` — `git/.gitconfig` の `[include]` から読まれる

どちらも**存在しなくてもエラーにならない**ので、必要になったときに手で作ればよい。

```bash
# 例: 仕事用のメールアドレスを使う
cat > ~/.gitconfig.local <<'EOF'
[user]
	email = work@example.com
EOF
```

## 各設定の要点

ここは効果の大きいものだけを抜き出したもの。
**全項目の説明は [docs/settings.md](docs/settings.md) にある。**

### zsh

追加のプラグインマネージャやツールに依存せず、zsh 標準機能だけで組んでいる。

| やっていること | 効果 |
|---|---|
| `SHARE_HISTORY` + 履歴10万件 | 複数のターミナル間で履歴が即共有される |
| `HIST_IGNORE_ALL_DUPS` / `HIST_IGNORE_SPACE` | 重複が溜まらない。空白始まりのコマンドは残さない |
| `up-line-or-beginning-search` を ↑↓ に割当 | **打ちかけの文字列で始まる履歴だけ**を遡れる |
| `compinit` + `matcher-list` | 大文字小文字を区別しない補完。単語の途中からでも効く |
| `FPATH` に Homebrew の `site-functions` | `gh` や `terraform` のサブコマンドが補完される |
| `zcompdump` の24時間キャッシュ | シェル起動が速くなる |
| `AUTO_PUSHD` | `cd -<Tab>` で今までいたディレクトリに戻れる |
| `typeset -U path` | シェルを入れ子で起動しても `PATH` が伸びない |

### git

[Git のコア開発者が使っている設定](https://blog.gitbutler.com/how-git-core-devs-configure-git)をベースにしている。特に効くもの:

| 設定 | 効果 |
|---|---|
| `push.autoSetupRemote` | 新規ブランチの初回 push で `-u` を書かなくて済む |
| `core.quotepath = false` | 日本語ファイル名が `\346\227...` にならず読める |
| `core.precomposeunicode` | macOS が濁点を分解する問題（`が` → `か` + `゛`）を吸収する |
| `diff.algorithm = histogram` | 関数を移動したときの差分が読みやすくなる |
| `merge.conflictstyle = zdiff3` | 衝突時に「共通の祖先」も表示されるので判断しやすい |
| `rerere.enabled` | 一度解決した衝突の解き方を覚えて再利用する |
| `fetch.prune` / `pruneTags` | 消えたリモートブランチがローカルに残らない |
| `rebase.updateRefs` | 積み上げたブランチの参照をまとめて付け替える |
| `help.autocorrect = prompt` | 打ち間違いを勝手に実行せず、確認してくれる |
| `commit.verbose` | コミットメッセージ編集画面に差分が出る |

`pull.rebase` は **`false`（merge コミットを作る従来の挙動）** にしてある。
挙動を明示することで「マシンによって pull の結果が違う」事故を防ぐのが目的。
rebase 派に転向するときはここを `true` にする。

エイリアスは `git aliases` で一覧できる。

### gitignore_global

「**どのプロジェクトでも絶対に追跡しないもの**」だけを入れている:
macOS が撒くファイル、エディタの作業ファイル、`.env` や `*.pem` などの秘密情報、
ローカル専用の作業ファイル。

`node_modules/` のような**プロジェクト固有の除外はここに書かない**。
グローバルに隠すと新しくリポジトリを作った人が気付けないため、各リポジトリの
`.gitignore` に書くのが正しい。

### VS Code

既存の設定はそのまま残し、以下を追記している:

- 保存時に行末空白を除去、改行コードを LF に固定
- `diffEditor.ignoreTrimWhitespace: false` — 空白だけの変更も差分に出す
- `search.exclude` / `files.watcherExclude` — `node_modules` などを検索・監視から外して軽くする

Rails 向けには以下を入れている:

- `[ruby]` の formatter を `Shopify.ruby-lsp` に指定
  （既定の formatter が prettier のままだと `.rb` の保存時整形が黙って失敗する）
- `[erb]` の `formatOnSave` を無効化（同じ理由。ERB を整形できる拡張が無いため）
- `rubyLsp.rubyVersionManager` に `rbenv` を明示（外すと LSP が起動しないことがある）
- `editor.wordSeparators` を Ruby 向けに調整 — **`@user` や `valid?` をダブルクリックで丸ごと選択できる**
- `workbench.editor.customLabels.patterns` — **タブが `index.html.erb` ではなく `users/index.html.erb` と表示される**
- `emmet.includeLanguages` で ERB でも Emmet を使えるようにする
- `files.watcherExclude` に `**/log/**` — `development.log` の監視をやめて CPU を下げる

## 管理していないもの

- **GitHub Copilot** — 意図的に外している。`brew bundle dump` で復活させないこと（下記）
- **gh の認証情報** (`~/.config/gh/hosts.yml`) — OAuth トークンが入るため。`.gitignore` で二重に防いでいる
- **Hammerspoon** — 設定が固まっていないため対象外
- **macOS のシステム設定** (`defaults write`) — 後から `macos/defaults.sh` として足せる

## メンテナンス

Homebrew の構成を更新したとき:

```bash
cd ~/dotfiles && brew bundle dump --vscode --force
```

差分を確認してからコミットする。

> **注意**: `brew bundle dump` は今インストールされているものをそのまま書き出す。
> 意図的に外した `github.copilot-chat` が手元に残っていると復活するので、
> 差分に出てきたら削除する。

## 参考

- [How Core Git Developers Configure Git](https://blog.gitbutler.com/how-git-core-devs-configure-git)
- [Popular git config options — Julia Evans](https://jvns.ca/blog/2024/02/16/popular-git-config-options/)
- [8 Useful Ways to Configure Your Zsh History](https://nickjanetakis.com/blog/8-useful-ways-to-configure-your-zsh-history)
- [github/gitignore — Global](https://github.com/github/gitignore/tree/main/Global)
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
