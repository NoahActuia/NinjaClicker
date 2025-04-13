// Implémentation des fonctionnalités web pour SaveService
import 'dart:html' as html;

// Exporte un fichier sur le web en permettant le téléchargement
void exportToWebFile(String jsonData, String fileName) {
  final blob = html.Blob([jsonData], 'text/plain', 'native');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

// Stocke une donnée dans le localStorage du navigateur
void storeInWebLocalStorage(String key, String data) {
  html.window.localStorage[key] = data;
}
