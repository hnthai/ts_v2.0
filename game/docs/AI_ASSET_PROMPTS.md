# Prompt sinh asset bằng AI

Game hiện chạy bằng **art placeholder** (sinh bởi `tools/gen_assets.py`). Để có
hình đẹp, dùng các prompt dưới đây với công cụ sinh ảnh bất kỳ (Midjourney,
Stable Diffusion, DALL·E, Firefly, Nano Banana...), rồi **ghi đè file cùng tên**
trong `game/assets/`. Tên file phải khớp tuyệt đối — game tự nhận.

## Quy cách kỹ thuật
- **Background:** 1280×720 (16:9), `.png`, không chữ, không nhân vật ở giữa khung hội thoại (vùng dưới 230px nên thoáng).
- **Nhân vật:** ~480×720, `.png` **nền trong suốt (transparent)**, nhân vật đứng nửa người/toàn thân, chừa lề.
- Phong cách thống nhất: **tu tiên / xianxia / donghua, màu sắc điện ảnh, ánh sáng mềm**. Gợi ý thêm vào mọi prompt: `chinese cultivation fantasy, donghua style, cinematic lighting, highly detailed, no text`.

---

## Backgrounds (`game/assets/bg/<tên>.png`)

| File | Prompt gợi ý |
|---|---|
| `title.png` | Bìa game: đỉnh núi tiên hùng vĩ trong mây, một bóng kiếm khách đứng nhìn ra xa, ánh tím vàng huyền ảo, hoành tráng |
| `sect_gate.png` | Cổng tông môn cổ kính trên núi mây, ban ngày, rêu phong, hơi tàn tạ nhưng uy nghiêm |
| `hall.png` | Đại điện gỗ trong tông môn, ánh nến ấm, cột chạm rồng, trang nghiêm |
| `courtyard.png` | Sân tu luyện lát đá, cây cổ thụ, ban ngày trong trẻo |
| `courtyard_night.png` | Sân tông môn về đêm, ánh trăng lạnh, không khí u ám căng thẳng |
| `night_sky.png` | Bầu trời đêm đầy sao trên dãy núi, sương mờ, tĩnh lặng rợn người |
| `sunrise_mountain.png` | Bình minh vàng cam rọi lên biển mây và đỉnh núi tiên, hy vọng, hùng vĩ |
| `town.png` | Phố cổ trang Trung Hoa nhộn nhịp dưới chân núi, mái ngói, đèn lồng |
| `forest.png` | Rừng trúc/rừng cổ thụ linh khí, ánh sáng xuyên tán lá, hơi huyền bí |
| `arena.png` | Đài tỉ thí đá giữa quảng trường tông môn, khán đài, khí thế |
| `demonic_altar.png` | Tế đàn ma giáo, vòng tròn máu phát sáng đỏ, không khí tà ác, khói đỏ |

## Nhân vật (`game/assets/char/<id>.png`, nền trong suốt)

| File | Mô tả prompt |
|---|---|
| `diep_tran.png` | Nam chính Diệp Trần: thanh niên tuấn tú, áo bào tu tiên xanh lam, khí chất điềm tĩnh kiên định, ánh kiếm khí mờ |
| `su_phu.png` | Vân Lão: lão sư tóc bạc, áo nâu vàng giản dị, hiền từ, phong thái cao nhân |
| `lam_uyen.png` | Lâm Uyển: thiếu nữ áo hồng/trắng, khí chất băng giá thanh lạnh, linh khí băng tuyết quanh người |
| `trieu_phong.png` | Triệu Phong: thiếu niên cương nghị, áo cam/nâu, vạm vỡ, ánh mắt gan dạ |
| `bach_truong.png` | Trưởng lão Bách: trung niên kiêu ngạo, áo lục đậm phái kiếm, tay cầm trường kiếm |
| `ma_ton.png` | Huyết Ma Tôn: phản diện, áo bào đỏ đen, khí tức tà ma, mắt đỏ, hắc khí cuộn quanh |

> **Mẹo:** có thể tạo thêm biểu cảm như `lam_uyen_angry.png`, `diep_tran_smile.png`.
> Engine hỗ trợ `{"show":"lam_uyen","expr":"angry"}` và tự fallback về sprite gốc
> nếu file biểu cảm chưa có.

## Nhạc & SFX (`game/assets/music/<tên>.{ogg|wav}`)
Hiện là tone placeholder. Thay bằng nhạc thật (ưu tiên `.ogg` để nhẹ):
`theme_title`, `theme_calm`, `theme_tense`, `theme_battle`, `theme_sad`,
`theme_victory`, và SFX `boom`, `clash`, `chime`.
Phong cách: nhạc cổ trang Trung Hoa (đàn cổ tranh, sáo trúc, trống trận cho cảnh chiến).
