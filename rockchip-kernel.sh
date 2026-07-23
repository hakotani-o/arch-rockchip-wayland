#!/bin/bash
set -eE
set -x  # 進行状況がわかるようにデバッグ表示を追加

# 引数のチェック（my-add.txt が指定されているか）
if [ -z "$1" ]; then
    echo "エラー: 第1引数に my-add.txt のパスを指定してください。"
    exit 1
fi

# コンテナの初期設定（root権限で実行）
pacman-key --init
cp -a keyrings /usr/share/pacman 2>/dev/null || true
pacman-key --populate --need archlinuxarm
pacman -Syyu --noconfirm

# 必要なパッケージのインストール
pacman -S --noconfirm --need sudo pacman-contrib

# ビルド用一般ユーザー「builder」の作成とsudo権限付与
useradd -m -G wheel builder
#usermod -G git builder
mkdir -p /etc/sudoers.d
echo "builder ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
chmod 0440 /etc/sudoers.d/builder


# 💡【ここを追加】/etc/gitconfig の権限エラーを根本解決する
# もしファイルがなければ空で作成し、すべてのユーザーが読み込める権限（644）を与えます
touch /etc/gitconfig
chmod 644 /etc/gitconfig
# /etc自体のパーミッションも、一般ユーザーが読み込める状態（755）か確認・修正
chmod 755 /etc


# 作業ディレクトリを /home/builder 内に作成し、所有権を builder に変更
mkdir -p /home/builder/kernel-org
chown -R builder:builder /home/builder

# my-add.txt を builder のホームに移動
mv "$1" /home/builder/my-add.txt
chown builder:builder /home/builder/my-add.txt
mv "$2" /home/builder/make-dot-config.sh
chown builder:builder /home/builder/make-dot-config.sh
chmod +x /home/builder/make-dot-config.sh

# === ここから一般ユーザー「builder」として実行 ===
sudo -u builder bash  << 'EOF'
set -eE
set -x

cd /home/builder/kernel-org

# Gitの初期化とSparse Checkout設定
git init
git config core.sparseCheckout true
git branch -m master
git remote add origin https://github.com/archlinuxarm/PKGBUILDs/
echo "core/linux-aarch64/*" >> .git/info/sparse-checkout

# 必要なフォルダだけをプル
git pull origin master

cd core/linux-aarch64
echo "------------- core/linux-aarch64 ------------------"
ls -la
echo "---------------------------------------------------"

# =========================================================
# ✨ 【超重要】PKGBUILDのprepare関数に、自動設定マージの仕掛けを注入
# =========================================================
# 1. 本家Rockchipのベース設定を生成 (make rockchip_defconfig)
# 2. my-add.txt (JMB582やsystemd用設定) を自動マージ
# 3. 巨大なデバッグ情報を無効化してメモリ不足・容量圧迫を回避
# 4. make olddefconfig で新パラメータを自動補完し、configファイルとして確定させる
# =========================================================
sed -i 's/make prepare/\/home\/builder\/make-dot-config.sh/' PKGBUILD
sed -i 's/pkgbase=linux-aarch64/pkgbase=linux-aarch64-rockchip/' PKGBUILD
cp linux-aarch64.install linux-aarch64-rockchip.install
cp linux-aarch64-chromebook.install linux-aarch64-rockchip-chromebook.install


# ソースの展開とチェックサム更新
#updpkgsums
#makepkg -od --noconfirm

# チェックサムの再更新
#updpkgsums

# カーネルのビルド（--noconfirm で依存関係の自動インストールを許可）
MAKEFLAGS="-j$(nproc)" makepkg -s 2>&1|tee ~/arch-build-log.txt


EOF
# === 一般ユーザーでの実行ここまで ===

# 出来上がったパッケージをコンテナのルート「/」に配置
cp /home/builder/kernel-org/core/linux-aarch64/linux-aarch64-rockchip-[0-9]*-aarch64.pkg.tar.* /
cp /home/builder/kernel-org/core/linux-aarch64/linux-aarch64-rockchip-headers-[0-9]*-aarch64.pkg.tar.* /

# ビルドログを root 権限で / に退避（base_kernel.sh が回収できるようにする）
cp /home/builder/*.txt / 2>/dev/null || true

