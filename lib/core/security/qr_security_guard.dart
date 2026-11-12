enum QrRiskLevel {
  safe,
  suspicious,
  blocked,
}

enum QrPayloadKind {
  url,
  text,
  wifi,
  contact,
  phone,
  email,
  unknown,
}

class QrDecision {
  final QrPayloadKind kind;
  final QrRiskLevel risk;
  final String rawContent;
  final String? displayHost;
  final Uri? uri;
  final String warningReason;

  const QrDecision({
    required this.kind,
    required this.risk,
    required this.rawContent,
    this.displayHost,
    this.uri,
    this.warningReason = '',
  });

  bool get isSafe => risk == QrRiskLevel.safe;
  bool get isSuspicious => risk == QrRiskLevel.suspicious;
  bool get isBlocked => risk == QrRiskLevel.blocked;
}

class QrSecurityGuard {
  static const Set<String> _dangerousSchemes = {
    'javascript',
    'data',
    'intent',
    'file',
    'content',
  };

  /// Analyzes and classifies raw QR scan results to prevent phishing or malicious actions.
  static QrDecision classify(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return QrDecision(
        kind: QrPayloadKind.unknown,
        risk: QrRiskLevel.blocked,
        rawContent: rawInput,
        warningReason: 'খালি কোড রিড করা হয়েছে।',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      // Plain text QR code
      return QrDecision(
        kind: QrPayloadKind.text,
        risk: QrRiskLevel.safe,
        rawContent: trimmed,
      );
    }

    final scheme = uri.scheme.toLowerCase();

    // 1. Block dangerous URI schemes
    if (_dangerousSchemes.contains(scheme)) {
      return QrDecision(
        kind: QrPayloadKind.unknown,
        risk: QrRiskLevel.blocked,
        rawContent: trimmed,
        uri: uri,
        warningReason: 'নিরাপত্তাজনিত কারণে এই স্ক্রিপ্ট/স্কিম ($scheme) ব্লক করা হয়েছে।',
      );
    }

    // 2. HTTP / HTTPS Link Analysis
    if (scheme == 'http' || scheme == 'https') {
      final host = uri.host.toLowerCase();
      bool isSuspicious = false;
      String reason = '';

      if (scheme == 'http') {
        isSuspicious = true;
        reason = 'এই লিঙ্কটি এনক্রিপ্ট করা নয় (HTTP)।';
      } else if (host.contains('xn--')) {
        isSuspicious = true;
        reason = 'সন্দেহজনক ডোমেইন নেম (Punycode / Homograph attack risk)।';
      } else if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
        isSuspicious = true;
        reason = 'ডোমেইন নামের বদলে ডিরেক্ট IP অ্যাড্রেস ব্যবহার করা হয়েছে।';
      } else if (host.split('.').length > 4) {
        isSuspicious = true;
        reason = 'অতিরিক্ত সাব-ডোমেইন বিশিষ্ট সন্দেহজনক লিঙ্ক।';
      }

      return QrDecision(
        kind: QrPayloadKind.url,
        risk: isSuspicious ? QrRiskLevel.suspicious : QrRiskLevel.safe,
        rawContent: trimmed,
        displayHost: host.isNotEmpty ? host : uri.authority,
        uri: uri,
        warningReason: reason,
      );
    }

    // 3. Known Safe Action Schemes
    if (scheme == 'tel') {
      return QrDecision(
        kind: QrPayloadKind.phone,
        risk: QrRiskLevel.safe,
        rawContent: trimmed,
        uri: uri,
      );
    }

    if (scheme == 'mailto') {
      return QrDecision(
        kind: QrPayloadKind.email,
        risk: QrRiskLevel.safe,
        rawContent: trimmed,
        uri: uri,
      );
    }

    if (scheme == 'WIFI' || trimmed.startsWith('WIFI:')) {
      return QrDecision(
        kind: QrPayloadKind.wifi,
        risk: QrRiskLevel.safe,
        rawContent: trimmed,
      );
    }

    // Default fallback
    return QrDecision(
      kind: QrPayloadKind.url,
      risk: QrRiskLevel.safe,
      rawContent: trimmed,
      displayHost: uri.host,
      uri: uri,
    );
  }
}
