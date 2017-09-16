import 'dart:ui' as ui show Size, Offset, Rect, Paint;
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
///
/// Terms used:
///   - `absolute positions` refer to positions
///      "in the coordinates of the full chart area given to the
///      ChartPainter by the application.
///   -
class SimpleChartLayouter {
  ChartOptions _options;
  ChartData _data;

  LegendLayouter legendLayouter;
  YLayouter
      yLayouter; // todo 00 make private - all manipulation through YLayouterOutput
  XLayouter xLayouter;

  /// This layouter stores positions in the [GuidingPoints] instance,
  /// and uses its members as "guiding points" where it's child layouts should
  /// draw themselves.
  GuidingPoints _guidingPoints;

  /// [xOutputs] and [yOutputs] hold on the X and Y Layouters output,
  /// maintain all points in absolute positions.
  ///
  /// Initialized in case the corresponding layouter does not run
  /// (e.g. no X, Y axis, no legend)
  List<XLayouterOutput> xOutputs = new List();
  List<YLayouterOutput> yOutputs = new List();
  List<LegendLayouterOutput> legendOutputs = new List();
  LabelScalerFormatter yScaler; // todo -1 is this needed?

  List<double> vertGridLineXs = new List();
  List<double> horizGridLineYs = new List();

  // todo 0 document
  double _legendContainerHeight = 0.0;
  double _yLabelsContainerWidth;
  double _yLabelsMaxHeight;

  ui.Size _chartArea;

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
    _chartArea = chartArea;

    // ### 1. First layout the legends on top
    LegendLayouter legendLayouter = new LegendLayouter(
        chartLayouter: this, availableWidth: chartArea.width);
    legendLayouter.layout();
    _legendContainerHeight = legendLayouter._size.height;

    print(" _legendContainerHeight = ${_legendContainerHeight}");

    legendOutputs = legendLayouter.outputs.map((var output) {
      var legendOutput = new LegendLayouterOutput();
      legendOutput.labelPainter = output.labelPainter;
      legendOutput.indicatorPaint = output.indicatorPaint;
      legendOutput.indicatorRect = output.indicatorRect;
      legendOutput.labelOffset = output.labelOffset;
      return legendOutput;
    }).toList();

    // ### 2. M a first call to YLayouter - this provides how much width
    //        is left for the XLayouter (grid and X axis).
    //        The y axis absolute min and max is not relevant in this first call.


    var yLayouterFirst = new YLayouter(
      chartLayouter: this,
      yAxisAbsMin: chartArea.height - _legendContainerHeight,
      yAxisAbsMax: 0.0,
    );

    print("   ### YLayouter #1: before layout: ${yLayouterFirst}");
    yLayouterFirst.layout();
    print("   ### YLayouter #1: after layout: ${yLayouterFirst}");

    _yLabelsContainerWidth = yLayouterFirst._yLabelsContainerWidth;
    _yLabelsMaxHeight = yLayouterFirst._yLabelsMaxHeight;

    this.yLayouter = yLayouterFirst;

    // ### 2. Knowing width required by YLayouter, we can layout X labels and grid.
    //        The available height is only marginally relevant (if there was
    //        not enough height for x labels.
    var xLayouter = new XLayouter(
        chartLayouter: this,
        // todo 1 add padding, from options
        availableWidth: chartArea.width - xLayouterAbsX);

    print("   ### XLayouter");
    xLayouter.layout();
    this.xLayouter = xLayouter;

    xOutputs = xLayouter.outputs.map((var output) {
      var xOutput = new XLayouterOutput();
      xOutput.painter = output.painter;
      xOutput.vertGridLineX = xLayouterAbsX + output.vertGridLineX;
      xOutput.labelX = xLayouterAbsX + output.labelX;
      return xOutput;
    }).toList();

    // ### 3. Second call to YLayouter is needed, as available height for Y
    //        is only known after XLayouter provided height of xLabels
    //        on the bottom .
    //        The y axis absolute min and max are used to scale data values
    //        to the y axis.

    double yAxisAbsMin = chartArea.height -
        (_options.xBottomMinTicksHeight +
            xLayouter._xLabelsContainerHeight +
            2 * _options.xLabelsPadTB);
    double yAxisAbsMax = xyLayoutersAbsY;

    var yLayouter = new YLayouter(
      chartLayouter: this,
      yAxisAbsMin: yAxisAbsMin,
      yAxisAbsMax: yAxisAbsMax,
    );

    print("   ### YLayouter #2: before layout: ${yLayouter}");
    yLayouter.layout();
    print("   ### YLayouter #2: after layout: ${yLayouter}");

    this.yLayouter = yLayouter;

