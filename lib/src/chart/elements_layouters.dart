import 'dart:ui' as ui show Size, Offset;
import 'dart:math' as math show max, min;

import 'package:flutter/painting.dart' as painting show TextPainter;
//import 'package:flutter/widgets.dart' as widgets show TextPainter;

import 'elements_painters.dart';
import 'chart_options.dart';
import 'chart_data.dart';
import '../util/range.dart';
import '../util/util.dart';

/// Layouters calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// Creates a simple chart layouter and call all needed [layout] methods.

class SimpleChartLayouter {
  ChartOptions _options;
  ChartData _data;

  YLayouter
  yLayouter; // todo 00 make private - all manipulation through YLayouterOutput
  XLayouter xLayouter;

  double legendHY = 50.0;

  /// This layouter stores positions in the [GuidingPoints] instance,
  /// and uses its members as "guiding points" where it's child layouts should
  /// draw themselves.
  GuidingPoints _guidingPoints;

  /// [xOutputs] and [yOutputs] hold on the X and Y Layouters output,
  /// maintain all points in absolute positions
  /// - positioned to full chart size, as provided by layout governing
  /// chart's painter (in which this layouter is used).
  List<XLayouterOutput> xOutputs = new List();
  List<YLayouterOutput> yOutputs = new List();
  LabelScalerFormatter yScaler;

  List<double> vertGridLineXs = new List();
  List<double> horizGridLineYs = new List();

  /* todo -1 remove
  List<double> labelXs = new List();
  List<double> labelYs = new List();
*/

  /// XLayouter's grid cannot start on the left (x=0) of the available chart area,
  /// it has to start at least a width of Y label left from the left.
  ///
  /// This member represents the forced minimum offset from the left
  /// of the chart area, to the left of the grid.
  double _yToXLayouterMinLeftGap;

  /// XLayouter's grid cannot start on the top (y=0) of the available chart area,
  /// it has to start at least half height of Y label down from the top.
  ///
  /// This member represents the forced minimum offset from top of the chart area,
  /// to the top of the grid, within this parent layouter.
  double _yToXLayouterMinTopGap;

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
  SimpleChartLayouter(
      {ui.Size chartArea, ChartData chartData, ChartOptions chartOptions}) {
    _data = chartData;
    _options = chartOptions;

    // ### 1. First call to YLayouter provides how much width is left for XLayouter (grid and X axis)
    var yLayouterFirst = new YLayouter(
        chartLayouter: this,
        availableHeight: chartArea.height,
        yAxisOffsetMinFromTop: 0.0,
        yAxisOffsetMinFromBottom: 0.0

    );

    print("   ### YLayouter #1: before layout: ${yLayouterFirst}");
    yLayouterFirst.layout();
    print("   ### YLayouter #1: after layout: ${yLayouterFirst}");
    _yToXLayouterMinLeftGap = yLayouterFirst._yLabelsContainerWidth;
    _yToXLayouterMinTopGap = yLayouterFirst._yLabelsMaxHeight / 2 + legendHY;
    this.yLayouter = yLayouterFirst;

    // ### 2. Knowing width required by YLayouter, we can layout X labels and grid.
    //        The available height is only marginally relevant (if there was
    //        not enough height for x labels.
    var xLayouter = new XLayouter(
        chartLayouter: this,
        // todo 1 add padding, from options
        availableWidth: chartArea.width - xLayouterOffsetFromLeft);

    print("   ### XLayouter");
    xLayouter.layout();
    this.xLayouter = xLayouter;

    xOutputs = xLayouter.outputs.map((var output) {
      var xOutput = new XLayouterOutput();
      xOutput.painter = output.painter;
      xOutput.vertGridLineX = xLayouterOffsetFromLeft + output.vertGridLineX;
      xOutput.labelX = xLayouterOffsetFromLeft + output.labelX;
      return xOutput;
    }).toList();

    // ### 3. Second call to YLayouter is needed, as available height for Y
    //        is only known after XLayouter provided height ov xLabels
    //        on the bottom (which is not available for Y height)
    // First call to YLayouter provides how much width is left for XLayouter (grid and X axis)

    var yLayouter = new YLayouter(
        chartLayouter: this,
        availableHeight: chartArea.height - xLayouter._xLabelsContainerHeight - legendHY,
        yAxisOffsetMinFromTop: xyLayoutersOffsetFromParentTop - legendHY, // todo -1 this should be additional offset from top of parent layouter
        yAxisOffsetMinFromBottom: 2 * _options.xLabelsPadTB + _options.xBottomMinTicksHeight
    );

    print("   ### YLayouter #2: before layout: ${yLayouter}");
    yLayouter.layout();
    print("   ### YLayouter #2: after layout: ${yLayouter}");

    this.yLayouter = yLayouter;

    // ### 4. Recalculate offsets for this parent layouter

    yOutputs = yLayouter.outputs.map((var output) {
      var yOutput = new YLayouterOutput();
      yOutput.painter = output.painter;
      yOutput.horizGridLineY = output.horizGridLineY;
      yOutput.labelY = output.labelY;
      return yOutput;
    }).toList();

    vertGridLineXs =
        xOutputs.map((var output) => output.vertGridLineX).toList();

    horizGridLineYs =
        yOutputs.map((var output) => output.horizGridLineY).toList();

    /* todo -1 remove
    // todo 00 how is this used?
    labelXs = xOutputs.map((var output) => output.labelX).toList();

    labelYs = yOutputs.map((var output) => output.labelY).toList();
    */
  }

