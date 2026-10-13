/// Route names mirror the exported screen IDs. D1-D3 are OS notifications;
/// D4-D6 are variants of existing screens, not additional destinations.
enum RemoriScreen {
  a0,
  a1,
  a2,
  a3,
  a4,
  a5,
  a6,
  c1,
  c2,
  c3,
  c4,
  c5,
  c6,
  c7,
  c8,
  c9,
  c10,
  c11,
  c12,
  c13,
  c14,
  c15,
  c16,
  c17,
  c18,
  c19,
  c20,
  p1,
  p2,
  p3,
  p4,
  p5,
  p6,
  p7,
  p8,
  p9,
  d7;

  String get path => '/$name';
  bool get isCaregiver => name.startsWith('c');
  bool get isPatient => name.startsWith('p');
  bool get isSetup => this == a4 || this == a5 || this == a6;

  bool get showsNavigation => const {
    c1,
    c2,
    c3,
    c6,
    c8,
    c10,
    c12,
    c14,
    c16,
    c18,
    c20,
    p1,
    p2,
    p4,
    p7,
  }.contains(this);

  int get navigationIndex => switch (this) {
    c3 || c6 => 1,
    c8 => 2,
    c10 || c14 || c16 || c18 || c20 => 3,
    p2 => 1,
    p4 => 2,
    p7 => 3,
    _ => 0,
  };

  static RemoriScreen? fromPath(String path) {
    for (final screen in values) {
      if (screen.path == path) return screen;
    }
    return null;
  }
}
