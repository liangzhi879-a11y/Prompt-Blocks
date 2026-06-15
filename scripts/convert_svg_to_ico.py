"""将 PB-logo.svg 转换为多尺寸 ICO 图标文件（使用 PySide6 QtSvg 渲染）。

SVG 基于 #0E3A5C (深蓝) 和 #F9F9F9 (白) 双色设计。
生成 16x16, 32x32, 48x48, 64x64, 128x128, 256x256 六个尺寸。
"""

from pathlib import Path
from PIL import Image
import io

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SVG_PATH = PROJECT_ROOT / "logo-design" / "PB-logo.svg"
OUTPUT_PATH = PROJECT_ROOT / "src" / "promptblocks" / "resources" / "icons" / "app.ico"

SIZES = [16, 32, 48, 64, 128, 256]


def svg_to_ico_qt(svg_path: Path, ico_path: Path, sizes: list[int]) -> None:
    """使用 PySide6 QtSvg 将 SVG 渲染为多尺寸 ICO。"""
    from PySide6.QtCore import QByteArray, Qt, QSize
    from PySide6.QtGui import QImage, QPainter
    from PySide6.QtSvg import QSvgRenderer

    svg_bytes = svg_path.read_bytes()
    renderer = QSvgRenderer(QByteArray(svg_bytes))

    images = []
    for size in sizes:
        img = QImage(QSize(size, size), QImage.Format_ARGB32)
        img.fill(Qt.transparent)
        painter = QPainter(img)
        painter.setRenderHint(QPainter.Antialiasing)
        painter.setRenderHint(QPainter.SmoothPixmapTransform)
        renderer.render(painter)
        painter.end()

        # 转换为 Pillow Image
        ptr = img.bits()
        if ptr is not None:
            pil_img = Image.frombuffer(
                "RGBA", (size, size), ptr, "raw", "BGRA", 0, 1
            )
            images.append(pil_img.copy())
        else:
            print(f"警告: 尺寸 {size}x{size} 像素数据为空")

    ico_path.parent.mkdir(parents=True, exist_ok=True)
    images[0].save(
        str(ico_path),
        format="ICO",
        sizes=[(sz, sz) for sz in sizes],
        append_images=images[1:],
    )
    print(f"ICO 已生成: {ico_path}  (尺寸: {', '.join(str(s) for s in sizes)})")


if __name__ == "__main__":
    from PySide6.QtWidgets import QApplication
    app = QApplication([])
    svg_to_ico_qt(SVG_PATH, OUTPUT_PATH, SIZES)
    app.quit()
    print("转换完成！")
