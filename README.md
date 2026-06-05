# CameraK - Manual Camera Control App

高度なマニュアルカメラ操作機能を備えたiPhoneカメラアプリです。標準カメラアプリでは制限されている各種機能を、最大限まで引き出せます。

## Features

### Core Functionality
- **ISO感度手動制御** - デバイスが対応する最大値まで制御可能
- **シャッタースピード手動制御** - 最大30秒の長時間露光に対応
- **マニュアルフォーカス** - タップしたポイントへのピンポイント合焦
- **ホワイトバランス手動調整** - 色温度を2000K～10000Kの範囲で制御
- **露出補正** - ±2EV の範囲で細かく調整
- **レンズ切り替え** - 複数のカメラレンズ間での切り替え

### Capture Formats
- **RAW (DNG)** - 完全なセンサーデータ
- **HEIF** - 現代的な圧縮フォーマット
- **JPEG** - 汎用フォーマット

### Apple AI Processing Control
- **Apple処理削除モード** - Lightroom での「Adobe標準プロファイル」と同じ状態
- **Night Mode ON/OFF** - 暗い環境での撮影時に選択可能
- **DeepFusion無効化** - より自然なディテール保持

### Additional Features
- **ヒストグラム表示** - リアルタイムの露出確認
- **タイマー機能** - セルフタイマー撮影（0～30秒）
- **デバイス自動判定** - 各iPhoneの最大性能を自動で引き出す

## Hardware Requirements

- iPhone 13 以降（iOS 16+推奨）
- カメラ機能

※ 古いiPhoneでも動作しますが、マニュアル操作の範囲はデバイス仕様に依存します

## Project Structure

```
CameraK/
├── App/
│   ├── CameraKApp.swift         # アプリエントリーポイント
│   └── AppDelegate.swift        # アプリデリゲート
├── Models/
│   ├── CameraViewModel.swift    # カメラ制御ロジック（MVVM）
│   └── CameraSettings.swift     # 設定データモデル
├── Views/
│   ├── ContentView.swift        # メインUI
│   ├── CameraPreviewView.swift  # カメラプレビュー
│   ├── HistogramView.swift      # ヒストグラム表示
│   └── SettingsView.swift       # 設定画面
└── Info.plist                   # アプリ設定
```

## Key Implementation Details

### AVFoundation Integration
- `AVCaptureSession` で カメラセッション管理
- `AVCapturePhotoOutput` で 写真撮影
- `AVCaptureDevice` で マニュアル制御

### Manual Controls
各種パラメータのマニュアル制御は以下のメソッドで実装：
- `setISO(_ value:)` - ISO感度設定
- `setShutterSpeed(_ duration:)` - シャッタースピード設定
- `setFocusDistance(_ distance:)` - フォーカス設定
- `setWhiteBalance(_ temperature:)` - ホワイトバランス設定
- `setExposureCompensation(_ compensation:)` - 露出補正設定

### Apple Processing Removal
`AVCapturePhotoSettings` で以下を無効化：
```swift
photoSettings.isAutoStillImageStabilizationEnabled = false
photoSettings.isPhotosDeepFusionEnabled = false
photoSettings.isAutoRedEyeReductionEnabled = false
photoSettings.isAutoVirtualDeviceHDREnabled = false
```

## Development Setup

### Requirements
- Xcode 14.0 以上
- iOS 16.0 以上
- Swift 5.7 以上

### Installation

1. Xcode でプロジェクトを開く：
   ```bash
   open CameraK.xcodeproj
   ```

2. Signing & Capabilities を設定
   - Team ID を自分のApple Developer アカウントに設定
   - Bundle ID: `com.kodaiiwata.camerak`

3. Info.plist でカメラ使用許可を確認
   - NSCameraUsageDescription
   - NSPhotoLibraryAddUsageDescription

4. 実機でテスト（シミュレータではカメラ機能が動作しません）

## Usage

### Basic Workflow
1. アプリを起動
2. カメラプレビューが表示される
3. 左右のスライダーで ISO / SS / フォーカス / WB / 露出補正を調整
4. 撮影形式を選択（RAW / HEIF / JPEG）
5. 白い円形ボタンで撮影

### Advanced Features
- **ヒストグラム表示**: 左上の📊アイコンで表示/非表示
- **Apple処理削除**: "No AI" ボタンで ON/OFF
- **Night Mode**: "Night" ボタンで ON/OFF
- **タイマー**: "Timer" ボタンで ON/OFF、秒数設定画面で調整

## Known Limitations

1. **デバイス仕様依存** - 古いiPhoneではマニュアル操作の範囲が制限される
2. **ISP完全バイパス不可** - ハードウェアレベルの処理は回避不可
3. **DNG形式** - すべてのデバイスで完全なセンサーデータ保証なし

## Future Enhancements

- [ ] ビデオ撮影対応
- [ ] フォーカスピーキング表示
- [ ] グリッドオーバーレイの強化
- [ ] メータリングモード選択（スポット/中央/全面）
- [ ] 撮影設定プリセット保存機能
- [ ] RAW + JPEG 同時出力
- [ ] バルブ撮影（30秒超える露光）

## Troubleshooting

### カメラが起動しない
- アプリにカメラ許可を与えているか確認
- 実機でテストしているか確認（シミュレータは動作しません）

### マニュアル操作が反応しない
- デバイスがそのパラメータに対応しているか確認
- 設定画面で対応範囲を確認

### 写真が保存されない
- フォトライブラリへのアクセス許可を確認
- デバイスの空き容量を確認

## License

This project is provided as-is for educational and personal use.

## Support

Issues or feature requests: contact the developer

---

**Note**: このアプリは Apple の標準カメラアプリの機能を拡張したものです。ISP 処理の完全削除はハードウェアレベルの制限により不可能ですが、`Remove Apple Processing` オプションと RAW 出力により、最大限に近い「素のデータ」を取得できます。
