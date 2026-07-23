#!/bin/bash
set -eE

mkdir -p ./mnt/usr/local/bin
cp ./firstboot-growroot.sh ./mnt/usr/local/bin
chmod +x ./mnt/usr/local/bin/firstboot-growroot.sh

# 【Arch仕様】Pacmanフックの設定
# ※もしカスタムカーネルのパッケージ名が「linux」以外なら、Targetを変更してください
CONF="./mnt/etc/pacman.d/hooks/update-extlinux.hook"
mkdir -p ./mnt/etc/pacman.d/hooks
cat << EOF2 > $CONF
[Trigger]
Operation = Upgrade
Type = Package
Target = linux

[Action]
When = PostTransaction
Exec = /usr/local/bin/generate-extlinux.sh
EOF2


# ① 【SDDM対応】setupadmin の自動ログインを設定
# SDDMは conf.d 形式で設定を流し込むのがArchの標準で、スマートです
mkdir -p ./mnt/etc/sddm.conf.d
cat << 'EOF_SDDM' > ./mnt/etc/sddm.conf.d/autologin.conf
[Autologin]
User=setupadmin
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

sudo useradd -m -s /bin/bash -G wheel,video "$NEW_USER"
echo "$NEW_USER:$PASS1" | sudo chpasswd
sudo rm -f /etc/xdg/autostart/first-boot-wizard.desktop

if [ -f "/etc/mkinitcpio.conf.org" ]; then
    sudo cp /etc/mkinitcpio.conf.org /etc/mkinitcpio.conf
    sudo rm -f /etc/mkinitcpio.conf.org
    (
        echo "# 復元された設定で initramfs を再構築中..."
        sudo mkinitcpio -P 2>&1
        echo "# 再構築が完了しました！"
    ) | zenity --text-info --title="システム最適化中" --width=600 --height=400 --auto-scroll
fi

sudo rm -f /etc/sddm.conf.d/autologin.conf
sudo rm -f /etc/sudoers.d/setupadmin
sudo rm -f /home/setupadmin/.config
zenity --info --text="設定が完了しました。システムを再起動します。" --width=300
sudo reboot
EOF

# 実行権限を付与
chmod +x ./mnt/usr/local/bin/gui-wizard.sh

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

