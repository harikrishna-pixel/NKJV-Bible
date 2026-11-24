import 'package:biblebookapp/services/analytics/mixpanel_tracking_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MixpanelTrackingGate.canSendEvent', () {
    test('disabled config blocks all', () {
      const config = MixpanelRemoteConfig(
        enabled: false,
        samplePct: 100,
        dailyEventCap: 40,
      );
      expect(
        MixpanelTrackingGate.canSendEvent(
          config: config,
          sampledInCached: true,
          anonymousId: 'user-a',
          eventsSentToday: 0,
        ),
        isFalse,
      );
    });

    test('null config fails closed', () {
      expect(
        MixpanelTrackingGate.canSendEvent(
          config: null,
          sampledInCached: true,
          anonymousId: 'user-a',
          eventsSentToday: 0,
        ),
        isFalse,
      );
    });

    test('sample_pct 0 blocks', () {
      const config = MixpanelRemoteConfig(
        enabled: true,
        samplePct: 0,
        dailyEventCap: 40,
      );
      expect(
        MixpanelTrackingGate.canSendEvent(
          config: config,
          sampledInCached: null,
          anonymousId: 'user-a',
          eventsSentToday: 0,
        ),
        isFalse,
      );
    });

    test('sample_pct 100 allows when under cap', () {
      const config = MixpanelRemoteConfig(
        enabled: true,
        samplePct: 100,
        dailyEventCap: 40,
      );
      expect(
        MixpanelTrackingGate.canSendEvent(
          config: config,
          sampledInCached: null,
          anonymousId: 'user-a',
          eventsSentToday: 0,
        ),
        isTrue,
      );
    });

    test('daily cap blocks when reached', () {
      const config = MixpanelRemoteConfig(
        enabled: true,
        samplePct: 100,
        dailyEventCap: 40,
      );
      expect(
        MixpanelTrackingGate.canSendEvent(
          config: config,
          sampledInCached: true,
          anonymousId: 'user-a',
          eventsSentToday: 40,
        ),
        isFalse,
      );
      expect(
        MixpanelTrackingGate.canSendEvent(
          config: config,
          sampledInCached: true,
          anonymousId: 'user-a',
          eventsSentToday: 39,
        ),
        isTrue,
      );
    });
  });

  group('app_open_daily once-per-day', () {
    test('sends when never sent', () {
      expect(
        MixpanelTrackingGate.shouldSendAppOpenDaily(
          lastSentDateYmd: null,
          now: DateTime(2026, 11, 24),
        ),
        isTrue,
      );
    });

    test('blocks same calendar day', () {
      expect(
        MixpanelTrackingGate.shouldSendAppOpenDaily(
          lastSentDateYmd: '2026-11-24',
          now: DateTime(2026, 11, 24, 23, 59),
        ),
        isFalse,
      );
    });

    test('allows next calendar day', () {
      expect(
        MixpanelTrackingGate.shouldSendAppOpenDaily(
          lastSentDateYmd: '2026-11-24',
          now: DateTime(2026, 11, 25, 0, 1),
        ),
        isTrue,
      );
    });
  });

  group('stable sample hash', () {
    test('same id is stable', () {
      final a = MixpanelTrackingGate.stableHash('anon-123');
      final b = MixpanelTrackingGate.stableHash('anon-123');
      expect(a, b);
    });
  });
}
