import 'dart:ui' as ui show Color;
import 'dart:math' as math show Random, pow;
import 'package:flutter/material.dart' as material show Colors;

import 'random_chart_data.dart' show RandomChartData;

Function toLabel = (String label) => label + yLabelUnits;

Function valueToLabel = (num value) => value.toString() + yLabelUnits;

/// Options for chart allow to configure certain sizes, colors, and layout.
///
/// Generally, some defaults are provided here. Some options, mostly sizing
/// related, may be overriden or adjusted by the chart auto-layout.
class ChartOptions {

  /// Colors corresponding to each data row (series) in [ChartData].
  final List<ui.Color> dataRowsColors = new List<ui.Color>();

  /// Number of grid lines. Autolayout can decrease but not increase todo 00 decrease not implemented
  final int minNumXGridLines = 1; // todo 00 not needed with auto layout?
  final int minNumYGridLines = 4; // todo 00 not needed with auto layout?

  /// Color defaults
  final ui.Color gridLinesColor = material.Colors.grey;
  final ui.Color xLabelsColor = material.Colors
      .grey; // or const ui.Color(0xFFEEEEEE)

  /// Length of ticks around the grid rectangle.
  /// Autolayout can increase these lengths, to fit labels below them.
  final double xTopMinTicksHeight = 6.0; // todo 00 not applied?
  final double yRightMinTicksWidth = 6.0;
  final double xBottomMinTicksHeight = 6.0;
  final double yLeftMinTicksWidth = 6.0;

  /// Pad space around X labels. todo 00 separate top, bottom, left, right, and only keep those used
  final double xLabelsPadTB = 2.0; // to extended grid and bottom
  final double xLabelsPadLR = 2.0; // to the left, right

  /// Pad space around Y labels.todo 00 separate top, bottom, left, right, and only keep those used
  final double yLabelsPadTB = 2.0;
  final double yLabelsPadLR = 2.0;

  final String yLabelUnits = "";

}

/// File for [LineChartOptions] and [RandomLineChartOptions]
/// todo 00 document
///
class LineChartOptions extends ChartOptions {

  final double hotspotInnerRadius = 3.0;
  final double hotspotOuterRadius = 6.0;

}

class RandomLineChartOptions extends LineChartOptions {

  RandomLineChartOptions(RandomChartData randomChartData) {
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
        int colorHex = new math.Random().nextInt(0xFFFFFF);
        int opacityHex = 0xFF;
        dataRowsColors.add(
            new ui.Color(colorHex + (opacityHex * math.pow(16, 6))));
      }
    }
  }

}