    // ### 4. Recalculate offsets for this Area layouter

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
  }

  // todo -1 surely more vars can be removed
  double get xyLayoutersAbsY => math.max(
      _yLabelsMaxHeight / 2 + _legendContainerHeight,
      _options.xTopMinTicksHeight);

  double get xLayouterAbsX => _yLabelsContainerWidth;

  double get yRightTicksWidth =>
      math.max(_options.yRightMinTicksWidth, xLayouter._gridStepWidth / 2);

  double get vertGridLinesFromY => xyLayoutersAbsY;

  double get vertGridLinesToY =>
      horizGridLineYs.reduce(math.max) + _options.xBottomMinTicksHeight;

  double get horizGridLinesFromX => xLayouterAbsX;

  double get horizGridLinesToX =>
      vertGridLineXs.reduce(math.max) + yRightTicksWidth;

  double get yLabelsAbsX => _options.yLabelsPadLR;

  double get xLabelsAbsY =>
      _chartArea.height -
      (xLayouter._xLabelsContainerHeight + _options.xLabelsPadTB);

  double get yLabelsMaxHeight => yLayouter._yLabelsMaxHeight;
}

/// Auto-layouter of the area containing Y axis.
///
/// Out of all calls to layouter's [layout] by Area layouter,
/// the call to this object's [layout] is first, thus
/// providing remaining available space for grid and x labels.
class YLayouter {
  /// The containing layouter.
  SimpleChartLayouter _chartLayouter;

  // ### input values

  // ### calculated values

  /// Results of laying out the y axis labels, usabel by clients.
  List<YLayouterOutput> outputs = new List();

  double _yLabelsContainerWidth;
  double _yLabelsMaxHeight;

  double _yAxisAbsMin;
  double _yAxisAbsMax;

  /// Constructor gives this layouter access to it's
  /// layouting Area [chartLayouter], giving it [availableHeight],
  /// which is (likely) the full chart area height available to the chart.
  ///
  /// This layouter uses the full [availableHeight], and takes as
  /// much width as needed for Y labels to be painted.
  ///
  YLayouter({
    SimpleChartLayouter chartLayouter,
    double yAxisAbsMin,
    double yAxisAbsMax,
  }) {
    _chartLayouter = chartLayouter;
    _yAxisAbsMin = yAxisAbsMin;
    _yAxisAbsMax = yAxisAbsMax;
  }

  /// Lays out the the area containing the Y axis.
  ///
  layout() {
    if (_chartLayouter._options.doManualLayoutUsingYLabels) {
      layoutManually();
    } else {
      layoutAutomatically();
    }
    _yLabelsContainerWidth = outputs
            .map((var output) => output.painter)
            .map((painting.TextPainter painter) => painter.size.width)
            .reduce(math.max) +
        2 * _chartLayouter._options.yLabelsPadLR;

    _yLabelsMaxHeight = outputs
        .map((var output) => output.painter)
        .map((painting.TextPainter painter) => painter.size.height)
        .reduce(math.max);
  }

  /// Manually layout Y axis by evenly dividing available height to all Y labels.
  void layoutManually() {
    List flatData = _chartLayouter._data.dataRows.expand((i) => i).toList();
    var dataRange =
        new Interval(flatData.reduce(math.min), flatData.reduce(math.max));

    List<String> yLabels = _chartLayouter._data.yLabels;

    Interval yAxisRange = new Interval(_yAxisAbsMin, _yAxisAbsMax);

    double gridStepHeight =
        (yAxisRange.max - yAxisRange.min) / (yLabels.length - 1);

    List<num> yLabelsDividedInYAxisRange = new List();
    var seq = new Iterable.generate(yLabels.length, (i) => i); // 0 .. length-1
    for (var yIndex in seq) {
      yLabelsDividedInYAxisRange.add(yAxisRange.min + gridStepHeight * yIndex);
    }

    var labelScaler = new LabelScalerFormatter(
        dataRange: dataRange,
        labeValues: yLabelsDividedInYAxisRange,
        toScaleMin: _yAxisAbsMin,
        toScaleMax: _yAxisAbsMax,
        chartOptions: _chartLayouter._options);

    labelScaler.setLabelValuesForManualLayout(
        labelValues: yLabelsDividedInYAxisRange,
        scaledLabelValues: yLabelsDividedInYAxisRange,
        formattedYLabels: yLabels);
    //labelScaler.scaleLabelInfos();
    //labelScaler.makeLabelsPresentable(); // todo -1 make private

    _commonLayout(labelScaler);
  }

  /// Generate labels from data, and auto layout
  /// Y axis according to data range, labels range, and display range
  void layoutAutomatically() {
    List flatData = _chartLayouter._data.dataRows.expand((i) => i).toList();

    Range range = new Range(
        values: flatData, chartOptions: _chartLayouter._options, maxLabels: 10);

    // revert toScaleMin/Max to accomodate y axis starting from top
    LabelScalerFormatter labelScaler = range.makeLabelsFromDataOnScale(
        toScaleMin: _yAxisAbsMin, toScaleMax: _yAxisAbsMax);

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
    return ", _yLabelsContainerWidth = ${_yLabelsContainerWidth}" +
        ", _yLabelsMaxHeight = ${_yLabelsMaxHeight}";
  }
}

