#!/bin/bash
set -eE

mkdir -p ./mnt/usr/local/bin
cp ./firstboot-growroot.sh ./mnt/usr/local/bin
chmod +x ./mnt/usr/local/bin/firstboot-growroot.sh


# ① 【SDDM対応】setupadmin の自動ログインを設定
# SDDMは conf.d 形式で設定を流し込むのがArchの標準で、スマートです
mkdir -p ./mnt/etc/sddm.conf.d
cat << 'EOF_SDDM' > ./mnt/etc/sddm.conf.d/autologin.conf
[Autologin]
User=setupadmin
#Session=lxqt-wayland.desktop
Session=labwc.desktop
EOF_SDDM

# ③ ウィザードスクリプトの配置
cat << 'EOF' > ./mnt/usr/local/bin/gui-wizard.sh
#!/bin/bash

# 【Wayland対応】Zenity用の環境変数
export GDK_BACKEND=wayland

# 🌟【もう一味！】もし環境変数が空なら、現在のユーザー(UID:1000)の値を自動セット
[ -z "$XDG_RUNTIME_DIR" ] && export XDG_RUNTIME_DIR=/run/user/1000
[ -z "$WAYLAND_DISPLAY" ] && export WAYLAND_DISPLAY=wayland-0
[ -z "$DBUS_SESSION_BUS_ADDRESS" ] && export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# 🌟 誤作動する安全チェック（if文）はすべて削除しました！

# ========================================================
# ここから本番の入力画面
# ========================================================
NEW_USER=$(zenity --entry --title="Initial Setup" --text="新しい一般ユーザー名を入力してください:" --width=400)

# キャンセルボタンが押された、または空欄だった場合の安全弁
# (自動起動のタイミングズレで空文字になった場合も、再起動せずSDDMをリスタートしてやり直します)
if [ -z "$NEW_USER" ]; then
    echo "[INFO] User input was empty. Restarting SDDM..." >> /tmp/wizard.log
    sudo systemctl restart sddm
    exit 0
fi

# --- これ以降のパスワード設定やmkinitcpioの処理はそのまま ---
while true; do
    PASS1=$(zenity --password --title="Initial Setup" --text="パスワードを設定してください:")
    PASS2=$(zenity --password --title="Initial Setup" --text="もう一度パスワードを入力してください:")
    if [ "$PASS1" = "$PASS2" ] && [ ! -z "$PASS1" ]; then
        break
    fi
    zenity --error --text="パスワードが一致しないか、空欄です。再入力してください。"
done

sudo useradd -m -s /bin/bash -G wheel,users,video "$NEW_USER"
echo "$NEW_USER:$PASS1" | sudo chpasswd


if [ -f "/etc/mkinitcpio.conf.org" ]; then
    sudo cp /etc/mkinitcpio.conf.org /etc/mkinitcpio.conf
    sudo rm -f /etc/mkinitcpio.conf.org
    (
        echo "# 復元された設定で initramfs を再構築中..."
        sudo mkinitcpio -P 2>&1
	sudo cp /boot/initramfs-linux.img /boot/initrd.img-$(uname -r)
	sudo rm /boot/initramfs-linux.img
        echo "# 再構築が完了しました！"
    ) | zenity --text-info --title="システム最適化中" --width=600 --height=400 --auto-scroll
fi

# ==========================================
# 1. タイムゾーンの選択・設定
# ==========================================
SELECTED_TZ=$(awk '/^[^#]/ {print $3}' /usr/share/zoneinfo/zone.tab | sort | \
zenity --list \
  --title="初期設定 - タイムゾーン Time zone" \
  --text="タイムゾーンを選択してください:" \
  --column="タイムゾーン" \
  --width=400 --height=450)

if [ -n "$SELECTED_TZ" ]; then
    # 起動中なので timedatectl がそのまま使えます
    sudo  ln -s /usr/share/zoneinfo/"$SELECTED_TZ" /etc/localtime
fi


# ==========================================
# 2. キーボードレイアウトの選択・設定
# ==========================================
# 主要なレイアウトのみを厳選してリスト化（ユーザーが迷わないため）
SELECTED_KEYMAP=$(zenity --list \
  --title="初期設定 - キーボード Keyboard" \
  --text="キーボードの配列を選択してください:" \
  --column="コード" --column="キーボード配列" \
  --hide-column=1 \
  "jp" "日本語配列 (jp)" \
  "us" "US layout (us)" \
  "uk" "UK layout (uk)" \
  --width=500 --height=300)