  // todo -1 surely more vars can be removed
  double get xyLayoutersOffsetFromParentTop =>
      math.max(_yToXLayouterMinTopGap, _options.xTopMinTicksHeight);

  double get xLayouterOffsetFromLeft => _yToXLayouterMinLeftGap;

  double get yRightTicksWidth =>
      math.max(_options.yRightMinTicksWidth, xLayouter._gridStepWidth / 2);

  double get vertGridLinesFromY => xyLayoutersOffsetFromParentTop;

  double get vertGridLinesToY =>
      horizGridLineYs.reduce(math.max) + _options.xBottomMinTicksHeight;

  double get gridHorizontalLinesFromX => xLayouterOffsetFromLeft;

  double get gridHorizontalLinesToX =>
      vertGridLineXs.reduce(math.max) + yRightTicksWidth;

  double get yLabelsOffsetFromLeft => _options.yLabelsPadLR;

  double get xLabelsOffsetFromTop =>
      yLayouter._availableHeight + _options.xBottomMinTicksHeight;

  double get yLabelsMaxHeight => yLayouter._yLabelsMaxHeight;

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

  double _availableHeight;

  // ### calculated values

  /// Results of laying out the y axis labels, usabel by clients.
  List<YLayouterOutput> outputs = new List();

  double _yLabelsContainerWidth;
  double _yLabelsMaxHeight;
  double _yAxisOffsetMinFromTop;
  double _yAxisOffsetMinFromBottom;
  double _yAxisAvailableHeight;

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
    double yAxisOffsetMinFromTop,
    double yAxisOffsetMinFromBottom

  }) {
    _chartLayouter = chartLayouter;
    _availableHeight = availableHeight;

    _yAxisOffsetMinFromTop = yAxisOffsetMinFromTop;
    _yAxisOffsetMinFromBottom = yAxisOffsetMinFromBottom;
    _yAxisAvailableHeight =
        _availableHeight - _yAxisOffsetMinFromTop - _yAxisOffsetMinFromBottom;
  }

  /// Lays out the the area containing the Y axis.
  ///
  layout() {
    // the scale is given by (adjusted) available height, known at
    // construction time.
    double toScaleMin = _yAxisOffsetMinFromTop + _yAxisAvailableHeight + _chartLayouter.legendHY; // here we are subtracting legendY in both vars. so remove one
    double toScaleMax = _yAxisOffsetMinFromTop + _chartLayouter.legendHY;

    if (_chartLayouter._options.doManualLayoutUsingYLabels) {
      layoutManually(toScaleMin: toScaleMin, toScaleMax: toScaleMax);
    } else {
      layoutAutomatically(toScaleMin: toScaleMin, toScaleMax: toScaleMax);
    }
    _yLabelsContainerWidth = outputs
        .map((var output) => output.painter)
        .map((painting.TextPainter painter) => painter.size.width)
        .reduce(math.max) + 2 * _chartLayouter._options.yLabelsPadLR;

    _yLabelsMaxHeight = outputs
        .map((var output) => output.painter)
        .map((painting.TextPainter painter) => painter.size.height)
        .reduce(math.max);
  }

  /// Manually layout Y axis by evenly dividing available height to all Y labels.
  void layoutManually({double toScaleMin, double toScaleMax}) {

    List flatData = _chartLayouter._data.dataRows.expand((i) => i).toList();
    var dataRange = new Interval(
        flatData.reduce(math.min), flatData.reduce(math.max));

    List<num> yLabels = _chartLayouter._data.yLabels;

    Interval yAxisRange = new Interval(toScaleMin, toScaleMax);

    double gridStepHeight = (yAxisRange.max - yAxisRange.min) / (yLabels.length - 1);

    List<num> yLabelsDividedInYAxisRange = new List();
    var seq = new Iterable.generate(yLabels.length, (i) => i); // 0 .. length-1
    for (var yIndex in seq) {
      yLabelsDividedInYAxisRange.add(yAxisRange.min + gridStepHeight * yIndex );
    }

    var labelScaler = new LabelScalerFormatter(
        dataRange: dataRange,
        labeValues: yLabelsDividedInYAxisRange,
        toScaleMin: toScaleMin,
        toScaleMax: toScaleMax,
        chartOptions: _chartLayouter._options);

    labelScaler.setLabelValuesForManualLayout( labelValues: yLabels, scaledLabelValues: yLabelsDividedInYAxisRange);
    //labelScaler.scaleLabelInfos();
    labelScaler.makeLabelsPresentable();

    _commonLayout(labelScaler);
  }

  /// Generate labels from data, and auto layout
  /// Y axis according to data range, labels range, and display range
  void layoutAutomatically({double toScaleMin, double toScaleMax}) {

    List flatData = _chartLayouter._data.dataRows.expand((i) => i).toList();

    Range range = new Range(
        values: flatData, chartOptions: _chartLayouter._options, maxLabels: 10);

    // revert toScaleMin/Max to accomodate y axis starting from top
    LabelScalerFormatter labelScaler = range.makeLabelsFromDataOnScale(
        toScaleMin: toScaleMin,
        toScaleMax: toScaleMax
    );

    _commonLayout(labelScaler);
  }

  void _commonLayout(LabelScalerFormatter labelScaler) {
    // Retain this scaler to be accessible to client code,
    // e.g. for coordinates of value dots.
    _chartLayouter.yScaler = labelScaler;

    for (LabelInfo labelInfo in labelScaler.labelInfos) {
      double topY = labelInfo.scaledLabelValue;
      var output = new YLayouterOutput();
      // textPainterForLabel calls [TextPainter.layout]
      output.painter = new LabelPainter(options: _chartLayouter._options)
          .textPainterForLabel(labelInfo.formattedYLabel);
      output.horizGridLineY = topY;
      output.labelY = topY - output.painter.height / 2;
      outputs.add(output);
    }
  }

  String toString() {
    return
      ", _availableHeight = ${_availableHeight}" +
          ", _yLabelsContainerWidth = ${_yLabelsContainerWidth}" +
          ", _yLabelsMaxHeight = ${_yLabelsMaxHeight}" +
          ", _yAxisOffsetMinFromTop = ${_yAxisOffsetMinFromTop}" +
          ", _yAxisOffsetMinFromBottom = ${_yAxisOffsetMinFromBottom}" +
          ", _yAxisAvailableHeight = ${_yAxisAvailableHeight}"
    ;
  }
}


