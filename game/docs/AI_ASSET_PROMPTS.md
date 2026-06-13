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
| `valley.png` | Vân Hà Cốc: sơn cốc nhỏ thanh bình, suối, ghế trúc, mây trắng vắt ngang, nơi cao nhân ẩn cư |
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
| `co_huyen.png` | Sư Tôn Cơ Huyền: nam nhân điềm đạm lười nhác nhưng khí chất thâm bất khả trắc, áo bào xanh lam giản dị, tay cầm chén trà, ánh mắt sâu thẳm giấu cả thiên địa |
| `lang_thien.png` | Đại đệ tử Lăng Thiên: thiếu niên kiếm tu ngông nghênh nhiệt huyết, áo cam/nâu, ôm trường kiếm, kiếm khí trắng xóa |
| `to_tuyet.png` | Nhị đệ tử Tô Tuyết: thiếu nữ Huyền Âm Băng Thể, áo trắng xanh, khí chất băng giá thanh lạnh, tuyết bay quanh người |
| `linh_nhi.png` | Tiểu đệ tử Linh Nhi: bé gái ~8 tuổi đáng yêu, Vạn Linh Chi Tâm, áo hồng, ôm thỏ tuyết, vạn vật linh thú vây quanh |
| `bach_truong.png` | Trưởng lão Bách (Huyền Thiên Tông): trung niên kiêu ngạo, áo lục đậm phái kiếm, tay cầm trường kiếm |
| `ma_ton.png` | Huyết Ma Lão Tổ: phản diện, áo bào đỏ đen, khí tức tà ma, mắt đỏ, huyết khí cuộn quanh |

> **Mẹo:** có thể tạo thêm biểu cảm như `lang_thien_angry.png`, `co_huyen_smile.png`.
> Engine hỗ trợ `{"show":"to_tuyet","expr":"angry"}` và tự fallback về sprite gốc
> nếu file biểu cảm chưa có.

## Nhạc & SFX (`game/assets/music/<tên>.{ogg|wav}`)
Hiện là tone placeholder. Thay bằng nhạc thật (ưu tiên `.ogg` để nhẹ):
`theme_title`, `theme_calm`, `theme_tense`, `theme_battle`, `theme_sad`,
`theme_victory`, và SFX `boom`, `clash`, `chime`.
Phong cách: nhạc cổ trang Trung Hoa (đàn cổ tranh, sáo trúc, trống trận cho cảnh chiến).
