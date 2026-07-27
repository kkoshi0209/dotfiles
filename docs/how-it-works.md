# 仕組み

「なぜこう動くのか」を図で追う。

- どこに何があるかは [structure.md](structure.md)
- 個々の設定の意味は [settings.md](settings.md)

---

## 全体の流れ

新しいマシンで `./install.sh` を叩いてから、実際に設定が効くまでの流れ。

```mermaid
sequenceDiagram
    participant U as あなた
    participant R as ~/dotfiles
    participant H as ~/ (ホーム)
    participant T as 各ツール<br/>(zsh, git, VS Code...)

    U->>R: git clone
    U->>R: ./install.sh
    R->>H: シンボリックリンクを張る
    Note over H: ~/.zshrc → ~/dotfiles/zsh/.zshrc

    U->>T: ターミナルを開く / git を叩く / VS Code を開く
    T->>H: 設定ファイルを読みに行く
    H-->>R: リンクの先を辿る
    R-->>T: 実体の内容が返る
```

**ツール側は「リンクを辿っている」ことを知らない。**
`~/.zshrc` を普通のファイルとして開いているつもりで、実体は `~/dotfiles` にある。

---

## install.sh の動き

```mermaid
flowchart TD
    START(["./install.sh 実行"]) --> LOOP{"対応表を<br/>1行ずつ処理"}

    LOOP --> EXIST{"リポジトリ側に<br/>実体はある?"}
    EXIST -->|"ない"| SKIP["skip<br/>次の行へ"]
    EXIST -->|"ある"| MKDIR["リンク先の親ディレクトリを<br/>mkdir -p"]

    MKDIR --> CHECK{"リンク先は<br/>今どうなっている?"}

    CHECK -->|"すでに正しいリンク"| OK["ok<br/>何もしない"]
    CHECK -->|"別の場所を指すリンク"| RELINK["relink<br/>張り替える"]
    CHECK -->|"実ファイル / 実ディレクトリ"| BACKUP["日時付きの .bak へ退避"]

    BACKUP --> LINK["ln -sfn でリンクを張る"]
    RELINK --> LINK

    LINK --> LOOP
    OK --> LOOP
    SKIP --> LOOP

    LOOP -->|"全行処理完了"| END(["完了"])
```

**同じコマンドを2回叩いても結果が変わらない**（冪等性）。
2回目はすべて `ok` の分岐に落ちるため、`.bak` が増えたりリンクが壊れたりしない。

### 1回目と2回目で何が違うか

```mermaid
flowchart LR
    subgraph first["1回目の実行"]
        F1["~/.zshrc<br/>（既存の実ファイル）"] -->|"backup"| F2["~/.zshrc.20260727.bak"]
        F3["リンクを新規作成"] --> F4["~/.zshrc → dotfiles/zsh/.zshrc"]
    end

    subgraph second["2回目の実行"]
        S1["~/.zshrc<br/>（すでに正しいリンク）"] -->|"ok（変化なし）"| S1
    end

    first --> second
```

---

## zsh の読み込み順序

ターミナルを開いたとき、どのファイルがどの順で読まれるか。
このリポジトリが管理するのは太字の2つだけで、他は macOS / Homebrew / Nix が用意する。

```mermaid
flowchart TD
    A(["ターミナルを開く"]) --> B["/etc/zshenv"]
    B --> C[".zshenv<br/>（このリポジトリでは未使用）"]
    C --> D{"ログイン<br/>シェルか?"}

    D -->|"Yes"| E["/etc/zprofile"]
    E --> F["<b>~/.zprofile</b><br/>brew shellenv"]
    F --> G

    D -->|"No"| G{"対話<br/>シェルか?"}

    G -->|"Yes"| H["/etc/zshrc"]
    H --> I["<b>~/.zshrc</b><br/>補完・履歴・エイリアス"]

    G -->|"No"| END1(["スクリプト実行のみ"])
    I --> END2(["プロンプトが出る"])
```

**Terminal.app や iTerm2 の新規タブは「ログイン かつ 対話」シェルとして起動する。**
そのため `.zprofile` → `.zshrc` の順に両方読まれる。

### なぜ2ファイルに分けているか

```mermaid
flowchart LR
    subgraph zprofile[".zprofile が担当"]
        P1["PATH の組み立て"]
        P2["1回だけ実行したい"]
    end

    subgraph zshrc[".zshrc が担当"]
        R1["補完・履歴・キーバインド"]
        R2["毎回のシェルで効いてほしい"]
    end

    NEST["シェルを入れ子で起動<br/>(vim内の :sh 、tmuxの新ペインなど)"]

    NEST -.->|".zshrc は毎回読まれる"| zshrc
    NEST -.->|".zprofile はログイン時のみ<br/>=普通は再実行されない"| zprofile
```

`PATH` の組み立てを `.zshrc` に置くと、シェルを入れ子で起動するたびに実行され、
`typeset -U path` で重複除去していても無駄な処理が積み重なる。
`.zprofile` はログイン時の1回で済むため、ここに置くのが正しい。

---

## git の2ファイルの関係

