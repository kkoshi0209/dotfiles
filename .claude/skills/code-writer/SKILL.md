---
name: code-writer
description: ソースコードの実装から、ブランチ作成、TDD、CLAUDE.md準拠/バグ/スコープレビュー、UI確認、security-auditによる最終セキュリティチェックまでを一貫して行う手順。ブランチ作成 → TDD実装 → code-review-local → UI確認(該当時) → security-audit の順に進め、各段階で指摘が無くなるまで修正を繰り返してから次の段階に進む。ソースコードを実装・修正する直前に読む。
---

# コード実装のパイプライン

実装した結果をそのまま出さない。ブランチ作成 → TDDでの実装 → code-review-localでのレビュー → (UIなら)ブラウザでの確認 → security-auditでの最終チェック、の段階を順番に通してから出力する。

コードのレビューは`code-review-local`が一本化して担う(依頼内容との整合性・事実確認・CLAUDE.md準拠・バグ/ロジック/セキュリティのすべてをそこで見る)。文章向けの`self-review`はここでは使わない。

**実装方針(レイヤー構成、既存コードとの統合方法などのアーキテクチャ判断)はここでは決めない。** `designer` skillでの設計フェーズで既に決まっているので、承認済みの設計doc(または依頼内容)に従って実装するだけにする。設計docが無い依頼(小さな修正など)では、既存コードの書き方に合わせる。

## 1. ブランチを作る

対象リポジトリが `backlog` / `dotfiles` なら不要(main上で直接作業する)。それ以外のリポジトリでは、このパイプラインで最初にファイルを編集する前に行う。

1. `git pull` で対象リポジトリを最新化する
2. `git checkout -b feature/<タスクを表す短い名前>` で新しいブランチを作る

develop/main 上のままで以降のステップ(実装)に進まない。

## 2. TDDで実装する

`test-driven-development` skill の RED → GREEN → REFACTOR サイクルに従う。テストを先に書いて失敗を確認してから、テストを通す最小限のコードを書く。

## 3. code-review-localでレビューする

`code-review-local` skill の手順(事実確認→CLAUDE.md準拠×2・バグ・ロジック/セキュリティ・スコープの5並列レビュー→指摘ごとの独立検証→確認できた指摘を直す)に従う。指摘が無くなるまで繰り返す(上限3周)。

## 4. UI/フロントエンドの変更があればブラウザで確認する

UIや画面表示に関わる変更があれば `playwright-skill` を使い、実際にdev serverを検出してブラウザで動作とスクリーンショットを確認する。UIに関係しない変更ならこの段階はスキップする。

## 5. security-auditで最終チェックする

`security-audit-local` skill の条件(scoped run・standardプロファイル・この環境向けのサンドボックス簡略化)で `security-audit` skill を実行する。`confirmed` な指摘があれば直し、再実行する。新規の `confirmed` が無くなるか、3回実行しても収束しなければ、残った指摘を明示して次に進む。

## 6. 実装内容を記録する

`doc-writer` に実装内容の記録を委任する。依頼元から設計docの参照が渡されていれば、そのdocのImplementation Notesに追記させる。渡されていなければ、新規にproject docを作る必要があるかを`doc-writer`に判断させる(`aftee-docs` skillの基準に従う)。

## 7. 報告する

作成したブランチ名(作った場合)、実装内容、code-review-localで直した点、UI確認の結果(該当する場合)、security-auditの結果(confirmed / needs_validation の件数と概要)、記録したdocの参照を報告する。
