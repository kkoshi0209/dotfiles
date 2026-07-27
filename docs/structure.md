# ディレクトリ構成

このリポジトリに何がどこにあるか、なぜその分け方なのかをまとめる。

個々の設定項目の意味は [settings.md](settings.md)、
仕組み（リンクの張られ方・読み込み順序）は [how-it-works.md](how-it-works.md) を参照。

---

## 全体像

```
~/dotfiles/
│
├── README.md              入口。新マシンでの復元手順
├── install.sh             シンボリックリンクを張る本体
├── Brewfile               Homebrew で入れるものの一覧
├── .gitignore             このリポジトリで追跡しないもの
│
├── docs/                  解説（リンクは張られない）
│   ├── structure.md         ← このファイル
│   ├── settings.md          設定を1項目ずつ解説
│   └── how-it-works.md      仕組みの解説
│
├── zsh/                   シェル
│   ├── .zshrc               対話シェルの設定
│   ├── .zprofile            ログイン時に1回だけ走る設定
│   └── .gemrc               RubyGems の設定
│
├── git/
│   ├── .gitconfig           git 本体の設定
│   └── gitignore_global     全リポジトリに効く gitignore
│
├── vscode/
│   └── settings.json        VS Code のユーザー設定
│
└── karabiner/
    └── karabiner.json       キーボードのカスタマイズ
```

---

## リポジトリとホームの対応

**実体はリポジトリ側にあり、ホーム側はそこを指すシンボリックリンク。**

```mermaid
graph RL
    subgraph home["~/ （リンク）"]
        H1["~/.zshrc"]
        H2["~/.zprofile"]
        H3["~/.gemrc"]
        H4["~/.gitconfig"]
        H5["~/.config/git/ignore"]
        H6["~/Library/Application Support/<br/>Code/User/settings.json"]
        H7["~/.config/karabiner/karabiner.json"]
    end

    subgraph repo["~/dotfiles/ （実体）"]
        R1["zsh/.zshrc"]
        R2["zsh/.zprofile"]
        R3["zsh/.gemrc"]
        R4["git/.gitconfig"]
        R5["git/gitignore_global"]
        R6["vscode/settings.json"]
        R7["karabiner/karabiner.json"]
    end

    H1 -.-> R1
    H2 -.-> R2
    H3 -.-> R3
    H4 -.-> R4
    H5 -.-> R5
    H6 -.-> R6
    H7 -.-> R7
```

点線がシンボリックリンク。この対応表は [install.sh](../install.sh) の `LINKS` 配列に
そのまま書かれている。**リンクを増やしたいときはあの配列に1行足すだけ。**

> リポジトリ側のファイルを編集すれば即座に反映される。
> コピーではなくリンクなので、`~/.zshrc` を直接編集してもリポジトリ側が変わる。

---

## ファイルの分類

リポジトリ内のファイルは、役割で3つに分かれる。

```mermaid
graph TD
    ROOT["~/dotfiles の中身"]

    ROOT --> A["① リンクされる設定ファイル"]
    ROOT --> B["② 仕組みを動かすファイル"]
    ROOT --> C["③ 読むためのファイル"]

    A --> A1["zsh/ git/ vscode/ karabiner/"]
    B --> B1["install.sh<br/>Brewfile<br/>.gitignore"]
    C --> C1["README.md<br/>docs/"]

    A1 --> A2["ホーム側にリンクが張られ<br/>各ツールが読む"]
    B1 --> B2["復元のときに実行される<br/>リンクは張られない"]
    C1 --> C2["人間が読む<br/>何にも影響しない"]
```

| | リンクされる | 実行される | 削除したら |
|---|---|---|---|
| `zsh/` `git/` `vscode/` `karabiner/` | ○ | — | 設定が失われる |
| `install.sh` | — | ○ | 復元できなくなる |
| `Brewfile` | — | ○ | パッケージ一覧が失われる |
| `docs/` `README.md` | — | — | **動作には影響しない** |

