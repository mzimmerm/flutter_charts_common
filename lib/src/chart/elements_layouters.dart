import 'dart:ui' as ui show Rect, Size, Offset;
import 'dart:math' as math show max;

import 'package:flutter/painting.dart' as painting show TextPainter;
//import 'package:flutter/widgets.dart' as widgets show TextPainter;

import 'elements_painters.dart';
import 'chart_options.dart';

/// todo 0 document
///
/// Layout X labels.
///
/// Note:
///   - Layouters may use Painters, for example for text (`TextSpan`),
///     for which we do not know any sizing needed for the Layouters,
///     until we call `TextPainter(text: textSpan).layout()`.
///   - [availableWidth], [xLabels], [chartOptions] is passed as arguments
///   - [xLabelsHeight], [gridStepWidth] is calculated
///   - depends on TextPainter
///     provided by LabelPainter.textPainterForLabel(String string)
///   - todo add iterations that allow layout size to be negotiated.
///     The above requires a parent layouter or similar object, that can ask
///     this object to recalculate
///     - skip labels to fit
///     - rotate labels to fit
///     - decrease font size to fit
///   - clients will typically make use of this object after [layout]
///     has been called on it
///
/// Assumes:
///   - Number of labels is the same as number of independent (X) axis points
///     for all values
///
///
///

class XLabelsLayouter {

  // ### input values

  List<String> _xLabels;
  double _availableWidth;
  double _spacing;
  ChartOptions _chartOptions;


  // ### calculated values

  /// Results of laying out the x axis labels, usabel by clients.
  List<XLabelLayouterOutput> outputs = new List();

  double xLabelsHeight;
  double gridStepWidth;

  /// todo 0 document
  XLabelsLayouter({
    List<String> xLabels,
    double availableWidth,
    ChartOptions chartOptions,
  }) {
    _xLabels = xLabels;
    _availableWidth = availableWidth;
    _chartOptions = chartOptions;
    _spacing = chartOptions.xLabelsPadLR;
  }

  /// Lays out the todo 0 document

  layout() {
    // Evenly divided available width to all labels.
    // Label width includes any spacing on each side.
    double labelFullWidth = _availableWidth / _xLabels.length;

    gridStepWidth = labelFullWidth;

    double midLabelXOffset = -1 * labelFullWidth / 2; // half label width left
    double labelXOffset = 0.0; // left point

    var seq = new Iterable.generate(_xLabels.length, (i) => i); // 0 .. length-1

    for ( var xIndex in seq ) {
      double midX = midLabelXOffset + gridStepWidth * xIndex;
      double leftX = labelXOffset + gridStepWidth * xIndex;
      var output = new XLabelLayouterOutput();
      // textPainterForLabel calls [TextPainter.layout]
      output.painter = new LabelPainter().textPainterForLabel(_xLabels[xIndex]);
      output.xMidOffset = midX;
      output.xOffset = leftX;
      output.xOffsetToCenter = leftX + output.painter.width / 2;
      outputs.add(output);
    }

    xLabelsHeight =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter p) => p.size.height)
            .reduce(math.max);
  }

}

/// A Wrapper of [XLabelsLayouter] members that can be iterated.

/// All positions are relative in the container of x labels
class XLabelLayouterOutput {

  /// Painter configured to paint one label
  painting.TextPainter painter;

  /// x offset of label left corner.
  double xOffset;

  ///  x offset of label middle point.
  ///
  ///  Also is the x offset of point that should
  /// show a dash for the label center on x axis.
  double xMidOffset;

  /// The offset of labels top/left corner,
  /// which puts the label centered around the grid points.
  double xOffsetToCenter;
}
