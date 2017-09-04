import 'dart:math' as math;

import 'dart:collection' as collection;

import 'chart_data.dart';


/// Generator of sample data for testing the charts.
///
class RandomChartData extends ChartData {

  int  _numXLabels;
  int  _numDataRows;
  bool _useMonthNames;
  int  _maxLabelLength;
  bool _overlapYValues;

  /// Generate random data for chart, with number of x labels given by
  /// [numXLabels] and number of data series given by [numDataRows].
  ///
  /// If [useMonthNames] is set to false, random
  ///
  RandomChartData({
    int numXLabels = 6,
    int numDataRows = 4,
    bool useMonthNames = true,
    int maxLabelLength = 8,
    bool overlapYValues = false,
  })
  {
    _numXLabels = numXLabels;
    _numDataRows = numDataRows;
    _useMonthNames = useMonthNames;
    _maxLabelLength = maxLabelLength;
    _overlapYValues = overlapYValues;

    _generateXLabels();

    _generateYValues();

    validate();

  }

  RandomChartData.fromXLabels({
    List<String> xLabels,
    int numDataRows = 4,
    bool overlapYValues = false,
  })
  {
    this.xLabels = xLabels;

    _numXLabels = xLabels.length;
    _numDataRows = numDataRows;
    _useMonthNames = false;
    // todo 0 : _maxLabelLength = xLabels.map(e => e.size()).reduce(max);
    _maxLabelLength = 20;
    _overlapYValues = overlapYValues;

    _generateYValues();

    validate();

  }

  /// Generate list of "random" [xLabels] as monthNames
  ///
  ///
  void _generateXLabels() {

    List<String> xLabelsMonths =  [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];

    for ( var xIndex in new Iterable.generate(_numXLabels, (i) => i) ) {
      xLabels.add(xLabelsMonths[xIndex % 12]);
    }

  }

  void _generateYValues() {

    dataRows = new List<List<double>>();

    double scale = 200.0;

    math.Random rgen = new math.Random();

    int maxYValue = 4;
    double pushUpStep = _overlapYValues ? 0.0 : maxYValue.toDouble();

    for ( var rowIndex in new Iterable.generate(_numDataRows, (i) => i) ) {
      dataRows.add(
          _oneDataRow(
              rgen: rgen,
              max: maxYValue,
              pushUpBy: (rowIndex - 1) * pushUpStep,
              scale: scale));
    }

  }

  List<double> _oneDataRow({math.Random rgen, int max, double pushUpBy, double scale}) {
    List<double> dataRow = new List<double>();
    for (int i = 0; i < _numXLabels; i++) {
      dataRow.add((rgen.nextInt(max) + pushUpBy) * scale);
    }
    return dataRow;
  }

}