---

## なぜこの分け方なのか

### トピックごとにディレクトリを切る

`zsh/` `git/` `vscode/` `karabiner/` のように、**ツール単位**で分けている。

```mermaid
graph LR
    subgraph bad["✗ 全部ルートに置く"]
        B1[".zshrc<br/>.zprofile<br/>.gemrc<br/>.gitconfig<br/>gitignore_global<br/>settings.json<br/>karabiner.json"]
    end

    subgraph good["○ ツール単位で分ける"]
        G1["zsh/"]
        G2["git/"]
        G3["vscode/"]
        G4["karabiner/"]
    end

    bad -->|"どれが何の設定か<br/>名前から分からない"| good
```

利点:

- **`settings.json` のような一般的すぎる名前が衝突しない**
  （VS Code 以外にも `settings.json` を使うツールがある）
- ツールを使わなくなったらディレクトリごと消せる
- `install.sh` の対応表と1対1に対応するので追いやすい

### ただし細かく分けすぎない

`zsh/config/aliases/git.zsh` のような深い階層にはしていない。

現状 `.zshrc` は115行、`.gitconfig` は118行で、**1ファイルで読み切れる量**に収まっている。
分割は「1ファイルが読み切れなくなってから」で間に合う。

> この方針は [Dries Vints の記事](https://driesvints.com/blog/getting-started-with-dotfiles/)
> が参考元。細かく分けた構成から少数のファイルへ戻した経緯が書かれている。

### `docs/` を分けている理由

README は「新しいマシンで復元する人」が読むもの。
解説を全部そこに書くと、手順が埋もれる。

```mermaid
graph TD
    Q{"何をしたい?"}
    Q -->|"新マシンで復元したい"| R["README.md"]
    Q -->|"どこに何があるか知りたい"| S["docs/structure.md"]
    Q -->|"この設定は何?"| T["docs/settings.md"]
    Q -->|"なぜこう動くのか知りたい"| U["docs/how-it-works.md"]
```

---

## ディレクトリごとの説明

### `zsh/`

シェルの設定。**3ファイルの役割がはっきり分かれている。**

```mermaid
graph TD
    A[".zprofile"] -->|"ログイン時に1回"| A1["PATH の組み立て<br/>（Homebrew の環境変数）"]
    B[".zshrc"] -->|"ターミナルを開くたび"| B1["補完・履歴・キーバインド<br/>エイリアス"]
    C[".gemrc"] -->|"gem コマンドが読む"| C1["ドキュメント生成を止める"]
```

| ファイル | いつ読まれるか | 何を置くか |
|---|---|---|
| `.zprofile` | ログインシェルの起動時に**1回だけ** | 一度決めれば変わらないもの（`PATH`） |
| `.zshrc` | 対話シェルを開く**たびに毎回** | 対話操作に関わるもの（補完・履歴） |
| `.gemrc` | `gem` コマンドの実行時 | RubyGems のオプション |

`.zprofile` と `.zshrc` の使い分けが重要。`PATH` の組み立てを `.zshrc` に書くと、
シェルを入れ子で起動するたびに実行されて `PATH` が伸びていく。

詳しい読み込み順序は [how-it-works.md](how-it-works.md#zsh-の読み込み順序)。

### `git/`

git の設定。**2ファイルは別の場所にリンクされる。**

```mermaid
graph RL
    H1["~/.gitconfig"] -.-> R1["git/.gitconfig"]
    H2["~/.config/git/ignore"] -.-> R2["git/gitignore_global"]

    R1 -->|"core.excludesfile で<br/>参照している"| H2
```

`.gitconfig` の中で `core.excludesfile = ~/.config/git/ignore` と書いているため、
**この2つは連動している**。片方だけ移すと gitignore が効かなくなる。

ファイル名が `gitignore_global` なのは、リポジトリ内に `.gitignore` がすでにあり、
そちらと紛らわしくならないようにするため（リンク先では `ignore` という名前になる）。

### `vscode/`

VS Code のユーザー設定。リンク先のパスに**空白が含まれる**のが特徴。

```
~/Library/Application Support/Code/User/settings.json
                    ↑ ここ
```

このため `install.sh` の中の変数展開は必ず `"` で囲っている。囲い忘れると
`Application` と `Support` が別々の引数として扱われて壊れる。

> `snippets/` も管理対象にできるが、現在は空なので入れていない。

### `karabiner/`

キーボードのカスタマイズ設定。

`~/.config/karabiner/` には `automatic_backups/` という自動バックアップの
ディレクトリもあるが、**これは追跡していない**（`.gitignore` で除外）。
設定を変更するたびに増えるためノイズになる。

### `docs/`

解説ファイル。**リンクは張られず、実行もされない。**
消しても環境の動作には影響しない。

---

## ルート直下のファイル

### `install.sh`

対応表を持ってシンボリックリンクを張る。
**このリポジトリで唯一の実行ファイル。**

処理の流れは [how-it-works.md](how-it-works.md#installsh-の動き) を参照。

### `Brewfile`

`brew bundle` が読むパッケージ一覧。3種類が1ファイルに入っている。

```mermaid
graph TD
    BF["Brewfile"]
    BF --> T["tap<br/>追加リポジトリ"]
    BF --> F["brew<br/>コマンドラインツール<br/>7個"]
    BF --> C["cask<br/>GUI アプリ<br/>1個"]
    BF --> V["vscode<br/>VS Code 拡張<br/>18個"]
```

`brew bundle dump --vscode --force` で現在の状態から作り直せる。

### `.gitignore`

**主目的はトークンの混入防止。**

```mermaid
graph TD
    G[".gitignore"]
    G --> S1["*.local<br/>秘密情報の逃がし先"]
    G --> S2["**/hosts.yml<br/>gh の OAuth トークン"]
    G --> S3["*.bak<br/>install.sh の退避ファイル"]
    G --> S4["ノイズ<br/>.DS_Store / automatic_backups / .zcompdump"]

    S1 --> R["リポジトリに入らない"]
    S2 --> R
    S3 --> R
    S4 --> R
```

---

## リポジトリに入らないファイル

**秘密情報とマシン固有の設定は、リポジトリの外に置く。**

```mermaid
graph TD
    subgraph tracked["リポジトリ（git 管理下・公開してよい）"]
        A["zsh/.zshrc"]
        B["git/.gitconfig"]
    end

    subgraph untracked["各マシンに手で置く（git 管理外）"]
        C["~/.zshrc.local"]
        D["~/.gitconfig.local"]
    end

    A -->|"末尾で source する"| C
    B -->|"[include] で読む"| D

    C --> C1["業務用の環境変数<br/>その機体だけの PATH"]
    D --> D1["仕事用のメールアドレス"]
```

どちらも**存在しなくてもエラーにならない**ので、必要になったマシンにだけ置けばよい。

この構成があるおかげで「秘密情報が混ざるからコミットできない」という状態を避けられる。

---

## 生成されるファイル

実行の結果として生まれ、リポジトリには入らないもの。

| ファイル | 誰が作るか | 場所 |
|---|---|---|
| `<名前>.<日時>.bak` | `install.sh` が既存の実ファイルを退避したもの | ホーム側 |
| `~/.zcompdump` | zsh の補完キャッシュ | ホーム |
| `~/.cache/zsh/zcompcache` | 補完結果のキャッシュ | ホーム |
| `~/.zsh_history` | コマンド履歴 | ホーム |

いずれも消しても再生成される。

---

## 関連ドキュメント

| ファイル | 内容 |
|---|---|
| [README.md](../README.md) | 新マシンでの復元手順 |
| [settings.md](settings.md) | 設定を1項目ずつ解説 |
| [how-it-works.md](how-it-works.md) | リンクの張られ方・読み込み順序・秘密情報の守り方 |
