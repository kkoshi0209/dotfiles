---
name: herdr-delegate
description: "herdr のペイン/タブ/ワークスペース/worktree にワーカーエージェントを立てて作業を委任するときの手順書。委任先の起動フラグ、プロンプトの渡し方、完了判定、成果物の回収、後片付けの正しい順序を含む。herdr で別エージェントに作業を投げる直前、または司令塔として複数エージェントを管理するときに読む。herdr CLI そのものの文法は vendor 管理の herdr skill を参照。"
---

# herdr でワーカーに委任する

前提: `test "${HERDR_ENV:-}" = 1` が通ること。CLI の文法そのもの(コマンド一覧、ID の意味、状態の定義)は `herdr` skill(`herdr --skill` が生成する vendor 管理ファイル。編集しない)を参照。ここには**この環境で実測して確定した運用ルールと落とし穴**だけを書く。

## 器の選び方

| シナリオ | 選択 |
|---|---|
| サブタスク1個 | 現在のタブに `pane split --current --no-focus` |
| 独立した2〜3並列(結果だけ欲しい) | 専用タブを1枚作り、その中にペインを並べる。司令塔のタブを潰さない |
| 並列で各画面を目視で追いたい | 1タブ1ペインで N タブ。3ペイン/タブにすると viewport が 19〜20行に潰れる(実測) |
| 別リポジトリ | `workspace create --cwd <repo>`(サイドバーに repo 名・ブランチ・git status が出る) |
| 同一リポジトリで**ファイルが衝突する**並行実装 | `worktree create --workspace <既存ID> --branch <name>` |
| 衝突しない並行実装 | worktree にしない(ディスクと後片付けのコストが無駄) |
| 素のコマンド実行(テスト・ビルド) | ペインを作って `pane run`。エージェントは起動しない |

同一 cwd の並列セッションはプロンプトキャッシュを共有する。worktree を分けると共有しない(公式ドキュメント記載)。読み取り中心の調査で worktree を分ける理由はない。

## 委任の手順

### 1. ペインを作る

```bash
herdr pane layout --pane "$HERDR_PANE_ID"   # 横に広ければ right、縦に高ければ down
PANE=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')
```

- ID は必ず JSON から取る。サイドバーの並び順や過去の例から推測しない
- `--no-focus` を明示する(ユーザーのフォーカスを奪わない)
- 同一方向の分割を繰り返さない。3枚目で読めなくなる。4枚目が必要なら `tab create` に切り替える

### 2. エージェントを起動する(フラグが本体)

```bash
SID=$(uuidgen | tr 'A-Z' 'a-z')   # transcript パスを先に確定させる
herdr agent start research-foo --kind claude --pane "$PANE" --timeout 60000 -- \
  --session-id "$SID" \
  -n "TASK-123 調査" \
  --model sonnet --effort medium \
  --permission-mode plan \
  --append-system-prompt 'これは既に herdr 経由で委任された作業です。あなたはさらに herdr で別エージェントを立てて再委任してはならず、自分の Read/Grep/Bash 等のツールで直接完了させること。'
```

| フラグ | なぜ渡すか |
|---|---|
| `--append-system-prompt` | **再委任の禁止はプロンプト本文ではなくシステムプロンプトに載せる。** 本文に書く運用は書き忘れが単一障害点で、2026-08-20に4段以上のネスト事故を起こした |
| `--session-id` | 起動前に transcript パス(`~/.claude/projects/<cwd をスラグ化>/<uuid>.jsonl`)が確定する。成果物回収の最も堅い経路 |
| `-n <name>` | herdr はターミナルタイトルを読むので、サイドバーで「どの委任先が何をしているか」が判別できる |
| `--model` / `--effort` | 用途別: 軽い調査は `sonnet` + `low`〜`medium`、難しい設計判断だけ `opus` や `--effort xhigh` |
| `--permission-mode` | 読み取り専用の調査は `plan`、書き込みを伴う作業は `acceptEdits`。既定の `manual` は権限確認で `blocked` に落ちて止まる |
| `--allowedTools` / `--disallowedTools` | 調査専用なら Write/Edit を外す |

渡してはいけないもの: `--bare`(hook を skip するので herdr の claude 統合が動かず、セッション復元と transcript 経路が壊れる)、`-w/--worktree`(herdr の worktree と二重管理になる)。

**WebSearch / WebFetch は組織のポリシー設定で `ask` になっており、ユーザー側の allow では上書きできない**(`permissions` の評価順が deny → ask → allow で、先にマッチした ask が勝つ)。Web を引く委任先は承認待ちで `blocked` に落ちる前提で、司令塔が定期的に状態を見て承認するか、`--permission-mode` では解決しないことを織り込んでおく。

### 3. プロンプトを投げる

長いプロンプトは**スクラッチファイルに書いて、短い指示でそのファイルを読ませる**。

```bash
herdr agent prompt research-foo '/tmp/task-123-prompt.md を読んで、そこに書かれたタスクを実行してください。' --wait --timeout 900000
```

