import 'dart:ui' as ui show Rect, Size, Offset;
import 'dart:math' as math show max;

import 'package:flutter/painting.dart' as painting show TextPainter;
//import 'package:flutter/widgets.dart' as widgets show TextPainter;

import 'elements_painters.dart';
import 'chart_options.dart';
import 'chart_data.dart';


/// Layouters calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// Creates a simple chart layouter and call all needed [layout] methods.

class SimpleChartLayouter {

  YLayouter yLayouter;
  XLayouter xLayouter;

  SimpleChartLayouter({
    ui.Size   chartArea,
    ChartData data,
    ChartOptions, options
  }) {
    var yLayouter = new YLayouter(
      chartData: data,
      outsideYOffset:  0.0,
      availableHeight: chartArea.height,
      chartOptions: options,);

    yLayouter.layout();
    this.yLayouter = yLayouter;

    var xLayouter = new XLayouter(
      yLayouter: yLayouter,
      chartData: data,
      outsideXOffset:  yLayouter.yLabelsContainerWidth, // todo -1-1 add padding, from settings
      availableWidth: chartArea.width - yLayouter.yLabelsContainerWidth,
      minOutsideYOffset: 0.0, // todo -2-2,
      chartOptions: options,);

    xLayouter.layout();
    this.xLayouter = xLayouter;
  }
}

class YLayouter {

  // ### input values

  List<String> _yLabels;
  double _outsideYOffset;
  double _availableHeight;
  double _spacing;
  ChartOptions _options;
  ChartData _data;

  // ### calculated values

  /// Results of laying out the y axis labels, usabel by clients.
  List<YLayouterOutput> outputs = new List();

  double yLabelsContainerHeight;
  double yLabelsContainerWidth;
  double gridStepHeight;

  /// todo 0 document
  YLayouter({
    ChartData chartData,
    double outsideYOffset,
    double availableHeight,
    ChartOptions chartOptions,
  }) {
    _data = chartData;
    _outsideYOffset = outsideYOffset;
    _availableHeight = availableHeight;
    _options = chartOptions;
    _spacing = chartOptions.yLabelsPadLR; // todo 00
    _yLabels = _generateYLabels();
  }

  /// Number of horizontal lines on grid.
  ///
  /// Bottom line will be drawn at value of min(data), top line on max(data).
  /// todo - 2 : calculate this from data, based on grid height and reasonable y points.
  int get numYGridLines => _options.minNumYGridLines;

  /// todo -1-1 Generate Y labels from data. For now hardcoded
  List<String> _generateYLabels() {
    return [ "25%", "50%", "75%", "100%"];
  }

  /// Lays out the todo 0 document

  layout() {
    // Evenly divided available height to all labels.
    // Label height includes any spacing on each side.
    double labelFullHeight = _availableHeight / _yLabels.length;

    gridStepHeight = labelFullHeight;

    double labelYOffset = 0.0; // top point

    var seq = new Iterable.generate(_yLabels.length, (i) => i); // 0 .. length-1

    for ( var yIndex in seq ) {
      double topY = labelYOffset + gridStepHeight * yIndex;
      var output = new YLayouterOutput();
      // textPainterForLabel calls [TextPainter.layout]
      output.painter = new LabelPainter().textPainterForLabel(_yLabels[yIndex]);
      output.yGridCoord = topY + output.painter.height / 2;
      outputs.add(output);
    }

    yLabelsContainerWidth =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter p) => p.size.width)
            .reduce(math.max);

    yLabelsContainerHeight =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter p) => p.size.height)
            .reduce(math.max);

  }
/* todo 00
  double _paintersMaxSize((painting.TextPainter p) => double dimFunc(p)) {
    return  outputs.map((var output) => output.painter)
            .map(dimFunc)
            .reduce(math.max);
  }
*/

  List<double> gridYCoords () {
    return outputs
        .map((var output) => output.yGridCoord  + _outsideYOffset)
        .toList();
  }

}


/// A Wrapper of [YLayouter] members that can be used by clients
/// to layout y labels container.

/// All positions are relative to the top of the container of y labels
class YLayouterOutput {

  /// Painter configured to paint one label
  painting.TextPainter painter;

  ///  y offset of label middle point.
  ///
  ///  Also is the y offset of point that should
  /// show a "tick dash" for the label center on y axis.
  ///
  /// First "tick dash" is on the first label, last on the last label,
  /// but y labels can be skipped.
  double yGridCoord;
}

double outOfGridHeight({ChartOptions options, XLayouter xLayouter}) {
  return
    options.xTopTicksHeight +
        options.xLabelsPadTop +
        options.xBottomTicksHeight +
        xLayouter.xLabelsContainerHeight;
}

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
///   - [availableWidth], [xLabels], [options] is passed as arguments
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

  YLayouter _yLayouter;
  List<String> _xLabels;
  double _outsideXOffset;
  double _availableWidth;
  double _spacing;
  ChartOptions _options;
  ChartData _data;

  // ### calculated values

  /// Results of laying out the x axis labels, usabel by clients.
  List<XLayouterOutput> outputs = new List();

  double xLabelsContainerWidth;
  double xLabelsContainerHeight;
  double gridStepWidth;

  /// todo 0 document
  XLayouter({
    YLayouter yLayouter,
    ChartData chartData,
    double outsideXOffset,
    double availableWidth,
    double minOutsideYOffset,
    ChartOptions chartOptions,
  }) {
    _yLayouter = yLayouter;
    _xLabels = chartData.xLabels;
    _data = chartData;
    _outsideXOffset = outsideXOffset;
    _availableWidth = availableWidth;
    _options = chartOptions;
    _spacing = chartOptions.xLabelsPadLR;
  }

  /// Lays out the todo 0 document

  layout() {
    // Evenly divided available width to all labels.
    // Label width includes any spacing on each side.
    double labelFullWidth =
        (_availableWidth - (_options.yLeftTicksWidth +_options.yRightTicksWidth))
            /
            _xLabels.length ;

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

    xLabelsContainerWidth =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter p) => p.size.width)
            .reduce(math.max);

    xLabelsContainerHeight =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter p) => p.size.height)
            .reduce(math.max);
  }

  List<double> gridXCoords() =>
      outputs
          .map((var output) => output.xGridCoord + _outsideXOffset)
          .toList();
}

/// A Wrapper of [XLayouter] members that can be used by clients
/// to layout x labels container.

/// All positions are relative to the left of the container of x labels
class XLayouterOutput {

  /// Painter configured to paint one label
  painting.TextPainter painter;

  ///  x offset of label middle point.
  ///
  /// Also is the x offset of point that should
  /// show a "tick dash" for the label center on x axis.
  ///
  /// First "tick dash" is on the first label, last on the last label.
  double xGridCoord;

}
