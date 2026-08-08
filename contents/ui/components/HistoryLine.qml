import QtQuick

Canvas {
    id: canvas

    property var values: []
    property color strokeColor: "#34d399"
    property real lineWidth: 1.6
    property int verticalPadding: 3

    onValuesChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
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

        ctx.beginPath();
        for (let i = 0; i < values.length; i++) {
            const x = step * i;
            const y = height - ((values[i] / maxValue) * (height - (verticalPadding * 2))) - verticalPadding;
            if (i === 0) {
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
