import 'dart:ui' as ui show Rect, Size, Offset;
import 'dart:math' as math show max;

import 'package:flutter/painting.dart' as painting show TextPainter;
//import 'package:flutter/widgets.dart' as widgets show TextPainter;

import 'elements_painters.dart';
import 'chart_options.dart';

/// todo 0 document
///
/// Master auto-layout of chart in the independent (X) axis direction,
/// using the number of independent values.
///
/// Number of independent (X) values is assumed to be the same as number of
/// xLabels, so that value can be used interchangeably.
///
/// Note:
///   - As a byproduct this lays out the X labels in their container. todo 1 generalize
///   - Layouters may use Painters, for example for text (`TextSpan`),
///     for which we do not know any sizing needed for the Layouters,
///     until we call `TextPainter(text: textSpan).layout()`.
///   - [availableWidth], [xLabels], [chartOptions] is passed as arguments
///   - [xLabelsContainerHeight], [gridStepWidth] is calculated
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

class XLayouter {

  // ### input values

  List<String> _xLabels;
  double _availableWidth;
  double _spacing;
  ChartOptions _chartOptions;

  // ### calculated values

  /// Results of laying out the x axis labels, usabel by clients.
  List<XLayouterOutput> outputs = new List();

  double xLabelsContainerHeight;
  double gridStepWidth;

  /// todo 0 document
  XLayouter({
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

    double labelXOffset = 0.0; // left point

    var seq = new Iterable.generate(_xLabels.length, (i) => i); // 0 .. length-1

    for ( var xIndex in seq ) {
      double leftX = labelXOffset + gridStepWidth * xIndex;
      var output = new XLayouterOutput();
      // textPainterForLabel calls [TextPainter.layout]
      output.painter = new LabelPainter().textPainterForLabel(_xLabels[xIndex]);
      output.xGridCoord = leftX + output.painter.width / 2;
      outputs.add(output);
    }

    xLabelsContainerHeight =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter p) => p.size.height)
            .reduce(math.max);
  }

}

/// A Wrapper of [XLayouter] members that can be used by clients
/// to layout x labels container.

/// All positions are relative to the left of the container of x labels
class XLayouterOutput {

  /// Painter configured to paint one label
  painting.TextPainter painter;

  ///  x offset of label middle point.
  ///
  ///  Also is the x offset of point that should
  /// show a dash for the label center on x axis.
  double xGridCoord;

  /// The offset of labels top/left corner,
  /// which puts the label centered around the grid points.
  /// double xOffsetToCenter;
}
