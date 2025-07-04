# ShadowingPractice2 修正指示書

## 概要
本ドキュメントは、ShadowingPractice2プロジェクトで発見された不整合と問題点を修正するための指示書です。優先度順に対応してください。

## 1. 【優先度：高】iOS バージョン要件の統一

### 問題
プロジェクト設定とドキュメントでiOSバージョン要件が異なっています。

### 修正内容

#### 1.1 プロジェクト設定の変更
`ShadowingPractice2.xcodeproj/project.pbxproj`を修正：
```
IPHONEOS_DEPLOYMENT_TARGET = 16.0;
```
※ Debug/Release両方の設定を変更してください

#### 1.2 ドキュメントの更新
以下のドキュメントのiOSバージョン要件を16.0に更新：

1. `complete-shadowing-spec.md`：
   - 「最小iOS: 17.0」→「最小iOS: 16.0」に変更

2. `development-guidelines.md`：
   - 「最小サポートiOS: 17.0」→「最小サポートiOS: 16.0」に変更

3. `CLAUDE.md`：
   - 「Minimum iOS: 18.4 (though documentation mentions iOS 17.0 compatibility)」を
   - 「Minimum iOS: 16.0」に変更

### 確認方法
- Xcode上でプロジェクト設定を確認
- iOS 16.0のシミュレータでビルド・実行できることを確認
- すべてのドキュメントでiOS要件が16.0で統一されていることを確認
