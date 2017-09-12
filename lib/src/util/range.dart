import 'dart:math' as math show min, max, pow;
import 'package:decimal/decimal.dart' as decimal;
import '../chart/chart_data.dart';
import '../chart/chart_options.dart';
import 'util.dart';

/// Scalable range, supporting creation of properly scaled x and y axis labels.
///
/// Given a list of values (for example to show on Y axis),
/// [makeLabelsFromData] creates labels evenly distributed to cover the range of values,
/// trying to not waste space, and show only relevant labels, in
/// decimal steps.

class Range {
  // todo 00 document fields and methods

  // ### Public api

  // ### Private api

  /// The auto-label generator [makeLabelsFromData] can decrease this but not increase.
  int _maxLabels;

  List<num> _values;

  Range({List<num> values, int maxLabels = 10}) {
    _values = values;
    // todo 1 maxLabels does not work. Enable and add to test
    _maxLabels = maxLabels;
  }

  /// superior and inferior closure -
  Interval get _closure =>
      new Interval(
          _values.reduce(math.min), _values.reduce(math.max), true, true);

  // todo 00 document
  /// Automatically generates unscaled label values from data.
  LabelScalerFormatter makeLabelsFromData() {
    num min = _closure.min;
    num max = _closure.max;
    num diff = max - min;

    Poly polyMin = new Poly(from: min); // 99
    Poly polyMax = new Poly(from: max); // 101
    Poly polyDiff = new Poly(from: diff); // 2

    int powerMin = polyMin.maxPower; // 1
    int signMin = polyMin.signum;
    int powerMax = polyMax.maxPower; // 2
    int signMax = polyMax.signum;
    int powerDiff = polyDiff.maxPower; // 0
    int signDiff = polyDiff.signum;

    // envelope for all y values
    num from, to;

    // Need to handle all combinations of the above (a < b < c etc).
    // There are not that many, because pMin <= pMax and pDiff <= pMax.
    if (false && powerDiff < powerMin) {
      // todo 1 - enable conditions where y=0 axis is not needed to show,
      //          to allow for details, mainly for lots of values.
      //          Make an option for this. Add to tests.
      from = polyMin.floorAtMaxPower.toDouble(); // 90
      to = polyMax.ceilAtMaxPower.toDouble(); // 110
    } else {
      // for now, always start with min or 0, and end at max (reverse if both negative).

      if (signMax <= 0 && signMin <= 0 || signMax >= 0 && signMin >= 0) {
        // both negative or positive
        if (signMax <= 0) {
          from = min;
          to = 0;
        } else {
          from = 0;
          to = max;
        }
      } else {
        from = min;
        to = max;
      }
    }

    // Now figure out labels, evenly distributed in the from, to range.

    List<num> labels = _distributeLabelsIn(new Interval(from, to));

    print(" ################ makeLabelsFromData: For ###_values=$_values found ###labeValues=${labels} and ###dataRange= ${from} to ${to} ");

    return new LabelScalerFormatter(
        dataRange: new Interval(from, to),
        labeValues: labels);
  }

