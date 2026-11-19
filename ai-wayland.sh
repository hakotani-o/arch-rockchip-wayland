#!/bin/bash
set -eE
set -x

mkdir -p ./mnt/usr/local/bin
cp ./firstboot-growroot.sh ./mnt/usr/local/bin
chmod +x ./mnt/usr/local/bin/firstboot-growroot.sh

# ==============================================================================
# GNOME / GDM 初回セットアップウィザード・自動ログイン構築ブロック
# ==============================================================================
TARGET_ROOT="./mnt"

# 1. 【GDM対応】setupadmin の自動ログイン設定（Wayland有効）
mkdir -p "${TARGET_ROOT}/etc/gdm"
cat << 'EOF_GDM' > "${TARGET_ROOT}/etc/gdm/custom.conf"
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=setupadmin
InitialSetupEnable=false
RemoteLoginEnable=false
XorgEnable=false

[security]

[xdmcp]

[chooser]

[debug]
EOF_GDM
#
# move disk_image.sh
#

# 3. 【GNOME自動起動】ログイン直後に gui-wizard.sh を起動する .desktop 配置
mkdir -p "${TARGET_ROOT}/etc/xdg/autostart"
cat << 'EOF_AUTOSTART' > "${TARGET_ROOT}/etc/xdg/autostart/first-boot-wizard.desktop"
[Desktop Entry]
Type=Application
Name=First Boot Wizard
Exec=/usr/local/bin/gui-wizard.sh
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF_AUTOSTART

# 4. 【ウィザード本体】GDM / GNOME Wayland 対応 gui-wizard.sh
mkdir -p "${TARGET_ROOT}/usr/local/bin"
cat << 'EOF_WIZARD' > "${TARGET_ROOT}/usr/local/bin/gui-wizard.sh"
#!/bin/bash

# 【Wayland対応】Zenity用の環境変数
export GDK_BACKEND=wayland

# 環境変数が空なら、現在のユーザー(UID:1000)の値を自動セット
[ -z "$XDG_RUNTIME_DIR" ] && export XDG_RUNTIME_DIR=/run/user/1000
[ -z "$WAYLAND_DISPLAY" ] && export WAYLAND_DISPLAY=wayland-0
[ -z "$DBUS_SESSION_BUS_ADDRESS" ] && export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# ========================================================
# 1. 新規ユーザー作成・パスワード設定
# ========================================================
NEW_USER=$(zenity --entry --title="Initial Setup" --text="新しい一般ユーザー名を入力してください:" --width=400)

# キャンセルまたは空欄の場合は GDM を再起動してやり直す
if [ -z "$NEW_USER" ]; then
    echo "[INFO] User input was empty. Restarting GDM..." >> /tmp/wizard.log
    sudo systemctl restart gdm
    exit 0
fi

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

# ========================================================
# 2. initramfs の復元・再構築（必要な場合のみ）
# ========================================================
if [ -f "/etc/mkinitcpio.conf.org" ]; then
    sudo cp /etc/mkinitcpio.conf.org /etc/mkinitcpio.conf
    sudo rm -f /etc/mkinitcpio.conf.org
    (
        echo "# 復元された設定で initramfs を再構築中..."
        sudo mkinitcpio -P 2>&1
        sudo ldconfig
        echo "# 再構築が完了しました！"
    ) | zenity --text-info --title="システム最適化中" --width=600 --height=400 --auto-scroll
fi

# ========================================================
# 3. タイムゾーンの選択・設定
# ========================================================
SELECTED_TZ=$(awk '/^[^#]/ {print $3}' /usr/share/zoneinfo/zone.tab | sort | \
zenity --list \
  --title="初期設定 - タイムゾーン Time zone" \
  --text="タイムゾーンを選択してください:" \
  --column="タイムゾーン" \
  --width=400 --height=450)

if [ -n "$SELECTED_TZ" ]; then
    sudo ln -sf /usr/share/zoneinfo/"$SELECTED_TZ" /etc/localtime
fi

# ========================================================
# 4. キーボードレイアウトの選択・設定
# ========================================================
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
    sudo localectl set-x11-keymap "$SELECTED_KEYMAP"
    echo "XKB_DEFAULT_LAYOUT=$SELECTED_KEYMAP" | sudo tee -a /etc/environment
    echo "XKB_DEFAULT_MODEL=pc105" | sudo tee -a /etc/environment
fi

# ========================================================
# 5. システム言語（LANG）の選択・設定
# ========================================================
SELECTED_LANG=$(zenity --list \
  --title="初期設定 - 言語 Locale" \
  --text="システム言語 (LANG) を選択してください:" \
  --column="ロケール" --column="言語" \
  --hide-column=1 \
  "ja_JP.UTF-8" "日本語 (ja_JP.UTF-8)" \
  "en_US.UTF-8" "English (en_US.UTF-8)" \
  --width=500 --height=300)

if [ -n "$SELECTED_LANG" ]; then
    echo "LANG=$SELECTED_LANG" | sudo tee -a /etc/environment
    sudo sed -i "s/#$SELECTED_LANG/$SELECTED_LANG/" /etc/locale.gen
    sudo locale-gen
    sudo sed -i "s/C.UTF-8/$SELECTED_LANG/" /etc/locale.conf
    sudo localectl set-locale LANG="$SELECTED_LANG"
fi

# ========================================================
# 6. 後処理（自動ログイン解除・cleanupサービス有効化・再起動）
# ========================================================
sudo sed -i '/^TimeLogin/d' /etc/gdm/custom.conf
sudo sed -i '/^AutomaticLogin/d' /etc/gdm/custom.conf
sudo rm -f /etc/sudoers.d/setupadmin
sudo rm -rf /home/setupadmin/.config

zenity --info --text="設定が完了しました。システムを再起動します。" --width=300
sudo rm -f /etc/xdg/autostart/first-boot-wizard.desktop
sudo systemctl enable setup-cleanup.service
sudo reboot
EOF_WIZARD

chmod +x "${TARGET_ROOT}/usr/local/bin/gui-wizard.sh"

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
--enable-features=AcceleratedVideoDecoder,V4l2VideoDecoder
--disable-features=UseChromeOSDirectVideoDecoder
EOF_CHROME



# 5. 【後片付け】次回起動時に setupadmin を完全削除するサービス
mkdir -p "${TARGET_ROOT}/etc/systemd/system"
cat << 'EOF_SETUPADMIN' > "${TARGET_ROOT}/etc/systemd/system/setup-cleanup.service"
[Unit]
Description=First Boot Cleanup Service
After=systemd-user-sessions.service

[Service]
Type=oneshot
ExecStart=/usr/bin/bash -c "pkill -u setupadmin; userdel -r setupadmin; systemctl disable setup-cleanup.service"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF_SETUPADMIN

