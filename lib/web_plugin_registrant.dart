// Flutter web plugin registrant file.
import 'package:audioplayers_web/audioplayers_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  if (pluginRegistrar != null) {
    AudioplayersPlugin.registerWith(pluginRegistrar);
  }
}
