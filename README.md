
# Arch Linux ARM for Orange Pi 5 / 5-Plus (Wayland Optimized)

Orange Pi 5（無印）および Orange Pi 5-Plus 向けに最適化された、カスタム Arch Linux ARM ディスクイメージの自動ビルドプロジェクトです。  
Rockchipのハードウェア特性を最大限に活かすカスタムカーネルと、軽量・高速な Wayland デスクトップ環境をクリーンなコンテナ環境から完全自動で生成します。

---

## 🚀 主な特徴とシステム構成

### 1. カスタム Rockchip カーネルの自動ビルド
本家 Arch Linux ARM の品質をベースに、実用性と安定性を極限まで高めたカスタムカーネルパッケージ（`linux-aarch64-rockchip`）をコンテナ内でクリーンビルドします。

* **完全自動化パイプライン:** `base_kernel.sh` および `rockchip-kernel.sh` による一気通貫のビルド環境構築。
* **スマート・コンフィグマージ:** 独自の自動構成スクリプト（`make-dot-config.sh`）により、本家のベース設定に独自の周辺機器・システム最適化差分（`my-add.txt`）を自動統合（JMB582 SATAコントローラ対応や、systemd動作に必要な要件を網羅）。
* **リソース最適化:** 巨大なデバッグ情報（DWARF5等）を無効化し、ビルド時のメモリ不足や容量圧迫を完全に回避。
* **セキュアなビルド環境:** コンテナの初期化、一般ユーザー（`builder`）への適切なsudo権限付与、権限エラー（`/etc/gitconfig` 等）の根本解決を内包。
* **高精度な分析:** ブート時間のログ解析（`systemd-analyze` 等）に基づいた、カーネルパラメーターの最適化。

### 2. 高速・軽量なカスタム Rootfs の生成
`pacstrap` を用いたクリーンビルドコンテナにより、無駄のない洗練されたルートファイルシステムを構築します。

* **パッケージの厳選:** 必要な依存関係だけを最小限に選定したシステムフットプリント。
* **自動インフラストラクチャ:** `base_rootfs.sh` と `pacstrap.sh` による再現性の高い自動生成。
* **ストレージの自動拡張:** `firstboot-growroot.sh` により、初回起動時にSDカードやNVMe SSDの全容量へシステム領域を自動拡張。
* **スマート起動スクリプト:** 初回ブート時の一般ユーザー自動作成、およびハードウェア環境に合わせた `initramfs` の自動再構築。
* **ブートローダーの自動生成:** 実機環境に応じた `extlinux.conf` の動的自動作成。
* **マルチメディア最適化:** ChromiumブラウザでのGPUハードウェアデコード（動画再生の高速化）を標準プリセット。
* **AI最適化秘伝スクリプト:** システムの利便性と美観を極限まで高める特製スタック（`ai-wayland.sh`）の注入。

### 3. 洗練された Out-of-the-Box デスクトップ環境
イメージを焼き付けて起動した瞬間から、実用的な次世代グラフィックス環境が利用可能です。

* **ウインドウマネージャ:** Openboxライクで極めて軽量・軽快に動作する Wayland コンポジタ `labwc` の最適化配置。
* **ステータスバー:** システムリソース（CPU温度、メモリ等）を美しく可視化する `waybar` の洗練されたプリセット。
* **日本語環境:** 初回起動時からストレスなく作業に移行できる、日本語入力（Fcitx5 / Mozc 等）の完全セットアップ。

---

## 🛠 開発・ビルドの軌跡（謝辞にかえて）
本プロジェクトの完成にあたり、ローカルコンテナ環境から GitHub Actions による CI/CD 構築に至るまで、**30回以上**に及ぶビルドテストと過酷な負荷検証（4K動画再生テスト、ファンレス自然冷却環境での温度検証等）を行いました。
数々のパーミッションエラー、依存パッケージのNoble環境への追従、アップロード構成の微調整といった技術的障壁を一つずつロジカルに解決し、最終的に「一発で美しく成功したクリーンなリリースイメージ」として結実しました。

本プロジェクトは、人間のエンジニアの構想力とAIの技術的サポートが融合した「AI共同開発（AI Co-Development）」によって誕生しました。

