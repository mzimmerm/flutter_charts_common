import 'dart:ui' as ui show Color;
import 'dart:math' as math show Random;
import 'package:flutter/material.dart' as material show Colors;

import 'random_chart_data.dart' show RandomChartData;

/// Options for Chart.
///
/// Generally, some defaults are provided here.
class ChartOptions {

  /// Colors corresponding to each data row (series) in [ChartData].
  final List<ui.Color> dataRowsColors  = new List<ui.Color>();

  final int minNumXGridLines = 1;
  final int minNumYGridLines = 4;

  final ui.Color gridLinesColor = material.Colors.grey;
  final ui.Color xLabelsColor = material.Colors.grey; // or const ui.Color(0xFFEEEEEE)

  // Lines around grid if wanted
  final double gridTopExtendHeight = 6.0;
  // todo 1 - do not need right extend?
  final double gridBottomExtendHeight = 12.0;
  // todo 1: forced by autolayout, for x labels to fit: final double gridLeftExtendWidth = 2.0;

  final double gridStepWidth = 8.0; // todo 0 remove

  // X labels pad from extend.
  final double xLabelsPadTop = 2.0;
  final double xLabelsPadLR = 2.0;

}

/// File for [LineChartOptions] and [RandomLineChartOptions]
/// todo 0
///
class LineChartOptions extends ChartOptions{

  final double hotspotInnerRadius = 3.0;
  final double hotspotOuterRadius = 6.0;

}

class RandomLineChartOptions extends LineChartOptions {

  RandomLineChartOptions(RandomChartData randomChartData ) {

    int dataRowsCount = randomChartData.dataRows.length;

    _setDataRowsRandomColors(dataRowsCount);
  }

  /// Set up to first threee data rows (series) explicitly, rest randomly
  void _setDataRowsRandomColors(int dataRowsCount) {

    if (dataRowsCount >= 1) {
      dataRowsColors.add(material.Colors.red);
    }
    if (dataRowsCount >= 2) {
      dataRowsColors.add(material.Colors.green);
    }
    if (dataRowsCount >= 3) {
      dataRowsColors.add(material.Colors.blue);
    }
    if (dataRowsCount > 3) {
      for (int i = 3; i < dataRowsCount; i++) {
        int colorHex = new math.Random().nextInt(0xFFFFFFFF);
        dataRowsColors.add(new ui.Color(colorHex));
      }
    }
  }

}