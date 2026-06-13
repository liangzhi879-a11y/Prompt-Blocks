import QtQuick
import ".."

Rectangle {
    id: tokenCounterRoot

    property string text: ""
    property string modelName: "gpt-4"
    property int totalApiTokens: 0
    property real totalApiCost: 0

    height: Theme.heightXS
    color: Theme.surfaceVariant
    radius: Theme.radiusSM

    readonly property int estimatedTokens: {
        if (!text || text.length === 0) return 0
        var chineseChars = 0
        var otherChars = 0
        for (var i = 0; i < text.length; i++) {
            var code = text.charCodeAt(i)
            if (code >= 0x4E00 && code <= 0x9FFF) {
                chineseChars++
            } else if (code > 32) {
                otherChars++
            }
        }
        return Math.ceil(chineseChars / 2) + Math.ceil(otherChars / 4)
    }

    Row {
        anchors.centerIn: parent
        spacing: Theme.spacingSM

        Text {
            text: Icons.chart
            font.pixelSize: Theme.fontSM
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: qsTr("约 %1 tokens").arg(tokenCounterRoot.estimatedTokens)
            color: Theme.onSurfaceVariant
            font.pixelSize: Theme.fontSM
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1
            height: 14
            color: Theme.divider
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: qsTr("累计 %1 tokens ($%2)").arg(tokenCounterRoot.totalApiTokens).arg(tokenCounterRoot.totalApiCost.toFixed(4))
            color: Theme.onSurfaceVariant
            font.pixelSize: Theme.fontSM
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