- **Main Lead & Build Architect**: hakotani
  - **GitHub**: [@hakotani-o](https://github.com)
  - 各スクリプトの作成、動作確認、ビルドイメージの動作確認（WIFI,BT,IPv6,CAMなど開発環境の制約のため動作確認ができていないものもあります）  
- **AI Co-Pilot & Technical Advisor**: Google AI
  - *各スクリプトのレビューや技術的な手法、エラー対応を全面的にサポート。*
    
---

## 📄 ライセンス / 免責事項 (License & Disclaimer)

### ライセンスについて
本リポジトリに含まれるビルドスクリプトおよび設定ファイルは、**MIT ライセンス**のもとで公開されています。商用・非商用を問わず、複製、改変、再配布、および使用が完全に自由です。
*(ただし、本スクリプトによってダウンロード・構築されるカーネル、Rootfs、各パッケージの著作権・ライセンスは、それぞれの原著作者（Arch Linux ARM, Rockchip 等）に帰属します。)*

### 免責事項
1. **自己責任での利用:** 本プロジェクトで提供されるディスクイメージおよびスクリプトは、「現状のまま（As-Is）」提供されます。動作保証や特定の目的への適合性を含め、明示・黙示を問わず一切の保証はありません。
2. **損害への責任:** 本成果物を使用したことによる、Orange Pi 5/5-Plus 実機の破損、データの消失、その他いかなる損害や不利益に対しても、開発者は一切の責任を負いません。必ず重要なデータのバックアップを取り、ご自身の責任においてご使用ください。
3. **本家プロジェクトとの関係:** 本プロジェクトは個人によるカスタムビルドであり、Arch Linux、Arch Linux ARM、および Xunlong (Orange Pi) 公式プロジェクトとは一切関係がありません。公式コミュニティへの問い合わせはお控えください。

---

## 🚀 導入・初期設定ガイド (Getting Started Guide)

本イメージをストレージに書き込み、起動した後の初期設定と、軽量デスクトップ環境（`labwc` + `waybar`）の構築手順です。

---

### 1. 初回起動 (FIRST BOOT) 〜 ユーザーアカウントの作成
イメージを書き込んだストレージを実機にセットし、電源を入れます。

* **初回起動時の挙動:**
  起動すると、自動的に**初期ユーザー登録画面**が表示されます。
  画面の指示に従って、**ご自身が使用したい「ユーザー名」と「パスワード」を自由に設定してください。**
* **⚠️ 重要（再構築の待機）：**
  ユーザー登録の後で、システムは `initramfs` の自動再構築やストレージ容量の自動拡張（`growroot`）を実行しています。画面に「OK/キャンセル」などのプロンプトが表示されても、**操作は行わず、すべての自動再構築処理が完全に終了するまで数分間そのままお待ちください。**

---

### 2. 2回目以降の起動 (SECOND BOOT) 〜 デスクトップ環境の構築
設定したユーザーでログインし、2回目以降の起動を迎えると、画面は **「黒画面にマウスカーソルだけ」** が表示された状態になります（ **Wayland** 最小構成の **正常** な挙動です）。

マウスを右クリックするとメニューが開くので、ターミナル（Terminal）を起動して以下の初期設定を進めていきます。

#### セットアップ用プロセスのクリーンアップ
初回ユーザー登録を担当していた裏方アカウント（`setupadmin`）とその環境が不要になるため、作成したご自身のユーザーでターミナルを開き、完全に削除します。
```bash
sudo userdel -r setupadmin
```

#### キーボードの日本語レイアウト設定
```bash
# labwcの設定テンプレートをコピー
cp -r /usr/share/doc/labwc ~/.config/labwc

# 環境変数ファイルに変数を追加
vi ~/.config/labwc/environment
# 末尾に以下を追加
XKB_DEFAULT_LAYOUT=jp
```
* **反映:** マウス右クリックメニュー ➔ `Reconfigure` を実行して反映させます。

#### タイムゾーンとロケール（日本語化）の設定
```bash
# タイムゾーンを東京に設定
sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# ロケールの生成
sudo vi /etc/locale.gen
# 「#ja_JP.UTF-8 UTF-8」のコメントアウト（#）を解除
sudo locale-gen

# システムロケールの変更
sudo vi /etc/locale.conf
# 「C.UTF-8」を「ja_JP.UTF-8」書き換え
```

#### オーディオ（音量）の設定
```bash
# アルサミキサーの起動
alsamixer
```
* `F6` キーを押してオーディオデバイスを選択します。
* `OUTPUT1` のボリュームを **65〜75** 程度に調整し、`ESC` で終了します。
* 必要に応じて `pavucontrol` を使用し、GUI側から音声出力を切り替えてください。

---

### 3. デスクトップ環境（labwc / waybar）のカスタマイズ

#### 必要パッケージとアイコン・テーマのインストール
```bash
sudo pacman -S waybar ttf-font-awesome otf-font-awesome ttf-nerd-fonts-symbols \
               adwaita-icon-theme hicolor-icon-theme lxqt-config \
               qt5-wayland qt6-wayland qt5ct qt6ct
```
Qtアプリケーションにテーマを適用するため、環境変数を追加します。
```bash
echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> ~/.bash_profile
```

#### Waybar（ステータスバー）の設定
```bash
# 設定テンプレートをコピー
cp -r /etc/xdg/waybar ~/.config/waybar

vi ~/.config/waybar/config.jsonc
```
1. バーを画面下に配置するため `"position": "bottom",` のコメントアウトを解除。
2. 左側モジュールにショートカット通知を追加。
```jsonc
   "modules-left": [
        "sway/workspaces",
        "sway/mode",
        "sway/scratchpad",
        "custom/media", // 後ろに「,」を追加
        "custom/shortcut" // 追加
    ],
```
3. ファイルの最下部に電源ボタンとショートカット表示の設定を注入。
```jsonc
    "custom/power": {
        "format" : "⏻ ",
        "tooltip": false,
        "on-click": "systemctl poweroff"
    }, // 後ろに「,」を追加
    "custom/shortcut": {
        "format": "Super+Enter : Terminal ",
        "tooltip": false
    }
}
```

#### キーバインドと自動起動の設定
```bash
# 1. ターミナル起動ショートカットの変更
デフォルトでは `W-Return` (Super + Enter) で `foot` が起動する設定になっています。
ご自身が使用するターミナルエミュレータ（例: `qterminal` など）に合わせて、設定ファイルを編集してください。

vi ~/.config/labwc/rc.xml

<!-- <keyboard> セクション内の以下のアクションを編集します -->
<keybind key="W-Return">
  <!-- 使用したいターミナルコマンド（例: qterminal）に書き換えます -->
  <action name="Execute" command="qterminal" /> 
</keybind>


# 2. 自動起動スクリプトの設定
vi ~/.config/labwc/autostart
# 以下を追加して保存、デフォルトの設定で不要なアプリケーションの起動があれば # でコメント化してください
pcmanfm-qt --daemon-mode &
```

#### 右クリックメニューのカスタマイズ
```bash
vi ~/.config/labwc/menu.xml
```
よく使うアプリケーションをメニューに登録します。
```xml
<menu id="root-menu">
  <item label="Terminal"><action name="Execute" command="lab-sensible-terminal" /></item>
  <item label="Firefox"><action name="Execute" command="firefox" /></item>
  <item label="Thunderbird"><action name="Execute" command="thunderbird" /></item>
  <item label="Pcmanfm-qt"><action name="Execute" command="pcmanfm-qt" /></item>
  <item label="Chromium"><action name="Execute" command="chromium" /></item>
  <separator />
```
* **反映:** 設定後、ターミナルで `labwc --reconfigure` を実行するか、メニューからリコンフィグします。

---

### 4. ブラウザ（Chromium）のWayland＆ハードデコード最適化
```bash
sudo pacman -S chromium

# デスクトップエントリーをローカルにコピーして編集
mkdir -p ~/.local/share/applications/
cp /usr/share/applications/chromium.desktop ~/.local/share/applications/
vi ~/.local/share/applications/chromium.desktop

# 起動コマンド（Exec）行をWaylandネイティブ起動モードに書き換え
# 変更前: Exec=/usr/bin/chromium %U
# 変更後:
Exec=/usr/bin/chromium --ozone-platform=wayland %U
```
* **YouTubeの負荷軽減:** マウスメニューからChromiumを起動し、拡張機能ストアで **「enhanced-h264ify」** を検索してインストールします。これにより、CPUに優しいH.264形式での再生が強制され、劇的に軽快になります。

---

### 5. 日本語入力（Fcitx5-Mozc）の完全セットアップ
```bash
sudo pacman -S fcitx5-im fcitx5-mozc fcitx5-configtool noto-fonts-cjk
```
Wayland環境で入力システムを正常に動作させるため、環境設定ファイルを新規作成します。
```bash
mkdir -p ~/.config/environment.d
vi ~/.config/environment.d/10-wayland-im.conf
```
以下を記述して保存します。
```text
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
KEYBOARD_DEFAULT_IM=fcitx
```
最後に、ログイン時にFcitx5が自動起動するように設定します。
```bash
vi ~/.config/labwc/autostart
# 末尾に以下を追加
fcitx5 -d
```
