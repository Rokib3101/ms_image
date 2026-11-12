import 'package:flutter_test/flutter_test.dart';
import 'package:ms_image/core/security/qr_security_guard.dart';

void main() {
  group('QrSecurityGuard Unit Tests', () {
    test('Classifies standard text as safe', () {
      final decision = QrSecurityGuard.classify('Hello World');
      expect(decision.kind, equals(QrPayloadKind.text));
      expect(decision.risk, equals(QrRiskLevel.safe));
    });

    test('Classifies standard HTTPS URL as safe', () {
      final decision = QrSecurityGuard.classify('https://flutter.dev');
      expect(decision.kind, equals(QrPayloadKind.url));
      expect(decision.risk, equals(QrRiskLevel.safe));
      expect(decision.displayHost, equals('flutter.dev'));
    });

    test('Classifies unencrypted HTTP URL as suspicious', () {
      final decision = QrSecurityGuard.classify('http://example.com');
      expect(decision.kind, equals(QrPayloadKind.url));
      expect(decision.risk, equals(QrRiskLevel.suspicious));
      expect(decision.warningReason, contains('HTTP'));
    });

    test('Classifies IP address host as suspicious', () {
      final decision = QrSecurityGuard.classify('https://192.168.1.1/admin');
      expect(decision.kind, equals(QrPayloadKind.url));
      expect(decision.risk, equals(QrRiskLevel.suspicious));
      expect(decision.warningReason, contains('IP অ্যাড্রেস'));
    });

    test('Classifies Punycode domain as suspicious', () {
      final decision = QrSecurityGuard.classify('https://xn--80ak6aa92e.com');
      expect(decision.kind, equals(QrPayloadKind.url));
      expect(decision.risk, equals(QrRiskLevel.suspicious));
      expect(decision.warningReason, contains('Punycode'));
    });

    test('Blocks dangerous javascript script scheme', () {
      final decision = QrSecurityGuard.classify('javascript:alert(1)');
      expect(decision.risk, equals(QrRiskLevel.blocked));
      expect(decision.warningReason, contains('ব্লক করা হয়েছে'));
    });

    test('Blocks dangerous intent scheme', () {
      final decision = QrSecurityGuard.classify('intent://evil#Intent;end');
      expect(decision.risk, equals(QrRiskLevel.blocked));
      expect(decision.warningReason, contains('ব্লক করা হয়েছে'));
    });
  });
}
