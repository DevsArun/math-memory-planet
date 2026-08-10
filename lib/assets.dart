/// Bundled image asset paths (generated art lives in assets/img/).
class A {
  A._();

  static const String nebula = 'assets/img/nebula.png';
  static const String mascot = 'assets/img/mascot.png';

  static String planet(int modeIndex) => 'assets/img/planet_$modeIndex.png';
}