  /// Makes anywhere from zero to nine label values, at full decimal
  /// values of greatest power of [Interval.max].
  ///
  /// Examples:
  ///   1. [Interval] is <0, 123> then labels=[0, 100]
  ///   2. [Interval] is <0, 299> then labels=[0, 200]
  ///   1. [Interval] is <0, 999> then labels=[0, 900]
  ///
  List<num> _distributeLabelsIn(Interval interval) {
    Poly polyMin = new Poly(from: interval.min);
    Poly polyMax = new Poly(from: interval.max);

    int powerMax = polyMax.maxPower; // 2
    int coeffMax = polyMax.coeffAtMaxPower; // 1
    int signMax = polyMax.signum;

    // using Min makes sense if one or both (min, max) are negative
    int powerMin = polyMin.maxPower; // 0
    int coeffMin = polyMin.coeffAtMaxPower; // 0
    int signMin = polyMin.signum;

    List<num> labels = [];
    int power = math.max(powerMin, powerMax);

    // todo 1 refactor this and make generic
    if (signMax <= 0 && signMin <= 0 || signMax >= 0 && signMin >= 0) {
      // both negative or positive
      if (signMax <= 0) {
        for (int l = signMin * coeffMin; l <= 0; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else {
        // signMax >= 0
        for (int l = 0; l <= signMax * coeffMax; l++) {
          labels.add(l * math.pow(10, power));
        }
      }
    } else {
      // min is negative, max is positive - need added logic
      if (powerMax == powerMin) {
        for (int l = signMin * coeffMin; l <= signMax * coeffMax; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else if (powerMax < powerMin) {
        for (int l = signMin * coeffMin; l <= 1; l++) {
          // just one over 0
          labels.add(l * math.pow(10, power));
        }
      } else if (powerMax > powerMin) {
        for (int l = signMin * 1; l <= signMax * coeffMax; l++) {
          // just one under 0
          labels.add(l * math.pow(10, power));
        }
      } else {
        throw new Exception("Unexpected power: $powerMin, $powerMax ");
      }
    }

    return labels;
  }

}

// todo 00 document as encapsulating Y Labels, also as return from ?? and
// todo 0 refactor and make immutable
class LabelScalerFormatter {
  /// Interval containing all data, unscaled (closure is on the scale of data).
  ///
  /// Note: generally, the interval of labels ([labelValues]) and data ([dataRange])
  ///       overlap/intersect, but do not contain one another.
  Interval dataRange;

  List<LabelInfo> labelInfos;

  LabelScalerFormatter({Interval dataRange, List<num> labeValues}) {
    this.dataRange = dataRange;
    this.labelInfos =
        labeValues.map((value) => new LabelInfo(value, this)).toList();
  }

  /// Self-scale the RangeOutput to the scale of the available chart size.
  void scaleLabelValuesTo({
    double toScaleMin,
    double toScaleMax,
    ChartOptions chartOptions})
  {
    labelInfos
        .map((var labelInfo) =>
        labelInfo._scaleLabelValueTo(
            toScaleMin: toScaleMin,
            toScaleMax: toScaleMax,
            chartOptions: chartOptions))
        .toList();
  }

  void makeLabelsPresentable({ChartOptions chartOptions}) {
    labelInfos
        .map((var labelInfo) =>
    labelInfo.formattedLabel = labelInfo.scaledLabelValue.toString())
        .toList();
  }

  // ### Helper accessors to collection of LabelInfos
  List<num> get labelValues =>
      labelInfos.map((labelInfo) => labelInfo.labelValue).toList();

  Interval get labelRange => new Interval(labelValues.reduce(math.min),  labelValues.reduce(math.max));

  Interval get labelAndDataRangeMerged => labelRange.merge(dataRange);

  List<String> get formattedLabels =>
      labelInfos.map((labelInfo) => labelInfo.formattedLabel).toList();

  List<num> get scaledLabelValues =>
      labelInfos.map((labelInfo) => labelInfo.scaledLabelValue).toList();


}

/// Manages labels and their values: scaled in , unscaled, and presented (formatted) todo 00 document
/// todo 00 review privacy
///
/// Note:
///
///    - YLabels critical issue: There are 3 intervals (example values in text):
///     - We have these scales:
///       - *LabelScalerFormatter.dataRange* e.g.  ###dataRange= [-600.0, 1800.0]  from data _values=[-600.0 ....  1800.0]
///       - *LabelScalerFormatter.labelRange* = [-1000, 1000] was correctly deduced
///       - *LabelScalerFormatter.labelAndDataRangeMerged* =  [-1000, 1800] - merge of the above
///       - *_yAxisAvailableHeight* = 376.0
///       - *Further, y axis must start at _yAxisMinOffsetFromTop = 8.0*
///     - *So, we need to*:
///       - 1. *Map / scale all LabelScalerFormatter.labelValues using:*
///         - /ownScale=labelAndDataRangeMerged=[-1000, 1800]/,
///         - /toScale=[8, 8+376]/;
///       - 2. yAxis scale is [8, 8+376]=[_yAxisMinOffsetFromTop,  _yAxisMinOffsetFromTop + _yAxisAvailableHeight]

class LabelInfo {
  LabelInfo(this.labelValue, this.parentScaler);

  LabelScalerFormatter parentScaler;

  /// Unscaled label value, ([labelValues] are on the scale of data).
  num labelValue;

  /// Label actually showing on axis (Y axis); typically a value with unit.
  ///
  /// Formatted label is just formatted [scaledLabelValue].
  String formattedLabel;

  /// Scaled label value.
  ///
  /// [scaledLabelValue]s are on the scale of y axis length.
  num scaledLabelValue;

  /// Self-scale the RangeOutput to the scale of the available chart size.
  void _scaleLabelValueTo({
    double toScaleMin,
        double toScaleMax,
        ChartOptions chartOptions})
  {

    print("            ### Scaling $this using: " +
        "ownScaleMin: ${parentScaler.labelAndDataRangeMerged.min.toDouble()}, " +
        "ownScaleMax: ${parentScaler.labelAndDataRangeMerged.max.toDouble()}, " +
        "toScaleMin: ${toScaleMin.toDouble()}, " +
        "toScaleMax: ${toScaleMax.toDouble()} ");

    // todo 00 consider what to do about the toDouble() - may want to ensure higher up
    scaledLabelValue = scaleValue(
        value: labelValue.toDouble(),
        ownScaleMin: parentScaler.labelAndDataRangeMerged.min.toDouble(),
        ownScaleMax: parentScaler.labelAndDataRangeMerged.max.toDouble(),
        toScaleMin: toScaleMin.toDouble(),
        toScaleMax: toScaleMax.toDouble());
  }

  String toString() {
    return super.toString() +
        " scaledLabelValue=${this.scaledLabelValue}," +
        " labelValue=${this.labelValue}," +
        " formattedLabel=${this.formattedLabel}";
  }
}

/// Not quite a polynomial. Just the minimum needed for Y label and axis
/// scaling.
///
/// Uses the [decimal] package.
class Poly {
  // ### members

  num _num;
  decimal.Decimal _dec;
  decimal.Decimal _one;
  decimal.Decimal _ten;

  // ### constructors

  /// Create
  Poly({num from}) {
    _num = from;
    _dec = dec(_num.toString());
    _one = numToDec(1); // 1.0
    _ten = numToDec(10);
  }

  // ### methods

  decimal.Decimal dec(String value) => decimal.Decimal.parse(value);

  decimal.Decimal numToDec(num value) => dec(value.toString());

  int get signum => _dec.signum;

  int get fractLen => _dec.scale;

  int get totalLen => _dec.precision;

  int get coeffAtMaxPower =>
      (_dec.abs() / numToDec(math.pow(10, maxPower))).toInt();

  int get floorAtMaxPower =>
      (numToDec(coeffAtMaxPower) * numToDec(math.pow(10, maxPower))).toInt();

  int get ceilAtMaxPower =>
      ((numToDec(coeffAtMaxPower) + dec('1')) *
          numToDec(math.pow(10, maxPower)))
          .toInt();

  /// Position of first significant non zero digit.
  ///
  /// Calculated by starting from 0 at the decimal point, first to the left,
  /// if no non zero is find on the left, then to the right.
  ///
  /// Zeros (0, 0.0 +-0.0 etc) are the only numbers where [maxPower] is 0.
  int get maxPower {
    if (totalLen == fractLen) {
      // pure fraction
      // multiply by 10 till >= 1.0 (not pure fraction)
      return _ltOnePower(_dec);
    }
    return totalLen - fractLen - 1;
  }

  int _geOnePower(decimal.Decimal tester) {
    if (tester < _one) throw new Exception("${tester} Failed: tester < 1.0");
    int power = -1;
    while (tester >= _one) {
      tester = tester / _ten;
      power += 1; // power = 0, 1, 2, etc
    }
    return power;
  }

  int _ltOnePower(decimal.Decimal tester) {
    if (tester >= _one) throw new Exception("${tester} Failed: tester < 1.0");
    int power = 0;
    while (tester < _one) {
      tester = tester * _ten;
      power -= 1; // power = -1, -2, etc
    }
    return power;
  }
}

/*
// todo 1 consider fixing this later
class IntervalC<T extends Comparable> {
  Interval(this.min, this.max,
      [this.includesMin = true, this.includesMax = true]);

  final T min;
  final T max;
  final bool includesMin;
  final bool includesMax;

  bool includes(T comparable) {
    // before - read as: if negative, true, if zero test for includes, if positive, false.
    int beforeMin = comparable.compareTo(min);
    int beforeMax = comparable.compareTo(max);

    // Hopefully these complications gain some minor speed,
    // dealing with the obvious cases first.
    if (beforeMin < 0 || beforeMax > 0) return false;
    if (beforeMin > 0 && beforeMax < 0) return true;
    if (beforeMin == 0 && includesMin) return true;
    if (beforeMax == 0 && includesMax) return true;

    return false;
  }

  /// Outermost union
  IntervalC<Comparable> merge(Interval other) {

    return new IntervalC(math.min(this.min, other.min), math.max(this.max, other.max));
  }
*/

// todo 0 add tests
class Interval {
  // todo 0 make constant; also add validation for min before max
  Interval(this.min, this.max,
      [this.includesMin = true, this.includesMax = true]);

  final num min;
  final num max;
  final bool includesMin;
  final bool includesMax;

  bool includes(num comparable) {
    // before - read as: if negative, true, if zero test for includes, if positive, false.
    int beforeMin = comparable.compareTo(min);
    int beforeMax = comparable.compareTo(max);

    // Hopefully these complications gain some minor speed,
    // dealing with the obvious cases first.
    if (beforeMin < 0 || beforeMax > 0) return false;
    if (beforeMin > 0 && beforeMax < 0) return true;
    if (beforeMin == 0 && includesMin) return true;
    if (beforeMax == 0 && includesMax) return true;

    return false;
  }

  /// Outermost union todo 1 consider includes
  Interval merge(Interval other) {
    return new Interval(
        math.min(this.min, other.min), math.max(this.max, other.max));
  }
}
