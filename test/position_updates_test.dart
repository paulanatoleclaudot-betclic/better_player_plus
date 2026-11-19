import 'package:better_player_plus/src/video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final TestDefaultBinaryMessenger messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const MethodChannel channel = MethodChannel('better_player_channel');
  const String eventsChannelName = 'better_player_channel/videoEvents0';
  late List<String> calls;

  setUp(() {
    calls = [];
    messenger
      ..setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        calls.add(methodCall.method);
        switch (methodCall.method) {
          case 'create':
            return <String, dynamic>{'textureId': 0};
          case 'position':
            return 1000;
          case 'setDataSource':
            await messenger.handlePlatformMessage(
              eventsChannelName,
              const StandardMethodCodec().encodeSuccessEnvelope(<String, Object>{
                'event': 'initialized',
                'duration': 100000,
                'width': 1920,
                'height': 1080,
              }),
              (ByteData? data) {},
            );
        }
        return null;
      })
      ..setMockMethodCallHandler(const MethodChannel(eventsChannelName), (MethodCall methodCall) async => null);
  });

  tearDown(() {
    messenger
      ..setMockMethodCallHandler(channel, null)
      ..setMockMethodCallHandler(const MethodChannel(eventsChannelName), null);
  });

  test('A playing video follows its position without asking for the absolute one', () async {
    final VideoPlayerController controller = VideoPlayerController();
    await controller.setNetworkDataSource('https://example.com/live.m3u8');
    await controller.play();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(calls, contains('position'));
    expect(calls, isNot(contains('absolutePosition')));
    expect(controller.value.position, const Duration(seconds: 1));

    await controller.dispose();
  });
}