/// A Wrapper of [YLayouter] members that can be used by clients
/// to layout y labels container.

/// Generally, the owner of this object decides what the offsets are:
///   - If owner is YLayouter, all positions are relative to the top of
///     the container of y labels
///   - If owner is Area [SimpleChartLayouter], all positions are relative
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
///     The above requires a Area layouter or similar object, that can ask
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
  /// layouting Area [chartLayouter], giving it [availableWidth],
  /// which is currently the full [chartLayouter._chartArea] width.
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

    // xlabels area without padding
    _xLabelsContainerHeight = outputs
        .map((var output) => output.painter)
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

/// Lays out the legend area for the chart.
///
/// The legend area contains individual legend items. Each legend item
/// has a color square and text, which describes one data row (that is,
/// one data series).
///
/// Currently, each individual legend item is given the same size.
/// This is not very efficient but simple, so legend text should be short
class LegendLayouter {
  /// The containing layouter.
  SimpleChartLayouter _chartLayouter;

  double _availableWidth;

  /// size which contains the whole layed out area of legend (independet of offset).
  ui.Size _size;

  // ### calculated values

  /// Results of laying out the x axis labels.
  List<LegendLayouterOutput> outputs = new List();

  /// Constructor gives this layouter access to it's
  /// layouting Area [chartLayouter], giving it [availableWidth],
  /// which is currently the full width of the [chartArea].
  ///
  /// This layouter uses the full [availableWidth], and takes as
  /// much height as needed for legend labels to be painted.
  ///
  LegendLayouter({
    SimpleChartLayouter chartLayouter,
    double availableWidth,
  }) {
    _chartLayouter = chartLayouter;
    _availableWidth = availableWidth;
  }

  /// Lays out the legend area.
  ///
  /// Evenly divides available width to all legend items.
  layout() {
    ChartOptions options = _chartLayouter._options;
    List<String> rowLegends = _chartLayouter._data.rowLegends;
    double indicatorToLegendPad = options.legendColorIndicatorPaddingLR;
    double indicatorWidth = options.legendColorIndicatorWidth;
    double indicatorHeight = indicatorWidth;
    double containerMarginTB = options.legendContainerMarginTB;
    double containerMarginLR = options.legendContainerMarginLR;

    // Allocated width of one color square + legend text (one legend item)
    double legendItemWidth =
        (_availableWidth - 2 * containerMarginLR) / rowLegends.length;

    var legendSeqs =
        new Iterable.generate(rowLegends.length, (i) => i); // 0 .. length-1

    // First paint all legends, to figure out max height of legends to center all
    // legends label around common center.
    // (todo 1 - is this ^^^ needed? can text of same font be diff. height)

    var legendMax = ui.Size.zero;
    for (var index in legendSeqs) {
      painting.TextPainter p = new LabelPainter(options: options)
          .textPainterForLabel(rowLegends[index]);
      legendMax = new ui.Size(math.max(legendMax.width, p.width),
          math.max(legendMax.height, p.height));
    }

    // Now we know legend container -size.height (width is unused)
    _size = new ui.Size(
        legendMax.width,
        math.max(legendMax.height, indicatorHeight) +
            2 * containerMarginTB);
    // Layout legend core: for each row, create and position
    //   - and indicator rectangle and it's paint
    //   - lable painter
    for (var index in legendSeqs) {
      var legendOutput = new LegendLayouterOutput();

      legendOutput.labelPainter = new LabelPainter(options: options)
          .textPainterForLabel(rowLegends[index]);

      double indicatorX = legendItemWidth * index + containerMarginLR;

      // height-wise center both indicatorRect and label around common
      // middle in  _size.height / 2
      double indicatorTop = (_size.height - indicatorHeight) / 2;
      legendOutput.indicatorRect = new ui.Offset(indicatorX, indicatorTop) &
          new ui.Size(indicatorWidth, indicatorHeight);

      double labelX = indicatorX + indicatorWidth + indicatorToLegendPad;

      // todo -1 add left margin of legend layouter
      double labelTop = (_size.height - legendOutput.labelPainter.height) / 2;
      legendOutput.labelOffset = new ui.Offset(labelX, labelTop);

      legendOutput.indicatorPaint = new ui.Paint();
      legendOutput.indicatorPaint.color =
          options.dataRowsColors[index % options.dataRowsColors.length];

      outputs.add(legendOutput);
    }
  }
}

/// A Wrapper of [LegendLayouter] members that can be used by clients
/// to layout the chart legend container.
///
/// All positions are relative to the left of the container.
class LegendLayouterOutput {
  // sequence in outputs
  int sequence;

  /// Painter configured to paint each legend label
  painting.TextPainter labelPainter;

  ///  rectangle of the legend color square series indicator
  ui.Rect indicatorRect;

  /// Paint used to paint the indicator
  ui.Paint indicatorPaint;

  ///  offset of legend label
  ui.Offset labelOffset;
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
