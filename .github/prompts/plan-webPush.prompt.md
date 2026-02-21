## Plan: web-pushでRails WebPush実装（DRAFT）

`web-push` gemを導入し、匿名デバイス購読を保存して、Service Worker経由で通知受信できる最小構成を作ります。方針は、(1) PWAルートを有効化、(2) 新規トップページに購読UIを配置、(3) サーバーは購読CRUD API + 非同期送信ジョブ、(4) VAPID鍵はRails credentials管理、です。これによりローカルで購読登録→手動トリガー送信→通知表示までを一気通貫で検証できます。既存構成（Importmap/Turbo/Stimulus、Solid Queue）に合わせ、拡張しやすい最小実装に留めます。

**Steps**
1. 依存と設定を追加: [Gemfile](Gemfile) に `web-push` を追加し、VAPID参照用設定を [config/initializers](config/initializers) 配下に追加（`Rails.application.credentials.dig(:web_push, ...)` を利用）。
2. PWA公開を有効化: [config/routes.rb](config/routes.rb) で `manifest`/`service-worker` ルートを有効化し、[app/views/layouts/application.html.erb](app/views/layouts/application.html.erb) の manifest link を有効化。
3. 購読保存モデルを作成: [app/models](app/models) に `PushSubscription`（endpoint, p256dh, auth, expiration_time, user_agent等の最小列）を追加し、DBマイグレーションを作成。
4. APIエンドポイントを実装: [app/controllers](app/controllers) に `PushSubscriptionsController` の `create`/`destroy` を追加し、JSONで購読登録・解除を受け付けるルートを [config/routes.rb](config/routes.rb) に追加。
5. 送信処理を非同期化: [app/jobs](app/jobs) に `SendWebPushNotificationJob` を追加し、`WebPush.payload_send` で単一/複数購読へ送信、無効subscription（410/404）を自動クリーンアップ。
6. UI導線を追加: ルートページ用 controller/view を追加し、[app/javascript/application.js](app/javascript/application.js) から購読JSを読み込んで「購読/解除」ボタンを提供、公開VAPID鍵を安全に受け渡し。
7. Service Worker受信処理を実装: [app/views/pwa/service-worker.js](app/views/pwa/service-worker.js) の `push` と `notificationclick` を実装し、payloadに応じて通知表示とクリック遷移を行う。
8. 手動トリガー導線を追加: 開発用の最小送信アクション（例: 管理用エンドポイント or rake task）を追加し、ジョブ enqueue で全購読へテスト通知を送れるようにする。
9. テストを追加: controller/model/jobテストを [test/controllers](test/controllers), [test/models](test/models), [test/jobs](test/jobs) に追加し、購読登録/解除、送信ジョブ、無効購読削除を検証。

**Verification**
- `bin/rails db:migrate`
- `bin/dev` で起動し、トップページで通知許可→購読登録を確認
- 開発用トリガーから通知送信し、ブラウザ通知表示・クリック遷移を確認
- `bin/rails test test/controllers test/models test/jobs` を実行
- HTTPS要件確認（本番はHTTPS前提、ローカルは`localhost`例外）

**Decisions**
- UI配置: 新規トップページを作成して配置
- 購読モデル: 匿名デバイス購読で管理
- 送信方式: ジョブ経由 + 手動トリガー最小導線
- PWA連携: 今回有効化する

このDRAFTで確定なら、次担当がそのまま実装に入れる粒度になっています。