/// A Wrapper of [YLayouter] members that can be used by clients
/// to layout y labels container.

/// Generally, the owner of this object decides what the offsets are:
///   - If owner is YLayouter, all positions are relative to the top of
///     the container of y labels
///   - If owner is parent [SimpleChartLayouter], all positions are relative
///     to the top of the available [chartArea].
class YLayouterOutput {
  /// Painter configured to paint one label
  painting.TextPainter painter;

  ///  y offset of Y label middle point.
  ///
  ///  Also is the y offset of point that should
  /// show a "tick dash" for the label center on the y axis.
  ///
  /// First "tick dash" is on the first label, last on the last label,
  /// but y labels can be skipped.
  double horizGridLineY;

  ///  y offset of Y label left point.
  double labelY;
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

  List<String> _xLabels;
  double _availableWidth;

  // ### calculated values

  /// Results of laying out the x axis labels, usabel by clients.
  List<XLayouterOutput> outputs = new List();

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
      var xOutput = new XLayouterOutput();
      xOutput.painter = new LabelPainter(options: _chartLayouter._options)
          .textPainterForLabel(_xLabels[xIndex]);
      xOutput.vertGridLineX = (_gridStepWidth / 2) + _gridStepWidth * xIndex;
      xOutput.labelX = xOutput.vertGridLineX - xOutput.painter.width / 2;
      outputs.add(xOutput);
    }

    _xLabelsContainerHeight = outputs
        .map((var output) => output.painter)
        .map((painting.TextPainter painter) => painter.size.height)
        .reduce(math.max) + 2 * _chartLayouter._options.xLabelsPadTB;
  }
}

/// A Wrapper of [XLayouter] members that can be used by clients
/// to layout x labels container.

/// All positions are relative to the left of the container of x labels
class XLayouterOutput {
  /// Painter configured to paint one label
  painting.TextPainter painter;

  ///  x offset of X label middle point.
  ///
  /// Also is the x offset of point that should
  /// show a "tick dash" for the label center on the x axis (unused).
  ///
  /// Also is the x offset of vertical grid lines. (see draw grid)
  ///
  /// First "tick dash" is on the first label, last on the last label.
  double vertGridLineX;

  ///  x offset of X label left point .
  double labelX;
}

/// Structural "backplane" model for chart layout.
///
/// Maintains positions (offsets) of a minimum set of *significant points* in layout.
/// Significant points are those at which the main layouter will paint
/// it's layouter children, such as: top-left of the Y axis labels,
/// top-left of the X axis labels, top-left of the data grid and other points.
/// The significant points are scaled and positioned in
/// the coordinates of ChartPainter.
///
/// SimpleChartLayouter stores positions in this instance,
/// and use its members as "guiding points" where it's child layouts should
/// draw themselves.
class GuidingPoints {
  List<ui.Offset> yLabelPoints;
}

/// Stores both scaled and unscaled X and Y values resulting from data.
///
/// While [GuidingPoints] manages points where layouts should
/// draw themselves, this class manages data values that should be drawn.
class LayoutValues {
  /// Y values of grid (also centers of Y labels),
  /// on the data scale
  List<num> yUnscaledGridValues;

  /// Y values of grid (also centers of Y labels),
  /// scaled to the main layouter coordinates.
  List<num> yGridValues;
}