- `agent prompt "$(cat file)"` で本文を直接渡すと、**4〜5KB の複数行テキストが着弾せず黙って消えることがある**(2026-08-24、3エージェントすべてで再現。プロンプトボックスが空のまま idle に戻った)。ファイル参照方式ならこの問題を回避でき、トークンも節約できる
- プロンプト本文には objective / 触ってよい範囲と触らない範囲 / 出力形式(成果物のパス) / 一次情報の指定 / 停止条件を書く。他のワーカーとの担当分割を明示しないと同じ調査を重複してやる
- `--wait` は「最初に落ち着いた `idle` / `done` / `blocked`」を待つ。既定と同じ `--until` を重ねて書かない
- タイムアウトの `{"error":{"code":"timeout"}}` は**失敗ではなく「まだ working」**を意味することが多い。`agent get` で状態を確認する

### 4. 完了を判定する(状態だけを信じない)

`agent_status: working` の根拠はターミナルタイトルの点字スピナーだけで、**進捗を意味しない**(`Waiting for API response · will retry in 2m 33s` で停滞中も working だった)。`idle` は「どの検出ルールにもマッチしなかった場合のフォールバック」なので、単独では完了の証拠にならない。判定は**成果物そのもの**で行う。

```bash
herdr agent get research-foo | jq -c '.result.agent | {agent_status, state_change_seq}'
ls -la /tmp/report-foo.md          # ← 委任時に出力先を指定しておく。これが本命
```

`blocked` なら承認待ち。`agent read <name> --source visible` で何を聞かれているか読んでから `agent send-keys <name> <数字>` で答える。**承認内容を確認せずに数字を送るループを回さない**(2026-08-24、使用量上限ダイアログで意図しない選択肢を押した)。

出力を画面から回収する場合:

- **`pane read --lines N` を使わない。** 非 idle のエージェントに対して `--lines 5000` でも viewport の18行しか返さず、警告も出ない。司令塔が「これで全部」と誤認する
- `agent read <name> --source recent-unwrapped --lines 200` を使う。非 idle なら `agent_not_idle` で明示的に失敗するので、待って再試行する
- それでも足りなければ transcript JSONL(`--session-id` で確定済み)を直接パースする。alternate screen の制約を完全に回避できる

### 5. 素のコマンドを別ペインで走らせる

```bash
P=$(herdr pane split --current --direction down --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')
herdr pane run "$P" 'S=DONE; just test; printf "%s_%s\n" "$S" MARKER'
herdr pane wait-output "$P" --match "DONE_MARKER" --timeout 300000
herdr pane read "$P" --source recent-unwrapped --lines 200
herdr pane close "$P"
```

`pane wait-output --match FOO` は **`pane run` が打ち込んだコマンド行そのものにマッチする**。`pane run '... echo FINISHED'` の直後に `--match FINISHED` すると 0.008 秒で成功を返す(実測)。センチネルは上の例のように実行時に組み立てて、コマンド文字列に literal で出さない。`--timeout` の省略は無限待機。

### 6. 後片付け

成果物を回収し終えたその時点で閉じる。自分が作ったものだけを閉じる。

```bash
herdr pane close "$PANE"
herdr tab close "$TAB"        # 自分が create したタブ
```

worktree は**順序が重要**。`workspace close` で閉じると git worktree が孤児になり、`worktree remove --workspace ID` が使えなくなる(復旧は `worktree open` で開き直してから remove)。

```bash
herdr worktree remove --workspace "$WS"           # dirty なら失敗する(安全装置)。ブランチは残る
```

`worktree create --cwd <repo>` は、そのリポジトリが未オープンだと**ソース側のワークスペースも同時に作る**(ワークスペースが2個増える)。`--workspace <既存ID>` を使えば1個だけ。

閉じてはいけないもの: 自分が作っていないペイン/タブ/ワークスペース、司令塔自身のペイン。`herdr server stop` は絶対に実行しない(セッションと全ペインのプロセスが落ちる)。

`agent_not_found` / `pane_not_found` は正常な運用の一部(相手が終了した、別クライアントが片付けた)。エラーを想定してハンドリングする。

### 7. 長時間タスクの完了通知

```bash
herdr notification show "TASK-123 調査完了" --body "レポートを /tmp/report-foo.md に出力" --sound done
```

`{"shown":true}` が返れば出ている。`{"shown":false,"reason":"disabled"}` なら config.toml の `[ui.toast] delivery` が `off` に戻っている。

## 使えるのに使われていない機能

- `pane report-metadata <pane> --source orchestrator --title "TASK-123 売上確定ロジック調査" --token phase=explore --ttl-ms 3600000` — 司令塔が委任先ペインに任意のラベルを書き込め、サイドバーに表示できる(config.toml の `[ui.sidebar.agents.rows_by_agent]` 設定済み)
- `events.wait`(CLI 未露出、`$HERDR_SOCKET_PATH` に改行区切り JSON を書く)— `pane_exited` は状態推測に頼らない確実な終了シグナル。`pane_output_changed` + `min_revision` で「working なのに停滞」を見分けられる
- `layout.export` / `layout.apply`(同じくソケット直叩き)— 委任用の標準レイアウトを保存して再現できる
- `agent explain <target> --verbose` — 状態がおかしいとき、なぜその状態と判定されたかをルール評価つきで出す。トラブルシュートの第一手
- `pane move <id> --new-tab` / `--new-workspace` — ペインで始めた作業が重くなったら独立したタブ/ワークスペースに昇格させられる。移動後は**ペイン ID が変わる**(`.result.move_result.pane.pane_id` を使う)
- `pane zoom --on` — 潰れたペインを一時的に全画面化して読む。ユーザーへの案内に使える
- `herdr --session <name>` — herdr 自体の挙動を試すときに本番セッションを汚さない
