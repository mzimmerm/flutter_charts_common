import 'package:flutter/widgets.dart' as widgets show TextPainter;
import 'package:flutter/painting.dart' as painting
    show TextStyle, TextSpan, TextPainter;
import 'package:flutter/material.dart' as material show Colors;
import 'dart:ui' as ui;


/// todo 1 document
/// Provides classes and methods that paint individual elements
/// of the chart: Labels, Axis, Titles.
///
class LabelPainter {

  ///  For the passed string , obtains a TextPainter that can be used
  ///  both for measuring and drawing.
  ///
  /// For the measured values to correspond the drawn sizes,
  /// all size related styling is included.
  ///
  /// Returns a layed-out `textPainter` instance of [TextPainter], which can
  /// paint itself on `canvas`, with top-left position at `offset`,
  /// using `textPainter.paint(canvas, offset)`.
  widgets.TextPainter textPainterForLabel(String string) {
    var text =
    new painting
        .TextSpan( // also { List<TextSpan> children,GestureRecognizer recognizer }
        text: string,
        style:
        new painting.TextStyle( // also
            color: material.Colors.grey[600],
            fontSize: 14.0)); // todo 2 remove hardcoded fontSize and textScaleFactor below.
    var textPainter =
    new painting.TextPainter( // also {int maxLines, String ellipsis} );
        text: text,
        textAlign: ui.TextAlign.left,
        textScaleFactor: 1.0); //  textScaleFactor does nothing ??

    textPainter
        .layout(); // (minWidth:0.0, maxWidth:double.INFINITY) or  minWidth:100.0, maxWidth: 300.0

    return textPainter;
  }
}