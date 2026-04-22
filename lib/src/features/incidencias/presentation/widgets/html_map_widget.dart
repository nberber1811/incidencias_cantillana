// Este es un selector condicional. 
// Si estamos en la web, cargará el widget real.
// Si estamos en Android/iOS, cargará la versión segura.

export 'html_map_widget_mobile.dart'
    if (dart.library.js_interop) 'html_map_widget_web.dart';
