import QtQuick
import ".."

Rectangle {
    id: glassRect
    color: "transparent"
    radius: Theme.radiusMD

    // 毛玻璃背景层
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.glassTint
        opacity: Theme.glassOpacity
    }

    // 噪点纹理模拟亚克力效果
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        opacity: 0.03

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                for (var i = 0; i < 500; i++) {
                    var x = Math.random() * width
                    var y = Math.random() * height
                    var alpha = Math.random() * 0.15
                    ctx.fillStyle = Theme.isDark
                        ? "rgba(255,255,255," + alpha + ")"
                        : "rgba(0,0,0," + alpha + ")"
                    ctx.fillRect(x, y, 1, 1)
                }
            }
        }
    }

    // 边框发光
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: Theme.glassBorder
        border.width: 1
    }
}
