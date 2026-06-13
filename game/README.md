# Hệ Thống Sư Tôn Vô Địch — Visual Novel (Godot 4)

Game visual novel tu tiên chuyển thể theo cốt truyện *"Hệ Thống Sư Tôn Vô Địch
Mạnh Nhất"*: **Cơ Huyền** xuyên không tới thế giới tu tiên, vừa khai cục đã là
**cảnh giới vô địch** nhưng chỉ muốn an nhàn. **Hệ Thống Sư Tôn** ép anh thu nhận
& bồi dưỡng đệ tử — mỗi khi đệ tử (Lăng Thiên, Tô Tuyết, Linh Nhi) lập kỳ tích,
chấn động thiên hạ, Sư Tôn nhận thưởng hậu hĩnh. Anh giấu kín thân phận, làm
"lão phế vật" của Vân Hà Cốc, để đệ tử bay cao. Có **lựa chọn phân nhánh** và
**3 kết thúc** (Vô Địch Sư Tôn / Truyền Thừa Rực Rỡ / An Nhàn Vô Địch).

## Chạy thử trên máy tính
1. Cài [**Godot 4.3+**](https://godotengine.org/download) (bản Standard).
2. Mở Godot → *Import* → chọn `game/project.godot`.
3. Bấm **▶ (F5)** để chơi.

> Lần mở đầu Godot sẽ import asset (vài giây) rồi tạo thư mục `.godot/` (đã được gitignore).

## Cấu trúc
```
game/
  project.godot            cấu hình project (màn hình landscape, mobile renderer)
  autoload/
    GameState.gd           tiến trình, cờ truyện, save/load, settings
    Audio.gd               quản lý BGM/SFX (tự bỏ qua file thiếu)
  scenes/
    Boot · MainMenu · Game · Settings · Ending   (.tscn + .gd)
    Game.gd                BỘ THÔNG DỊCH visual novel (đọc story JSON)
  story/
    characters.json        tên + màu nhân vật
    chapter01..05.json      nội dung 5 chương (có phân nhánh & 3 kết thúc)
  assets/
    bg/ char/ music/        art + audio (đang là placeholder)
  docs/AI_ASSET_PROMPTS.md  prompt để thay bằng asset AI
tools/
  gen_assets.py            sinh lại placeholder art/audio
  validate_story.py        kiểm tra story JSON (link block, asset, kết thúc)
```

## Viết tiếp / sửa cốt truyện
Mỗi chương là một file JSON gồm các *block*, mỗi block là danh sách *lệnh*. Xem
đầy đủ cú pháp ở phần đầu `scenes/Game.gd`. Tóm tắt lệnh:

| Lệnh | Ý nghĩa |
|---|---|
| `{"bg":"name"}` | đổi nền `assets/bg/name.png` |
| `{"music":"name"}` / `{"music":""}` | phát / dừng nhạc nền |
| `{"sfx":"name"}` | phát hiệu ứng |
| `{"show":"char","at":"left|center|right","expr":".."}` | hiện nhân vật |
| `{"hide":"all"}` | ẩn nhân vật |
| `{"say":"Tên","text":"..","color":"#hex"}` | thoại (chờ chạm) |
| `{"narrate":".."}` | lời dẫn |
| `{"choice":[{"text":"..","goto":"block","set":{"flag":val}}]}` | lựa chọn |
| `{"set":{"flag":val}}` / `{"if":"flag","eq":val,"goto":"b","else":"b2"}` | cờ & rẽ nhánh |
| `{"goto":"block"}` / `{"next_chapter":"chapterXX"}` / `{"end":"id"}` | chuyển tiếp |

Sau khi sửa, chạy kiểm tra:
```bash
python3 tools/validate_story.py     # báo lỗi link block / asset thiếu / chương cụt
```

## Thay asset đẹp (AI)
Xem `docs/AI_ASSET_PROMPTS.md`. Chỉ cần ghi đè file cùng tên trong `assets/`.

## Build APK / AAB cho Android
Xem hướng dẫn chi tiết: [`docs/ANDROID_BUILD.md`](docs/ANDROID_BUILD.md).
