import QtQuick

Canvas {
    id: canvas

    property var values: []
    property color strokeColor: "#34d399"
    property color fillColor: Qt.rgba(strokeColor.r, strokeColor.g, strokeColor.b, 0.28)
    property real lineWidth: 1.5
    property int verticalPadding: 5

    onValuesChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        if (!values || values.length < 2) {
            return;
        }

        const maxValue = Math.max.apply(null, values.concat([1]));
        const step = width / Math.max(1, values.length - 1);

        function yAt(index) {
            return height - ((values[index] / maxValue) * (height - (verticalPadding * 2))) - verticalPadding;
        }

        ctx.beginPath();
        ctx.moveTo(0, height);
        ctx.lineTo(0, yAt(0));
        for (let i = 1; i < values.length; i++) {
            ctx.lineTo(step * i, yAt(i));
        }
        ctx.lineTo(step * (values.length - 1), height);
        ctx.closePath();
        ctx.fillStyle = fillColor;
        ctx.fill();

        ctx.beginPath();
        for (let j = 0; j < values.length; j++) {
            const x = step * j;
            const y = yAt(j);
            if (j === 0) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = lineWidth;
        ctx.stroke();
    }
}
