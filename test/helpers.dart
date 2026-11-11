import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/chirp_app.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

class FakeCore implements ChirpCore {
  const FakeCore([this.info = const CoreInfo(version: '9.9.9', protocol: 1)]);

  @override
  final CoreInfo? info;
}

void setWindow(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> pumpChirp(
  WidgetTester tester, {
  ChirpCore core = const FakeCore(),
}) async {
  await tester.pumpWidget(ChirpApp(core: core));
  await tester.pumpAndSettle();
}
