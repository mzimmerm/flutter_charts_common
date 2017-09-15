import 'dart:math' as math;

class ChartData {

  List<List<double>> dataRows = new List();

  /// Labels on independent (X) axis.
  ///
  /// It is generally assumed labels are defined,
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  List<String> xLabels = new List();

  /// Labels on dependent (Y) axis. They must be numbers.
  ///
  /// If you need number labels with units (e.g. %), define % in options
  /// If you need purely String labels, this is a todo 1.
  ///
  /// This is used only if [ChartOptions.doManualLayoutUsingYLabels] is true.
  ///
  /// They may be undefined, in which case the
  /// Y axis is likely not shown.
  List<String> yLabels = new List();

  void validate() {
    for (List<double> dataRow in dataRows) {
      if (xLabels != null && dataRow.length != xLabels.length) {
        throw new StateError(" dataRow.length != xLabels.length"
            " [${dataRow.length}] != [${xLabels.length}]. ");
      }
    }
  }

  List<double> _flattenData() {
    return this.dataRows.expand((i) => i).toList();
  }

  double maxData() {
     return _flattenData().reduce(math.max);
  }

  double minData() {
     return _flattenData().reduce(math.min);
  }

}