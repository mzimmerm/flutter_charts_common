import 'dart:math' as math;

class ChartData {

  List<List<double>> dataRows = new List();

  List<String> xLabels = new List();

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