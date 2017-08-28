import 'dart:math' as math;

class ChartData {

  List<List<double>> dataRows = new List();

  /// Labels on independent (X) axis.
  ///
  /// It is generally assumed labels are defined,
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  List<String> xLabels = new List();

  /// Labels on dependent (Y) axis.
  ///
  /// They may not be defined, in which case the
  /// Y axis is likely not shown.
  List<String> yLabels = new List();

  void validate() {
    for (List<double> list in dataRows) {
      if (xLabels != null) {
        if (list.length != xLabels.length) {
          throw new StateError(" dataList.size() != xLabels.size()"
              " [${list.length}] != [${xLabels.length}]. ");
        }
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