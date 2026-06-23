/// Sanitizes sync/auth log text so diagnostics can be kept without exposing
/// tokens, URLs, transaction payloads, or user financial data.
String sanitizeSyncLogText(Object? value, {int maxLength = 600}) {
  if (value == null) return '';

  String text = value.toString();
  if (text.isEmpty) return text;

  final List<RegExp> sensitiveFieldPatterns = <RegExp>[
    RegExp(
      r'("?(?:authorization|api_key|apiKey|token|access_token|refresh_token)"?\s*[:=]\s*)"?[^",\s}]+"?',
      caseSensitive: false,
    ),
    RegExp(
      r'("?(?:name|iban|account_number|accountNumber|description|amount|foreign_amount|foreignAmount|notes|tags|group_title|groupTitle|source_name|sourceName|destination_name|destinationName|category_name|categoryName|budget_name|budgetName|bill_name|billName|external_id|externalId|internal_reference|internalReference|external_url|externalUrl|source_id|sourceId|destination_id|destinationId)"?\s*[:=]\s*)"?[^",}\]]+"?',
      caseSensitive: false,
    ),
  ];

  for (final RegExp pattern in sensitiveFieldPatterns) {
    text = text.replaceAllMapped(
      pattern,
      (Match match) => '${match.group(1)}<redacted>',
    );
  }

  text = text
      .replaceAll(
        RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
        'Bearer <redacted>',
      )
      .replaceAll(
        RegExp(r'https?://[^\s,;)"\]]+', caseSensitive: false),
        '<redacted-url>',
      )
      .replaceAllMapped(
        RegExp(r'([?&](?:query|token|api_key|key)=)[^&\s]+'),
        (Match match) => '${match.group(1)}<redacted>',
      );

  if (text.length > maxLength) {
    return '${text.substring(0, maxLength)}...<truncated>';
  }

  return text;
}
