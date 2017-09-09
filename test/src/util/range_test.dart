import 'package:test/test.dart';

// import 'package:flutter_test/flutter_test.dart';
import '../../../lib/src/util/range.dart';

void main() {
  test('my first unit test', () {
    var answer = 42;
    expect(answer, 42);
  });

  test('Poly power and coeff', () {
    Poly p = new Poly(from: 123.04);
    expect(p.signum, 1);
    expect(p.maxPower, 2);
    expect(p.coeffAtMaxPower, 1);

    p = new Poly(from: 78);
    expect(p.signum, 1);
    expect(p.maxPower, 1);
    expect(p.coeffAtMaxPower, 7);

    p = new Poly(from: 0);
    expect(p.signum, 0);
    expect(p.maxPower, 0);
    expect(p.coeffAtMaxPower, 0);

    p = new Poly(from: 0.0);
    expect(p.signum, 0);
    expect(p.maxPower, 0);
    expect(p.coeffAtMaxPower, 0);

    p = new Poly(from: 0.1);
    expect(p.signum, 1);
    expect(p.maxPower, -1);
    expect(p.coeffAtMaxPower, 1);

    p = new Poly(from: 0.01);
    expect(p.signum, 1);
    expect(p.maxPower, -2);
    expect(p.coeffAtMaxPower, 1);

    p = new Poly(from: -0.01);
    expect(p.signum, -1);
    expect(p.maxPower, -2);
    expect(p.coeffAtMaxPower, 1);
  });

  test('Poly floor and ceil', () {
    Poly p = new Poly(from: 123.04);
    int maxPower = p.maxPower;
    expect(p.floorAtMaxPower, 100); // ex: throwsA(throwsException));
    expect(p.ceilAtMaxPower, 200);

    // todo 0 test pure fractions and negatives
  });


  test('Range makeLabels', () {

    Range r = new Range(values: [1, 22, 333], maxLabels: 0);
    RangeOutput o = r.makeLabels();
    Interval c = o.closure;
    List<num> labels = o.labels;
    expect(c.min, 0.0);
    expect(c.max, 333.0);
    expect(labels.length, 4);
    expect(labels[0], 0.0);
    expect(labels[1], 100.0);
    expect(labels[2], 200.0);
    expect(labels[3], 300.0);

    r = new Range(values: [-1, -22, -333], maxLabels: 0);
    o = r.makeLabels();
    c = o.closure;
    labels = o.labels;
    expect(c.min, -333.0);
    expect(c.max, 0.0);
    expect(labels.length, 4);
    expect(labels[0], -300.0);
    expect(labels[1], -200.0);
    expect(labels[2], -100.0);
    expect(labels[3], 0.0);

    r = new Range(values: [22, 10, -333], maxLabels: 0);
    o = r.makeLabels();
    c = o.closure;
    labels = o.labels;
    expect(c.min, -333.0);
    expect(c.max, 22.0);
    expect(labels.length, 5);
    expect(labels[0], -300.0);
    expect(labels[1], -200.0);
    expect(labels[2], -100.0);
    expect(labels[3], 0.0);
    expect(labels[4], 100.0);

    r = new Range(values: [-22, -10, 333], maxLabels: 0);
    o = r.makeLabels();
    c = o.closure;
    labels = o.labels;
    expect(c.min, -22.0);
    expect(c.max, 333.0);
    expect(labels.length, 5);
    expect(labels[0], -100.0);
    expect(labels[1], 0.0);
    expect(labels[2], 100.0);
    expect(labels[3], 200.0);
    expect(labels[4], 300.0);

    // todo 0 test pure fractions, and combination of pure fractions and mixed (whole.fraction)
  });

}
