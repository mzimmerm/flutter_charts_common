import 'dart:ui' as ui show Rect, Size, Offset;
import 'dart:math' as math show max, min;

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

  ChartOptions _options;
  ChartData _data;

  YLayouter yLayouter; // todo 00 make private - all manipulation through YLayouterOutput
  XLayouter xLayouter;

  /// [xOutputs] and [yOutputs] hold on the X and Y Layouters output,
  /// maintain all points in absolute positions
  /// - positioned to full chart size, as provided by layout governing
  /// chart's painter (in which this layouter is used).
  List<XLayouterOutput> xOutputs = new List();
  List<YLayouterOutput> yOutputs = new List();

  List<double> gridXCoords = new List();
  List<double> gridYCoords = new List();

  List<double> labelXCoords = new List();
  List<double> labelYCoords = new List();

  /// XLayouter's grid cannot start on the left (x=0) of the available chart area,
  /// it has to start at least a width of Y label left from the left.
  ///
  /// This member represents the forced minimum offset from the left
  /// of the chart area, to the left of the grid.
  double _xLayouterMinOffsetLeft;

  /// XLayouter's grid cannot start on the top (y=0) of the available chart area,
  /// it has to start at least half height of Y label down from the top.
  ///
  /// This member represents the forced minimum offset from top of the chart area,
  /// to the top of the grid.
  double _xLayouterMinOffsetTop;


  /// Simple Layouter for a simple flutter chart.
  ///
  /// The simple flutter chart layout consists of only 2 major areas:
  ///   - [YLayouter] area manages and lays out the Y labels area, by calculating
  ///     sizes required for Y labels (in both X and Y direction).
  ///     The [YLayouter]
  ///   - [XLayouter] area manages and lays out the
  ///     - X labels area, and the
  ///     - grid area.
  ///     In the X direction, takes up all space left after the
  ///     YLayouter layes out the  Y labels area, that is, full width
  ///     minus [YLayouter.yLabelsContainerWidth].
  ///     In the Y direction, takes
  ///     up all available chart area, except a top horizontal strip,
  ///     required to paint half of the topmost label.
  SimpleChartLayouter({
    ui.Size chartArea,
    ChartData chartData,
    ChartOptions chartOptions
  }) {
    _data = chartData;
    _options = chartOptions;

    var yLayouter = new YLayouter(
      chartLayouter: this,
      availableHeight: chartArea.height,
    );

    yLayouter.layout();
    _xLayouterMinOffsetLeft =
        yLayouter._yLabelsContainerWidth;
    _xLayouterMinOffsetTop = yLayouter._yLabelsMaxHeight / 2;
    this.yLayouter = yLayouter;

    var xLayouter = new XLayouter(
        chartLayouter: this,
        yLayouter: yLayouter,
        // todo 1 add padding, from options
        availableWidth: chartArea.width - xLayouterOffsetLeft
    );

    xLayouter.layout();
    this.xLayouter = xLayouter;

    xOutputs = xLayouter.outputs.map((var output) {
      var xOutput = new XLayouterOutput();
      xOutput.painter = output.painter;
      xOutput.gridXCoord = xLayouterOffsetLeft + output.gridXCoord;
      xOutput.labelXCoord = xLayouterOffsetLeft + output.labelXCoord;
      return xOutput;
    }).toList();

    yOutputs = yLayouter.outputs.map((var output) {
      var yOutput = new YLayouterOutput();
      yOutput.painter = output.painter;
      yOutput.gridYCoord = output.gridYCoord;
      yOutput.labelYCoord = output.gridYCoord;
      return yOutput;
    }).toList();

    gridXCoords = xOutputs.map((var output) => output.gridXCoord).toList();

    gridYCoords = yOutputs.map((var output) => output.gridYCoord).toList();

    labelXCoords = xOutputs.map((var output) => output.labelXCoord).toList();

    labelYCoords = yOutputs.map((var output) => output.labelYCoord).toList();
  }

  double get xLayouterOffsetTop =>
      math.max(_xLayouterMinOffsetTop, _options.xTopTicksHeight);

  double get xLayouterOffsetLeft => _xLayouterMinOffsetLeft;

  double get yRightTicksWidth =>
      math.max(_options.yRightTicksWidth, xLayouter._gridStepWidth / 2);

  double get gridVerticalLinesFromY => xLayouterOffsetTop;

  double get gridVerticalLinesToY =>
      gridYCoords.reduce(math.max) + _options.xBottomTicksHeight;

  double get gridHorizontalLinesFromX => xLayouterOffsetLeft;

  double get gridHorizontalLinesToX =>
      gridXCoords.reduce(math.max) + yRightTicksWidth;

  double get xLabelsContainerHeight => xLayouter._xLabelsContainerHeight;

  double get xLabelsContainerWidth => xLayouter._xLabelsContainerWidth;

  double get yLabelsContainerHeight => yLayouter._yLabelsContainerHeight;

  double get yLabelsContainerWidth => yLayouter._yLabelsContainerWidth;
}

