---
name: software-architecture
description: "コードを実装する前に決めておく設計方針。呼び出し側から見て何をするか分かる関数・名前にする、業務ロジックをフレームワーク/DBから分離する、抽象化は早すぎず3箇所目で行い重複と車輪の再発明を避ける、ネストを減らす、型付きのエラーハンドリングをする、独立した非同期処理は並列化する。`test-driven-development`でテストを書く前、実装方針を決める直前に読む。"
---

# 実装方針の原則

ここにある原則は [NeoLabHQ/context-engineering-kit](https://github.com/NeoLabHQ/context-engineering-kit) の `ddd` プラグイン(17ルール)を、重複を削って6グループに再構成したもの。各原則の出典は節末に記載する。例はTypeScriptだが、考え方自体は言語を問わない。

## 1. 呼び出し側から見て何をするか分かるようにする

関数の中身を読まないと「何が起きるか」分からない関数を書かない。名前が約束していないことをしない、副作用・分岐・ミューテーションは呼び出し側に見える形で書く。これは1つの原則の6つの現れ方であり、根は同じ。

- **問い合わせ(値を返す)と命令(副作用を起こす)を混ぜない。** 代入の右辺は純粋な値であるべきで、代入しているのに裏で何かを書き換える関数は呼び出し側を欺く
- **検証(validate)は例外を投げる代わりに真偽値を返す。** 例外を投げるかどうかは呼び出し側が決める判断(policy)であり、検証関数自身(mechanism)が決めることではない
- **入力を書き換えて結果を伝えない。** 結果は必ず返り値にする。書き換えは「何が変わったか」を追うために実装を読む必要が生じる
- **複数の副作用(DB保存・メール送信・イベント発行など)を1つの関数に隠さない。** オーケストレーションする側の関数に1行ずつ並べ、読み手がその関数を開かずに「何が起きるか」を把握できるようにする
- **ログ出力をヘルパー関数の中に隠さない。** `logger.log(...)` は呼び出し側に書き、ヘルパーには整形などの純粋な処理だけを任せる
- 関数名が「取得(get)」なら取得だけをする。分析イベントの送信や最終アクセス日時の更新のような副作用を`getUser`の中に混ぜない

```typescript
// 悪い例: validateResultは検証に見えて実は例外を投げる。呼び出し側は分岐が無いように見える
const result = performProcess(param)
validateResult(result) // -> throws

// 良い例: 判断(投げるかどうか)は呼び出し側に出す
const result = performProcess(param)
if (!isValid(result)) throw new ProcessingError(result)
```

- **名前がその関数・変数の唯一の説明になる。** 呼び出し側はコメントではなく名前だけを見て使うかどうかを判断する。処理の中身を読まないと何をするか分からない名前(`process`, `handle`, `data`)を避け、何をする/何であるかを名前自体に込める。良い名前が見つからないときは、たいてい関数の責務が1つに定まっていない

出典: Command-Query Separation (Fowler, Meyer) / Policy-Mechanism Separation / Explicit Data Flow / Principle of Least Astonishment (Martin, Clean Code)

## 2. 業務ロジックをフレームワーク・DB・IOから分離する

業務ルールそのもの(「割引率はいくつか」「合計金額をどう計算するか」)は、Expressのコントローラやprismaの呼び出しと同じ関数に書かない。業務ロジックをフレームワーク非依存の純粋関数にし、DB・HTTP・ロガーへの呼び出しは外側の層(controller/repository)に押し出す。

理由は2つ。純粋関数はモック無しでテストできる。フレームワークやDBを差し替えても業務ロジックは変更不要になる。

```typescript
// domain層: フレームワークへの依存が無い純粋関数
function calculateOrderTotal(items: OrderItem[]): number {
  const subtotal = items.reduce((sum, i) => sum + i.price * i.qty, 0)
  return subtotal > 100 ? subtotal * 0.9 : subtotal
}

// controller層: 薄いアダプター。業務ロジックそのものは持たない
app.post("/orders", async (req, res) => {
  const total = calculateOrderTotal(req.body.items)
  const order = await orderRepository.save({ ...req.body, total })
  res.json(order)
})
```

出典: Clean Architecture (Robert C. Martin) / Domain-Driven Design (Eric Evans) / Functional Core, Imperative Shell (Gary Bernhardt)

## 3. 重複と車輪の再発明を避ける

- **同じ関数・同じ業務ルール・同じ概念を3箇所目で書こうとしたら抽出する**(Fowlerの「3度目のルール」)。関数の重複は見つけやすいが、**同じ判断を変数名を変えて複数箇所に書く「ロジックの重複」**や、**「アクティブなユーザーとは何か」のような概念を条件式のまま複数箇所にばらまく「概念の重複」**は気づきにくく、仕様変更時に直し漏れが起きる。1箇所の関数・1つの名前付き述語にまとめる
- **抽象化は2箇所目で急がず、3箇所目で行う。** 具体的なコードが2つしか無い段階では、何が本質的な共通点で何がたまたま一致しているだけかを判断できない。早すぎる抽象化(誤った抽象化)は、後から来た3つ目のケースに無理やり当てはめようとして条件分岐だらけの共通関数になり、重複したままの3つのコードより直しにくくなる。「具体を複数集めてから共通点を抽出する」順番を守り、「将来こうなりそうだから」で先に抽象から作らない
- **車輪を再発明する前にnpmの既存ライブラリを探す。** リトライ処理・認証・フォームバリデーションなど、自作するとテスト・保守の負債になりやすい領域は特にそうする。自作が妥当なのは、ドメイン固有のロジック、パフォーマンス上どうしても必要な場合、既存ライブラリでは要件を満たせないと確認した場合に限る

出典: The Pragmatic Programmer (Hunt & Thomas, DRY) / Refactoring (Fowler, Rule of Three) / Sandi Metz, "The Wrong Abstraction"

## 4. ネストを減らし、関数・ファイルを分割する

- **ガード節(早期return)でエラー条件を関数の先頭に並べ、本処理のネストを浅くする。** 3段階以上ネストしたif文は、本処理がどこにあるか分からなくなる
- **関数は80行、ファイルは200行を超えたら分割を検討する。** 1つの関数が検証・変換・保存・通知のように複数の責務を持っていたら、責務ごとに関数を抽出する

出典: Flattening Arrow Code (Jeff Atwood)

## 5. エラーは型で区別し、握りつぶさずログに残す

`catch (e)` で何でも受けて握りつぶさない。想定内の業務エラー(例: 決済拒否)と想定外のシステム障害(例: ネットワーク断)を型で区別し、再送出する前にどちらが起きたかをログに残す。ログが無いと、本番で何が起きたか追えなくなる。

```typescript
catch (error) {
  if (error instanceof PaymentDeclinedError) {
    logger.warn("Payment declined", { orderId, reason: error.reason })
    throw new DomainError(`Payment declined for order ${orderId}`)
  }
  logger.error("Unexpected payment failure", { orderId, error })
  throw error
}
```

## 6. 独立した非同期処理は並列化する

依存関係の無い複数の非同期処理(別々のAPI呼び出し、別々のDBクエリなど)を、意味もなく`await`を連続させて直列実行しない。合計の待ち時間が足し算になる。`Promise.all`で同時に発行すれば、待ち時間は最も遅い1本分で済む。

```typescript
// 悪い例: 合計 = latency(A) + latency(B)
const dataA = await serviceA.getData(key)
const dataB = await serviceB.getData(key)

// 良い例: 合計 ≈ max(latency(A), latency(B))
const [dataA, dataB] = await Promise.all([serviceA.getData(key), serviceB.getData(key)])
```

並列化しない方がよいのは、後続処理が前の結果に依存する場合、順序や因果関係を保つ必要がある場合、レート制限・リソース競合がある場合。

## ドメイン固有の命名(補足)

`utils` `helpers` `common` `shared` のような汎用的なモジュール名は、無関係な関数の寄せ集め場所になりやすい。`OrderCalculator` `UserAuthenticator` のように、そのモジュールが何のドメイン概念を扱うかで名前を付ける。

## 採用しなかった原則

元の17ルールのうち「Boy Scout Rule(触っているコードのついでに改善してよいが、スコープを広げない)」は採用していない。`~/.claude/CLAUDE.md`の既存原則(早すぎる抽象化をしない、タスクに必要な範囲を超えて変更しない)とほぼ同内容のため。