`git/.gitconfig` と `git/gitignore_global` は**別々のファイルだが独立していない**。

```mermaid
flowchart LR
    A["git/.gitconfig"] -->|"core.excludesfile =<br/>~/.config/git/ignore と書いてある"| B["~/.config/git/ignore"]
    B -.->|"実体は"| C["git/gitignore_global"]

    D["git status / git add"] -->|"除外ルールを<br/>ここから読む"| A
    A -->|"参照先を辿る"| B
```

`.gitconfig` の中の1行が、もう片方のファイルへの**参照**になっている。
片方だけ新しいマシンにコピーしても、参照が壊れて gitignore が効かなくなる。

---

## リンクされたファイルを編集したときに何が起きるか

**シンボリックリンクなので、どちらから編集しても同じ実体を書き換える。**

```mermaid
flowchart TD
    subgraph case1["ケース1: リポジトリ側を編集"]
        A1["code ~/dotfiles/zsh/.zshrc<br/>で編集して保存"] --> A2["実体が変わる"]
        A2 --> A3["~/.zshrc<br/>（リンク）を開いても<br/>新しい内容が見える"]
        A2 --> A4["git diff で<br/>差分が見える"]
    end

    subgraph case2["ケース2: ホーム側を編集"]
        B1["vim ~/.zshrc<br/>で編集して保存"] --> B2["実体が変わる<br/>（同じファイルなので）"]
        B2 --> B3["~/dotfiles/zsh/.zshrc<br/>を開いても<br/>新しい内容が見える"]
        B2 --> B4["git diff で<br/>差分が見える"]
    end
```

**「どちらを編集しても実体は1つ」**なので、コミットし忘れることはあっても、
編集内容が反映されないという事故は起きない。

---

## 秘密情報を混入させない仕組み

3段階の防御になっている。

```mermaid
flowchart TD
    subgraph layer1["第1段階: そもそも書かない"]
        L1["gh の認証は<br/>hosts.yml に保存される<br/>→ dotfiles には含めない設計"]
    end

    subgraph layer2["第2段階: 誤って作っても除外する"]
        L2[".gitignore の<br/>**/hosts.yml"]
        L3[".gitignore の<br/>*.local"]
    end

    subgraph layer3["第3段階: コミット前の目視確認"]
        L4["git ls-files を<br/>grep -E でトークン検索"]
    end

    layer1 --> layer2 --> layer3
    layer3 --> OK(["push してよい"])
```

どこか1段が抜けても、次の段で止まるようにしている。
実際に運用でも、この後の段階（`*.local` の仕組み）を先に用意したことで
「秘密情報が混ざるからコミットできない」という状態を避けている。

---

## `*.local` による秘密情報の分離

```mermaid
flowchart TD
    subgraph public["公開リポジトリ（誰でも読める）"]
        A["git/.gitconfig"]
        B["zsh/.zshrc"]
    end

    subgraph private["各マシンだけに置く（gitignore 済み）"]
        C["~/.gitconfig.local"]
        D["~/.zshrc.local"]
    end

    A -->|"末尾: [include] path = ~/.gitconfig.local<br/>（無くてもエラーにならない）"| C
    B -->|"末尾: source ~/.zshrc.local<br/>（無くてもエラーにならない）"| D

    C -.->|"例: 仕事用メールアドレス"| E["この機体だけの設定"]
    D -.->|"例: 社内ツールの PATH"| E
```

`[include]` も `source` も、**参照先のファイルが存在しなくてもエラーにならない**。
そのため個人のマシンでも会社のマシンでも同じ `install.sh` が動き、
必要な差分だけを `*.local` に手で足せばよい。

---

## Brewfile と install.sh の役割分担

「何を入れるか」と「どこにリンクを張るか」は別の関心事なので、別ファイルに分けている。

```mermaid
flowchart LR
    subgraph inputs["入力"]
        BF["Brewfile"]
        LS["install.sh の<br/>LINKS 配列"]
    end

    subgraph actions["実行されること"]
        A1["brew bundle<br/>パッケージのインストール"]
        A2["./install.sh<br/>リンクを張る"]
    end

    subgraph result["結果"]
        R1["コマンドが使えるようになる<br/>(gh, node, rbenv...)"]
        R2["設定が反映される<br/>(.zshrc, .gitconfig...)"]
    end

    BF --> A1 --> R1
    LS --> A2 --> R2

    R1 -.->|"rbenv はインストールされるが<br/>初期化コードは"| R2
```

**Brewfile が入れたツールを、`.zshrc` が初期化する**という依存関係が一部ある
（`rbenv init` など）。そのためインストールの順序は
「Homebrew → clone → install.sh → brew bundle」で、
`install.sh` を先に実行してリンクを張ってから `brew bundle` する必要はない
（どちらが先でも動くが、README の手順はこの順で書いてある）。

---

## 関連ドキュメント

| ファイル | 内容 |
|---|---|
| [README.md](../README.md) | 新マシンでの復元手順 |
| [structure.md](structure.md) | ディレクトリ構成 |
| [settings.md](settings.md) | 設定を1項目ずつ解説 |