/// Auto-layouter of the area containing Y axis.
///
/// Out of all calls to layouter's [layout] by parent layouter,
/// the call to this object's [layout] is first, thus
/// providing remaining available space for grid and x labels.
class YLayouter {

  /// The containing layouter.
  SimpleChartLayouter _chartLayouter;

  // ### input values

  List<String> _yLabels;
  double _availableHeight;

  // ### calculated values

  /// Results of laying out the y axis labels, usabel by clients.
  List<YLayouterOutput> outputs = new List();

  double _yLabelsContainerHeight;
  double _yLabelsContainerWidth;
  double _yLabelsMaxHeight;
  double _gridStepHeight;

  /// Constructor gives this layouter access to it's
  /// layouting parent [chartLayouter], giving it [availableHeight],
  /// which is (likely) the full chart area height available to the chart.
  ///
  /// This layouter uses the full [availableHeight], and takes as
  /// much width as needed for Y labels to be painted.
  ///
  YLayouter({
    SimpleChartLayouter chartLayouter,
    double availableHeight,
  }) {
    _chartLayouter = chartLayouter;
    _availableHeight = availableHeight;
    _yLabels = _generateYLabels();
  }

  /// Number of horizontal lines on grid.
  ///
  /// Bottom line will be drawn at value of min(data), top line on max(data).
  /// todo 2 : calculate this from data, based on grid height and reasonable y points.
  int get numYGridLines => _chartLayouter._options.minNumYGridLines;

  /// todo -1-1 Generate Y labels from data. For now hardcoded
  List<String> _generateYLabels() {
    return [ "25%", "50%", "75%", "100%"];
  }

  /// Lays out the the area containing the Y axis.
  ///
  layout() {
    // Evenly divided available height to all labels.
    // Label height includes any spacing on each side.
    double labelFullHeight = _availableHeight / _yLabels.length;

    _gridStepHeight = labelFullHeight;

    var seq = new Iterable.generate(_yLabels.length, (i) => i); // 0 .. length-1

    for (var yIndex in seq) {
      double topY = _gridStepHeight * yIndex;
      var output = new YLayouterOutput();
      // textPainterForLabel calls [TextPainter.layout]
      output.painter = new LabelPainter(options: _chartLayouter._options)
          .textPainterForLabel(_yLabels[yIndex]);
      output.gridYCoord = topY + output.painter.height / 2;
      output.labelYCoord = topY;
      outputs.add(output);
    }

    _yLabelsContainerWidth =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter painter) => painter.size.width)
            .reduce(math.max) + 2 * _chartLayouter._options
            .yLabelsPadLR; // todo 0 the yLabelsPadLR must be used 1) in y labels print 2) add to dots calcs(?)

    /// difference between top of first label and bottom of last todo 1 unreliable long term
    _yLabelsContainerHeight =
        outputs.map((var output) => output.labelYCoord).reduce(math.max) -
            outputs.map((var output) => output.labelYCoord).reduce(math.min) +
            outputs.map((var output) => output.painter)
                .map((painting.TextPainter painter) => painter.size.height)
                .reduce(math.max);

    _yLabelsMaxHeight =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter painter) => painter.size.height)
            .reduce(math.max);
  }

