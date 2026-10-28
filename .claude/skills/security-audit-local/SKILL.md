---
name: security-audit-local
description: "`security-audit` skillを、個人開発者が自分の変更差分だけをこの環境でチェックするためのアダプター。scoped run・standardプロファイル・OSサンドボックス要件の簡略化、という3つの条件を指定する。コード変更の最終チェックとして`security-audit`を呼ぶ直前に読む。"
---

# security-auditをこの環境・この用途向けに使う

`security-audit` skill(cloudflare/security-audit-skill)はそのままでは、未信頼の第三者コードをOSレベルで隔離されたサンドボックス内で監査する、コードベース全体向けの本格的な多段階監査ツールとして設計されている。ここでは、**自分が信頼する自分のコードの、1回の変更差分だけ**を監査する用途に合わせて使い方を絞る。

## 指定する条件

`security-audit` skillをfull audit modeで起動するとき、以下を指定する。

- **モード**: full audit mode
- **プロファイル**: standard
- **範囲**: **scoped run**。対象は今回変更したファイル・差分のみ(2つのソース参照間のdiff)。リポジトリ全体は対象にしない

## この環境向けの簡略化

`security-audit` skillの「Universal execution safety」節は、外部ネットワーク遮断・環境変数の許可リスト化・ファイルディスクリプタ検証つきの成果物昇格手順という、OSレベルで隔離されたサンドボックスを要求する。これは未信頼の第三者コードを運用環境で監査する前提の設計であり、ここで監査するのはユーザー自身が信頼する自分のコードなので、この要件は満たさなくてよい。

動的な実行確認(実際にコードを動かして挙動を確かめる部分)が必要な指摘については、無理にサンドボックスを再現しようとせず、`security-audit` skill自身が定める通り `needs_validation`(要検証・重大度なし)として報告するに留める。静的な原因分析で `confirmed` と判定できるものはそのまま報告する。

## 結果の扱い

`confirmed`な指摘があれば直し、同じscoped runの条件で`security-audit`を再実行する。新規の`confirmed`が無くなるか、3回実行しても収束しなければ、残った指摘を明示して次に進む。
