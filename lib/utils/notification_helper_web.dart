// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void requestWebNotificationPermission() {
  js.context.callMethod('eval', [
    """
    if (!('Notification' in window)) {
      alert('Ta przeglądarka nie obsługuje powiadomień.');
    } else {
      Notification.requestPermission().then(function (permission) {
        if (permission === 'granted') {
          alert('Powiadomienia zostały włączone!');
        } else {
          alert('Na iPhone powiadomienia działają tylko po dodaniu aplikacji do ekranu głównego (Udostępnij -> Dodaj do ekranu początkowego) i muszą zostać zaakceptowane.');
        }
      });
    }
    """
  ]);
}
