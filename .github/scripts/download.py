import os
import json
import io
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

def download_file():
    # GitHub Secrets から環境変数経由で JSON キーを読み込む
    key_info = json.loads(os.environ["GCP_SERVICE_ACCOUNT_KEY"])
    creds = service_account.Credentials.from_service_account_info(
        key_info, 
        scopes=['https://googleapis.com']
    )

    # Drive API サービスの構築
    service = build('drive', 'v3', credentials=creds)

    file_id = '1s7obgLU7z0PgjoxBYkIt2KzWVCsGGEny'
    output_filename = 'MY.tar' # 保存したいファイル名

    # ダウンロードリクエスト
    request = service.files().get_media(fileId=file_id)
    fh = io.FileIO(output_filename, 'wb')
    downloader = MediaIoBaseDownload(fh, request)
    
    done = False
    while done is False:
        status, done = downloader.next_chunk()
        print(f"Download {int(status.progress() * 100)}%.")

if __name__ == '__main__':
    download_file()
