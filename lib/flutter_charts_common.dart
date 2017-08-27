///
/// **This file [root/lib/flutter_charts_common.dart] _IS the flutter_charts_common package_,
///    and can be used by _external code_ OR _code inside the same lib_.**.
///
/// Basically, files _exported_ in this file, for example
///
/// > export 'src/chart/chart_data.dart';
///
/// are visible to external applications (to which the contents of the _lib_
/// directory is copied through pub) using code like this
///
///       > import 'package:flutter_charts_common/flutter_charts_common.dart';
///
/// Code under [root/lib] directory
///     1. can use same _import 'package:etc'_ as above external code
///     2. or file scheme, e.g.
///     > import 'src/chart/chart_data.dart';
///
/// Any dart file (any client application) located outside
/// of the "lib" directory just above, can only see the classes
/// contained in the exported packages listed in this file, flutter_chart.dart.
///
/// Why? The reasons are complex combination of Dart conventions.
///
/// 1. First:  what makes the directory structure starting from the top level
///            `flutter_charts_common` (call it `root directory`)
///            a **“library package”** (or **”pub package”**)
///            named `flutter_charts_common`? Three requirements:
///     * The existence of file `pubspec.yaml` in the  `root directory`
///     * The presence in `pubspec.yaml`  of the following line
///       `name: flutter_charts_common`
///     * The existence of directory lib just under the `root directory`
/// 2. Second: Why is this file needed? Because dart tools have the
///      convention to consider everything under lib/src private
///      and not visible to external Dart files (if we  were too,
///      for example, copy the whole  root directory under `flutter_charts_common`
///      to some other project). So this file, _flutter_charts.dart_
///      provides the public API to our package `flutter_charts_common`.
///      All classes (and oly those classes) listed "exported" in this file,
///      are visible externally.
/// 3. Third:  Why so complicated?  This is an unfortunate result Dart
///      not being Newspeak :)  but in some seriousness this is the
///      Dart way of providing ability to create private classes in
///      libraries we share with the world.
///
/// Notes:
///  1.  In the naming `.dart` files in export the *lib level is skipped*
///      starting with the ‘src’ representing Private.
///         `export 'src/chart/line/line_chart.dart';` // even though under lib
///  2.  Generally, external code can import
///      all classes in one library in one line, referencing this file
///         `import 'package:flutter_charts_common/flutter_charts_common.dart';`
///  3. We can say that **files below the _lib/src_ directory in Dart,
///     are by convention, private, and invisible above the _lib_ directory.
///


export 'src/chart/chart_data.dart';
export 'src/chart/random_chart_data.dart';
export 'src/chart/line/line_chart.dart';
export 'package:flutter_charts_common/src/chart/chart_options.dart';

export 'src/layout.dart';
