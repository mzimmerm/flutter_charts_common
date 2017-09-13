import 'dart:math' as math;

import 'dart:collection' as collection;

import 'chart_data.dart';
import 'chart_options.dart';


/// Generator of sample data for testing the charts.
///
class RandomChartData extends ChartData {

  ChartOptions _chartOptions;
  int _numXLabels;
  int _numDataRows;
  bool _useMonthNames;
  int _maxLabelLength;
  bool _overlapYValues;

  /// Generate random data for chart, with number of x labels given by
  /// [numXLabels] and number of data series given by [numDataRows].
  ///
  /// If [useMonthNames] is set to false, random
  ///
  RandomChartData({
    ChartOptions chartOptions,
    int numXLabels = 6,
    int numDataRows = 4,
    bool useMonthNames = true,
    int maxLabelLength = 8,
    bool overlapYValues = false,
  }) {
    _chartOptions = chartOptions;
    _numXLabels = numXLabels;
    _numDataRows = numDataRows;
    _useMonthNames = useMonthNames;
    _maxLabelLength = maxLabelLength;
    _overlapYValues = overlapYValues;

    _generateXLabels();

    _generateYValues();

    _generateYLabels();

    validate();
  }

  /// Generate list of "random" [xLabels] as monthNames
  ///
  ///
  void _generateXLabels() {
    List<String> xLabelsMonths = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];

    for (var xIndex in new Iterable.generate(_numXLabels, (i) => i)) {
      xLabels.add(xLabelsMonths[xIndex % 12]);
    }
  }

  void _generateYLabels() {
    if (_chartOptions.doManualLayoutUsingYLabels) {
      yLabels = [ "25%", "50%", "75%", "100%"];
    }
  }

  void _generateYValues() {
    dataRows = new List<List<double>>();

    double scale = 200.0;

    math.Random rgen = new math.Random();

    int maxYValue = 4;
    double pushUpStep = _overlapYValues ? 0.0 : maxYValue.toDouble();

    for (var rowIndex in new Iterable.generate(_numDataRows, (i) => i)) {
      dataRows.add(
          _oneDataRow(
              rgen: rgen,
              max: maxYValue,
              pushUpBy: (rowIndex - 1) * pushUpStep,
              scale: scale));
    }
    print("Random generator data: ${_flattenData()}.");
  }

  List<double> _oneDataRow(
      {math.Random rgen, int max, double pushUpBy, double scale}) {
    List<double> dataRow = new List<double>();
    for (int i = 0; i < _numXLabels; i++) {
      dataRow.add((rgen.nextInt(max) + pushUpBy) * scale);
    }
    return dataRow;
  }

  List<double> _flattenData() {
    return this.dataRows.expand((i) => i).toList();
  }

}