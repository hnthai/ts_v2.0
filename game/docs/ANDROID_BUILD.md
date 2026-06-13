# Build & xuất bản lên Android

## A. Chuẩn bị một lần
1. **Godot 4.3+** (Standard).
2. **Export Templates**: Trong Godot → *Editor ▸ Manage Export Templates ▸ Download and Install*.
3. **OpenJDK 17** (cho keystore & gradle): cài JDK 17.
4. **Android SDK**: cách nhanh nhất là cài **Android Studio**, rồi trong Godot →
   *Editor ▸ Editor Settings ▸ Export ▸ Android* trỏ:
   - `Java SDK Path` → JDK 17
   - `Android SDK Path` → thư mục SDK (vd: `~/Android/Sdk`)
   - bấm **Install Build Template** nếu dùng Gradle/AAB.

## B. Tạo keystore (chữ ký số — bắt buộc để phát hành)
```bash
keytool -genkeypair -v \
  -keystore suton.keystore -alias suton \
  -keyalg RSA -keysize 2048 -validity 10000
```
> Giữ file `.keystore` + mật khẩu **thật cẩn thận**: mất nó = không thể cập nhật app trên Play Store.

Trong Godot → *Project ▸ Export ▸ Android* (đã có sẵn 2 preset trong
`export_presets.cfg`), ở mục **Keystore** điền đường dẫn keystore + alias + mật khẩu
cho bản *release*. (Không commit keystore/mật khẩu lên git.)

## C. Sửa thông tin app
Trong preset Android, đổi:
- `package/unique_name`: từ `com.example.sutonvodich` → tên miền đảo ngược **của bạn** (vd `com.tenban.suton`). **Không trùng** app khác trên Play.
- `version/code` (số nguyên tăng dần mỗi lần phát hành) và `version/name` (vd `1.0.0`).
- `launcher_icons/...`: trỏ tới icon 192×192 (và adaptive 432×432). Có thể export `icon.svg` ra PNG.

## D. Export
- **APK** (test nhanh trên máy/điện thoại): preset *"Android"* → *Export Project* → `build/su-ton-vo-dich.apk`.
  Cài thử: `adb install -r build/su-ton-vo-dich.apk`.
- **AAB** (định dạng Google Play yêu cầu): preset *"Android (AAB - Play Store)"*
  (`gradle_build/use_gradle_build=true`, `export_format=1`) → ra `build/su-ton-vo-dich.aab`.

## E. Đưa lên Google Play
1. Đăng ký **Google Play Developer** ($25 một lần): https://play.google.com/console
2. *Create app* → điền tên, ngôn ngữ, loại Game.
3. Hoàn tất các mục bắt buộc:
   - **Privacy policy** (URL) — bắt buộc kể cả game offline.
   - **Content rating** (bảng câu hỏi IARC).
   - **Data safety**, **Target audience**, **Ads** (game này không quảng cáo/không internet → khai báo đơn giản).
   - Store listing: mô tả, **icon 512×512**, **feature graphic 1024×500**, screenshot.
4. Tải **AAB** lên track **Internal testing** trước → mời tester → kiểm tra thật.
5. Khi ổn: nâng dần **Closed → Open → Production**.

## Kiểm thử chất lượng trước khi phát hành (checklist)
- [ ] Chơi xuyên suốt cả 5 chương + thử cả 3 kết thúc (đổi lựa chọn).
- [ ] `python3 tools/validate_story.py` không còn lỗi.
- [ ] Save → thoát → *Chơi tiếp* khôi phục đúng vị trí.
- [ ] Test trên ≥2 kích thước màn hình (điện thoại + máy tính bảng).
- [ ] Không crash khi thiếu asset (đã xử lý fallback).
- [ ] APK chạy mượt, thời gian khởi động chấp nhận được.
- [ ] Tăng `version/code` trước mỗi lần upload bản mới.
