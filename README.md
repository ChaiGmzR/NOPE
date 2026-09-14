# NOPE

**STAY FOCUS**

NOPE es una aplicación Flutter para Android que añade fricción deliberada al
uso impulsivo del teléfono. Permite iniciar bloques de enfoque o programar
rutinas semanales y mantiene disponibles Teléfono, SMS y WhatsApp.

## Qué incluye este MVP

- Bloques rápidos de 25, 45, 60 o 90 minutos.
- Horarios semanales editables, incluidos periodos que cruzan medianoche.
- Bloqueo de aplicaciones mediante un `AccessibilityService` nativo en Kotlin.
- Lista esencial dinámica para el marcador, la app SMS predeterminada, el
  teclado, WhatsApp, WhatsApp Business y aplicaciones Authenticator detectadas.
- Pantalla de foco con reloj digital, analógico o de arena.
- Diez retos mezclados, incluidos Sudoku, sopa de letras y une los puntos,
  antes de conceder una pausa de cinco minutos.
- Nueva tanda de retos después de cada regreso al bloqueo.
- Calendario de cumplimiento, racha, horas protegidas e interrupciones.
- Apariencia clara/oscura y tres tintas seleccionables.
- Comprobación automática de nuevas versiones publicadas en GitHub Releases.
- Descarga, verificación SHA-256 y apertura del instalador de Android.
- Almacenamiento local; el MVP no usa cuentas, analítica ni servidores.

## Ejecutar

```powershell
flutter pub get
flutter run
```

Para generar un APK instalable de desarrollo:

```powershell
flutter build apk --debug
```

El archivo queda en `build/app/outputs/flutter-apk/app-debug.apk`.

## Actualizaciones

Al iniciar, NOPE consulta la release más reciente de
`ChaiGmzR/NOPE`, compara su etiqueta semántica con la versión instalada y busca
un asset `.apk`. Si existe una versión superior, la app ofrece descargarla.
La descarga solo acepta HTTPS desde GitHub, valida el digest SHA-256 cuando la
API lo proporciona y abre el instalador del sistema.

Android exige que el usuario autorice a NOPE como fuente de instalación y
confirme cada actualización. Esa confirmación no se puede omitir en un teléfono
personal sin administración empresarial.

Para publicar versiones futuras:

1. Incrementa `version` en `pubspec.yaml`, por ejemplo `0.2.0+2`.
2. Compila con `flutter build apk --release` usando la misma clave de firma.
3. Publica una release con etiqueta `v0.2.0` y adjunta un archivo `.apk`.

La clave y las credenciales locales están excluidas de Git. Conserva una copia
segura de `android/app/nope-release.jks` y
`android/SIGNING-CREDENTIALS.txt`: sin ambos archivos no será posible instalar
futuras versiones encima de la v0.1.0.

## Activar el bloqueo

1. Instala y abre NOPE.
2. Pulsa **Activar protección**.
3. En Accesibilidad, selecciona **NOPE Focus Protection** y activa el servicio.
4. Regresa a NOPE y crea un horario o inicia un bloque rápido.

El servicio solo solicita eventos de cambio de ventana y declara
`canRetrieveWindowContent="false"`: no necesita leer el árbol de contenido de
la pantalla para aplicar las reglas.

## Límite de Android

En un teléfono personal, una app común no puede imponer el modo kiosco del
sistema ni hacerse imposible de desactivar. NOPE implementa un bloqueador de
autocontrol con Accesibilidad. El modo `lock task` verdaderamente administrado
requiere un dispositivo corporativo configurado con un Device Policy
Controller (DPC).

- [AccessibilityService — Android Developers](https://developer.android.com/reference/android/accessibilityservice/AccessibilityService)
- [Lock task mode — Android Developers](https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode)
- [Política de AccessibilityService — Google Play](https://support.google.com/googleplay/android-developer/answer/10964491)

Antes de publicar en Google Play se debe completar la declaración de uso de
Accesibilidad, mantener el aviso y consentimiento destacado dentro de la app,
publicar una política de privacidad y probar la protección en distintas capas
de fabricante. La distribución directa mediante actualización APK usa
`REQUEST_INSTALL_PACKAGES`, un permiso sujeto a restricciones adicionales en
Google Play.

## Estructura

```text
lib/
  controllers/    Estado, sesiones, métricas y sincronización
  models/         Horarios de enfoque
  screens/        Onboarding, inicio, bloqueo, horarios, progreso y ajustes
  services/       Persistencia y MethodChannel Android
  theme/          Sistema visual de NOPE
  widgets/        Componentes reutilizables
android/
  .../MainActivity.kt
  .../BlockingAccessibilityService.kt
```

## Verificación

```powershell
flutter analyze
flutter test
flutter build apk --release
```

Las pruebas incluyen periodos regulares y nocturnos, serialización y renders
de regresión visual a 390 × 844 px.
