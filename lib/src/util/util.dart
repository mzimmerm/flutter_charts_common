// Functions here should eventually be held by a class

/// Scale the [value] that must be from the scale
/// given by [ownScaleMin] - [ownScaleMax]
/// to the "to scale" given by  [toScaleMin] - [toScaleMax].
///
/// The calculations are rather pig headed and should be made more terse;
/// also could be separated by caching the scales which do not change
/// unless data change.
double scaleValue(
    {double value,
    double ownScaleMin,
    double ownScaleMax,
    double toScaleMin,
    double toScaleMax}) {
  // first move scales to be both starting at 0; also move value equivalently.
  // Naming the 0 based coordinates ending with 0
  double value0 = value - ownScaleMin;
  double ownScaleMin0 = 0.0;
  double ownScaleMax0 = ownScaleMax - ownScaleMin;
  double toScaleMin0 = 0.0;
  double toScaleMax0 = toScaleMax - toScaleMin;

  // Next scale the value to 0 - 1 segment
  double value0ScaledTo01 = value0 / (ownScaleMax0 - ownScaleMin0);

  // Then scale value0Scaled01 to the 0 based toScale0
  double valueOnToScale0 = value0ScaledTo01 * (toScaleMax0 - toScaleMin0);

  // And finally shift the valueOnToScale0 to a non-0 start on "to scale"

  double scaled = valueOnToScale0 + toScaleMin;

  return scaled;
}
