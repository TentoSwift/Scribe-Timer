# Scribe Timer

手書きで数字を入力するだけで、すばやくタイマーをセットできる Apple Watch アプリです。

[App Store からダウンロード](https://apps.apple.com/jp/app/scribe-timer/id6759303566)

## デモ

https://github.com/user-attachments/assets/ab478561-a83c-4bd8-b9fa-9e847a91c306

## 特徴

- **手書き入力**：画面に数字を一桁ずつ書くだけでタイマー時間を設定（CoreML / MNIST による数字認識）
- **柔軟な単位**：時間・分・秒を組み合わせて指定可能
- **ウィジェット対応**：文字盤からタイマーの残り時間を確認
- **テーマカラー**：好みの色にカスタマイズ
- **タイマーデザイン変更**：複数のデザインから選択可能
- **バイブレーション設定**：通知の振動パターンをカスタマイズ
- **入力認識ディレイ調整**：書き終わりから認識までの間隔を調整
- **多言語対応**：40 以上の言語にローカライズ済み

## 動作環境

- watchOS（Apple Watch）

## プロジェクト構成

```
Scribe Timer/
├── Scribe Timer Watch App/      # メインアプリ（watchOS）
│   ├── ContentView.swift        # 手書き入力 UI
│   ├── Timer/                   # タイマー機能
│   ├── In-App Purchase/         # アプリ内課金
│   ├── MNISTClassifier.mlmodel  # 数字認識モデル
│   └── *.lproj/                 # ローカライズ
├── scribe.widget/               # ウィジェット拡張
└── Scribe Timer.xcodeproj
```

## ライセンス

© 2026 Tento Ishino
