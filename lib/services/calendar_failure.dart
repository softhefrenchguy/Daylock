// Only these fixed messages may be displayed; provider responses can contain
// credentials or private calendar details and must never be shown verbatim.
enum CalendarFailureKind {
  authorization,
  configuration,
  unavailable,
  response,
  adminConsent,
  accountMismatch,
}

class CalendarFailure implements Exception {
  final CalendarFailureKind kind;
  final bool isMicrosoft;
  const CalendarFailure(this.kind, {this.isMicrosoft = false});

  String get message => switch (kind) {
    CalendarFailureKind.authorization =>
      isMicrosoft
          ? 'Microsoft calendar access needs renewed permission. Reconnect this account. Your organisation may require administrator approval. Cached events are still available.'
          : 'Google calendar permission has expired or was removed. Reconnect this account. Cached events are still available.',
    CalendarFailureKind.configuration =>
      isMicrosoft
          ? 'Microsoft sign-in is not configured correctly. Check the Entra client ID, native redirect URI and supported account types.'
          : 'Google sign-in is not configured correctly. Check the OAuth client ID, Android package and signing certificate.',
    CalendarFailureKind.unavailable =>
      isMicrosoft
          ? 'Microsoft Calendar is unavailable. Check your connection and try again. Work accounts need an accessible Exchange mailbox. Cached events are still available.'
          : 'Google Calendar is unavailable. Check your connection and try syncing again. Cached events are still available.',
    CalendarFailureKind.response =>
      isMicrosoft
          ? 'Microsoft returned an incomplete or unsupported calendar response. Cached events are still available. Try again later.'
          : 'Google returned an incomplete or unsupported calendar response. Cached events are still available. Try again later.',
    CalendarFailureKind.adminConsent => 'Your organisation requires administrator approval or restricts this sign-in. Contact your IT administrator. Cached events are still available.',
    CalendarFailureKind.accountMismatch => 'Select the same Microsoft account and organisation when reconnecting. Existing accounts and cached events have been kept.',
  };
}
