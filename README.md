# KeepAwake

KeepAwake は、選択した時間だけ Mac の**アイドルによるディスプレイ消灯とシステムスリープ**を抑止する、小さなメニューバーアプリです。カーソルを動かしたり、入力を偽装したりしません。

## 動作環境

- macOS 13 Ventura 以降
- ビルドには Xcode Command Line Tools または Xcode（Swift 5.9 以降）
- 管理者権限・アクセシビリティ権限・ネットワーク通信は不要

## 使い方

メニューバーのカップ型アイコンを開き、次のいずれかを選びます。

- `1時間開始`: 1 時間後に自動停止し、残り時間を表示
- `手動で停止するまで開始`: `停止` またはアプリ終了まで継続

オン中はアイコンが塗りつぶしになります。バッテリー駆動時間が短くなる場合があるため、不要になったら停止してください。起動時は常にオフです。自動ログイン起動は設定しません。

## 制限

KeepAwake は macOS の正規の IOKit power management assertion (`PreventUserIdleDisplaySleep`) を使用します。これは要求であり、OS があらゆる状況で必ず維持する保証ではありません。

- 手動ロック、Apple メニュー等からの明示的なスリープ、MacBook の蓋閉じ、低バッテリー、熱保護、OS のセキュリティ／電源判断は回避しません。
- すでに消えているディスプレイを点灯させる機能ではありません。
- アプリがクラッシュまたは強制終了した場合、プロセス終了に伴い assertion は OS により破棄されます。通常の停止・期限切れ・終了ではアプリ自身が明示解除します。
- ネットワーク接続や別アプリの接続維持を保証しません。特に Dot 接続の継続は保証しません。
- システム設定を恒久的に変更しません。

根拠: Apple の [`IOPMAssertionCreateWithDescription`](https://developer.apple.com/documentation/iokit/1557078-iopmassertioncreatewithdescription) および [`kIOPMAssertionTypePreventUserIdleDisplaySleep`](https://developer.apple.com/documentation/iokit/kiopmassertiontypepreventuseridledisplaysleep) の仕様に従っています。

## 再現可能なビルド

```sh
git clone <repository-url>
cd keepawake
swift test
./scripts/build-app.sh
```

生成物は `dist/KeepAwake.app` です。ビルドスクリプトはローカル実行用に ad-hoc 署名します。Developer ID 署名や notarization は行いません。公開配布する場合は、配布者自身の署名・notarization 方針を別途決めてください。

インストールする場合は、ユーザー自身が `KeepAwake.app` を `/Applications` へコピーして起動します。このリポジトリのスクリプトはインストールや常駐起動を行いません。

## テストと実機 QA

```sh
swift test
./scripts/qa-assertion.sh
```

ユニットテストは時間設定、期限切れ、多重開始、失敗時状態、停止・破棄時のリソース解放を確認します。QA スクリプトは短時間だけ実際の assertion を取得し、`pmset -g assertions` で開始と解除を確認して、必ずオフで終了します。

## プロジェクト構成

- `Sources/KeepAwake`: SwiftUI / AppKit メニューバー UI
- `Sources/KeepAwakeCore`: 時間管理と IOKit assertion 所有権
- `Sources/KeepAwakeAssertionQA`: 実 assertion の短時間 QA ヘルパー
- `Tests`: ユニットテスト
- `scripts/build-app.sh`: `.app` 生成

## ライセンス

このプロジェクトは [MIT License](LICENSE) で提供します。改変、再配布、商用利用が可能ですが、著作権表示とライセンス表示を残してください。本ソフトウェアは無保証です。

## サポート方針

不具合報告や改善案は GitHub Issues で受け付けます。ただし個人開発のため、返信、修正、継続的な保守、特定環境での動作を保証しません。

配布用の Developer ID 署名と notarization は行っていません。公開配布する場合は、その提供方法を別途明示します。