if [ -n "$SELECTED_KEYMAP" ]; then
    # localectl コマンドで、コンソールとX11/Wayland両方のキーボードを同時に設定
    sudo localectl set-x11-keymap "$SELECTED_KEYMAP"
    echo "XKB_DEFAULT_LAYOUT=$SELECTED_KEYMAP" | sudo tee -a /etc/environment
    echo "XKB_DEFAULT_MODEL=pc105" | sudo tee -a /etc/environment
fi


# ==========================================
# 3. システム言語（LANG）の選択・設定
# ==========================================
# ディスクイメージ内に事前に生成（locale-gen）されている主要言語を選択肢にする
SELECTED_LANG=$(zenity --list \
  --title="初期設定 - 言語 Locale" \
  --text="システム言語 (LANG) を選択してください:" \
  --column="ロケール" --column="言語" \
  --hide-column=1 \
  "ja_JP.UTF-8" "日本語 (ja_JP.UTF-8)" \
  "en_US.UTF-8" "English (en_US.UTF-8)" \
  --width=500 --height=300)

if [ -n "$SELECTED_LANG" ]; then
    # システム全体のロケールを設定
    echo "LANG=$SELECTED_LANG" | sudo tee -a /etc/environment
    sudo sed -i "s/#$SELECTED_LANG/$SELECTED_LANG/" /etc/locale.gen
    sudo locale-gen
    sudo sed -i "s/C.UTF-8/$SELECTED_LANG/" /etc/locale.conf
    sudo localectl set-locale LANG="$SELECTED_LANG"
fi

sudo rm -f /etc/sddm.conf.d/autologin.conf
sudo rm -f /etc/sudoers.d/setupadmin
sudo rm -f /home/setupadmin/.config
# 次回起動時に setupadmin を完全消去する1回限りのサービスを有効化
sudo systemctl enable setup-cleanup.service

zenity --info --text="設定が完了しました。システムを再起動します。" --width=300
sudo rm -f /etc/xdg/autostart/first-boot-wizard.desktop
sudo reboot
EOF

# 実行権限を付与
chmod +x ./mnt/usr/local/bin/gui-wizard.sh

# 6 setupadmin 削除
cat << 'EOF_SETUPADMIN' > ./mnt/etc/systemd/system/setup-cleanup.service
[Unit]
Description=First Boot Cleanup Service
After=systemd-user-sessions.service

[Service]
Type=oneshot
# setupadmin のプロセスを強制終了したあと、ユーザーとホームディレクトリ>を完全削除し、このサービス自体を無効化
ExecStart=/usr/bin/bash -c "pkill -u setupadmin; userdel -r setupadmin; systemctl disable setup-cleanup.service"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF_SETUPADMIN


# 3. systemd サービスファイルの作成
cat << EOF4 > ./mnt/etc/systemd/system/firstboot-growroot.service
[Unit]
Description=First Boot Root Partition Resizer
After=local-fs.target
Before=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/firstboot-growroot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF4

# 4. 【Chromium仕様確認】
# Arch LinuxのChromiumは、環境変数ファイルを /etc/chromium/default ではなく
# 「/etc/chromium-flags.conf」として1行ずつフラグを並べる仕様が一般的です
mkdir -p ./mnt/etc
cat << 'EOF_CHROME' > ./mnt/etc/chromium-flags.conf
--enable-features=AcceleratedVideoDecoder,V4l2VideoDecode
--disable-features=UseChromeOSDirectVideoDecoder
EOF_CHROME

# ③ SDDMに「Xfce (Wayland)」の選択肢を追加する
#JFLimさんが動かしていたものと同じ「Xfce (Wayland)」をSDDMのメニューに出現させるため、以下のデスクトップエントリーファイルを生成します。

# 【Xfce Wayland対応】SDDM用のセッションファイルを作成
mkdir -p ./mnt/usr/share/wayland-sessions
cat << 'EOF_XFCE_WAY' > ./mnt/usr/share/wayland-sessions/xfce-wayland.desktop
[Desktop Entry]
Version=1.0
Name=Xfce (Wayland)
Comment=Run Xfce with Labwc backend
Exec=startxfce4 --wayland
Type=Application
DesktopNames=XFCE
EOF_XFCE_WAY

