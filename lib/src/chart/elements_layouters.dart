import 'dart:ui' as ui show Rect, Size, Offset;
import 'dart:math' as math show max;

import 'package:flutter/painting.dart' as painting show TextPainter;
//import 'package:flutter/widgets.dart' as widgets show TextPainter;

import 'elements_painters.dart';
import 'chart_options.dart';

/// todo 0 document
///
/// Layout X labels.
///
/// Note:
///   - desired width is given from parent
///   - desired height is calculated
///   - depends on TextPainter
///     provided by LabelPainter.textPainterForLabel(String string)
///   - Can skip labels to fit
///   - Can rotate labels to fit
///   - Can decrease font size to fit
///
/// Given
///
/// Assumes:
///   - Number of labels is the same as number of independent (X) axis points
///     for all values
///
///

class XLabelsLayouter {

  // ### provided values

  List<String> _xLabels;
  double _availableWidth;
  //double _xOffsetOfFirstMidLabel;
  double _spacing;


  // ### calculated values

  /// x offset of label centers. Also represents points on X axis that should 
  /// show a dash for the label center..
  var midLabelsXOffsets = new List<double>();
  List<painting.TextPainter> labelsPainters = new List();
  double xLabelsHeight;
  double gridStepWidth;

  /// todo 0 document
  XLabelsLayouter({
    List<String> xLabels,
    double availableWidth,
    //double xOffsetOfFirstMidLabel,
    ChartOptions chartOptions,
  }) {
    _xLabels = xLabels;
    _availableWidth = availableWidth;
    //_xOffsetOfFirstMidLabel = xOffsetOfFirstMidLabel;
    _spacing = chartOptions.xLabelsPadLR;
  }

  /// Lays out the todo 0 document

  layout() {
    // evenly divided available width. Includes any spacing on each side
    double labelFullWidth = _availableWidth / _xLabels.length;

    gridStepWidth = labelFullWidth;

    double midLabelXOffset = -labelFullWidth / 2; // shift half label width left

    var seq = new Iterable.generate(_xLabels.length, (i) => i); // 0 .. length-1

    for ( var xIndex in seq ) {
      double midLabel = midLabelXOffset * (xIndex + 1);
      midLabelsXOffsets.add(midLabel);
      labelsPainters.add(new LabelPainter().textPainterForLabel(_xLabels[xIndex]));
    }

    xLabelsHeight =
        labelsPainters
            .map((painting.TextPainter p) => p.size.height)
            .reduce(math.max);
  }

}