/* todo 00 try to convert above to common code
  double _paintersMaxSize((painting.TextPainter p) => double dimFunc(p)) {
    return  outputs.map((var output) => output.painter)
            .map(dimFunc)
            .reduce(math.max);
  }
*/


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
  double gridYCoord;

  ///  y offset of label left point (drawing y labels).
  double labelYCoord;
}

/// todo 0 document
///
/// Auto-layouter of chart in the independent (X) axis direction.
///
/// Number of independent (X) values (length of each data row)
/// is assumed to be the same as number of
/// xLabels, so that value can be used interchangeably.
///
/// Note:
///   - As a byproduct this lays out the X labels in their container. todo 1 generalize
///   - Layouters may use Painters, for example for text (`TextSpan`),
///     for which we do not know any sizing needed for the Layouters,
///     until we call `TextPainter(text: textSpan).layout()`.
///   - [availableWidth], [xLabels], [options] is passed as arguments
///   - [xLabelsContainerHeight], [_gridStepWidth] is calculated
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

class XLayouter {

  /// The containing layouter.
  SimpleChartLayouter _chartLayouter;

  // ### input values

  YLayouter _yLayouter;
  List<String> _xLabels;
  double _availableWidth;

  // ### calculated values

  /// Results of laying out the x axis labels, usabel by clients.
  List<XLayouterOutput> outputs = new List();

  double _xLabelsContainerWidth; // todo 00 unused
  double _xLabelsContainerHeight;
  double _gridStepWidth;

  /// Constructor gives this layouter access to it's
  /// layouting parent [chartLayouter], giving it [availableWidth],
  /// which is (likely) the remainder of width after [YLayouter]
  /// has taken whichever width it needs.
  ///
  /// This layouter uses the full [availableWidth], and takes as
  /// much height as needed for X labels to be painted.
  ///
  XLayouter({
    SimpleChartLayouter chartLayouter,
    YLayouter yLayouter,
    double availableWidth,
  }) {
    _chartLayouter = chartLayouter;
    _yLayouter = yLayouter;
    _xLabels = _chartLayouter._data.xLabels;
    _availableWidth = availableWidth;
  }

  /// Lays out the todo 0 document

  /// Evenly divids available width to all labels.
  /// First / Last vertical line is at the center of first / last label,
  ///
  /// Label width includes spacing on each side.
  layout() {
    double labelFullWidth = _availableWidth / _xLabels.length;

    _gridStepWidth = labelFullWidth;

    var seq = new Iterable.generate(_xLabels.length, (i) => i); // 0 .. length-1

    for (var xIndex in seq) {
      // double leftX = _gridStepWidth * xIndex;
      var output = new XLayouterOutput();
      output.painter = new LabelPainter(options: _chartLayouter._options)
          .textPainterForLabel(_xLabels[xIndex]);
      output.gridXCoord = (_gridStepWidth / 2) + _gridStepWidth * xIndex;
      output.labelXCoord = output.gridXCoord - output.painter.width / 2;
      outputs.add(output);
    }

    _xLabelsContainerWidth =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter painter) => painter.size.width)
            .reduce((a, b) => a + b);

    _xLabelsContainerHeight =
        outputs.map((var output) => output.painter)
            .map((painting.TextPainter painter) => painter.size.height)
            .reduce(math.max);
  }

}

/// A Wrapper of [XLayouter] members that can be used by clients
/// to layout x labels container.

/// All positions are relative to the left of the container of x labels
class XLayouterOutput {

  /// Painter configured to paint one label
  painting.TextPainter painter;

  ///  x offset of label middle point (see draw x labels).
  ///
  /// Also is the x offset of point that should
  /// show a "tick dash" for the label center on x axis (unused).
  ///
  /// Also is the x offset of vertical grid lines. (see draw grid)
  ///
  /// First "tick dash" is on the first label, last on the last label.
  double gridXCoord;

  ///  x offset of label left point (see draw x labels).
  double labelXCoord;

}
