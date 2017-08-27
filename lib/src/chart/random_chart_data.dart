import 'dart:math' as math;

import 'chart_data.dart';

/// Sample (rather than truly random) data for testing the chart.
///
class RandomChartData extends ChartData {

  int numXLabels = 6;

  RandomChartData() {

    init();

    generate();

    validate();

  }

  void init() {

    xLabels = new List<String>();

    xLabels.add('JAN');
    xLabels.add('FEB');
    xLabels.add('MAR');
    xLabels.add('APR');
    xLabels.add('JUN');
    xLabels.add('JUL');
    //xLabels.add('AUG');
    //xLabels.add('SEP');
    //xLabels.add('OCT');


  }

  void generate() {

    dataRows = new List<List<double>>();

    double scale = 200.0;

    math.Random rgen = new math.Random();

    int max = 4;

    dataRows.add(_oneDataRow(rgen, max, 0.0, scale));
    dataRows.add(_oneDataRow(rgen, max, 4.0, scale));
    dataRows.add(_oneDataRow(rgen, max, 8.0, scale));

  }

  List<double> _oneDataRow(math.Random rgen, int max, double pushUp, double scale) {
    List<double> dataRow = new List<double>();
    for (int i = 0; i < numXLabels; i++) {
      dataRow.add((rgen.nextInt(max) + pushUp) * scale);
    }
    return dataRow;
  }

}