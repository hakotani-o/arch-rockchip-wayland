#!/bin/bash
# ログファイルに出力をすべてリダイレクト
exec > /var/log/firstboot-growroot.log 2>&1

echo "=== Starting RootFS Auto Grow ==="

# ルートマウント元のデバイスとパーティション番号を取得
ROOT_DEV=$(findmnt -n -o SOURCE /)
DEV=$(lsblk -no PKNAME "${ROOT_DEV}")
PART=$(echo "${ROOT_DEV}" | grep -o '[0-9]*$')

if [ -z "${DEV}" ] || [ -z "${PART}" ]; then
    echo "ERROR: Could not detect root device."
    exit 1
fi

DEV_PATH="/dev/${DEV}"
echo "Target Device: ${DEV_PATH}, Partition: ${PART}"

# パーティション拡張
growpart "${DEV_PATH}" "${PART}"

# カーネルへパーティション変更の通知
partx -u "${ROOT_DEV}"

# オンラインリサイズ実行 (e2fsprogsのresize2fsを使用)
resize2fs "${ROOT_DEV}"

echo "=== RootFS Auto Grow Completed ==="

# 自身を無効化して次回から動かさない（自爆）
systemctl disable firstboot-growroot.service
