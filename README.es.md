# Xiaomi G Pro 27i Red Tint Reset

Pequeño script para Windows destinado a mitigar el problema documentado de tinte rojo o **red tint** en el **Xiaomi Mini LED Gaming Monitor G Pro 27i**, reaplicando un valor de aplicación de pantalla mediante DDC/CI.

Versión en inglés: [`README.md`](README.md).

La solución confirmada en este caso es:

```text
VCP DC / Display Application = 0
```

Esto reproduce el efecto correctivo observado al abrir el OSD del monitor, pasar visualmente por otro perfil de imagen como ECO, y volver a Normal.

## Nota importante sobre el alcance

Esto fue probado en un ambiente muy específico:

- una unidad del Xiaomi Mini LED Gaming Monitor G Pro 27i;
- usado como monitor externo conectado a un notebook;
- configurado como pantalla principal de Windows;
- HDR apagado;
- FreeSync apagado;
- local dimming apagado;
- tasa de refresco de 60 Hz;
- Windows con acceso DDC/CI mediante ControlMyMonitor.

No se han hecho pruebas exhaustivas con HDR encendido, FreeSync encendido, local dimming encendido, otras tasas de refresco, otros drivers de GPU, otros cables, otras configuraciones de conexión, computadores de escritorio ni otras unidades del mismo monitor.

También existe una observación inesperada: en el funcionamiento normal del problema, el red tint tendía a reaparecer después de un ciclo de apagado y encendido del monitor. No parecía haber una corrección manual que resistiera un nuevo encendido del monitor. Sin embargo, después de aplicar este reset por DDC/CI, el estado corregido puede persistir durante varios ciclos de apagado y encendido, es decir, el red tint no necesariamente vuelve cada vez que el monitor se apaga y se vuelve a encender.

Una observación preliminar relacionada es que el estado corregido también parece sobrevivir al menos algunos ciclos de standby y recuperación. Por ejemplo, si el computador se apaga o deja de enviar señal y el monitor entra en standby por timeout de señal, la imagen puede mantenerse corregida cuando vuelve la señal al encender nuevamente el computador. Ese comportamiento no está caracterizado todavía. Debe tratarse como una observación preliminar que requiere más pruebas.

## Observación sobre espacio de color

Una observación posterior sugiere que `VCP DC = 0` está relacionado con la ruta interna de imagen/color del monitor, no solo con un reset invisible del red tint.

En la unidad probada, cuando el espacio de color del OSD estaba configurado en **DCI-P3**, ejecutar el script devolvió el monitor a **Nativo**. Esto hace plausible que el problema de red tint esté vinculado con un estado de espacio de color/gamut mal aplicado o atascado, y que reaplicar `VCP DC = 0` fuerce al firmware del monitor a recargar o reiniciar esa parte de la ruta de procesamiento de imagen.

Hasta ahora esto solo se ha observado con DCI-P3 -> Nativo. Falta probar por separado el comportamiento con Adobe RGB y sRGB.

## Qué hace

El script principal envía este comando DDC/CI al monitor objetivo:

```powershell
ControlMyMonitor.exe /SetValue <monitor> DC 0
```

Efecto secundario observado en la unidad probada:

- puede devolver el espacio de color/gamut del OSD del monitor a **Nativo**.

No cambia:

- fuente de entrada;
- modo de energía;
- brillo;
- contraste;
- perfil de color de Windows;
- configuración de GPU.

## Requisitos

- Windows.
- [ControlMyMonitor](https://www.nirsoft.net/utils/control_my_monitor.html), de NirSoft.
- El monitor Xiaomi debe ser alcanzable mediante DDC/CI.

En el monitor probado no se encontró una opción del OSD para activar o desactivar DDC/CI. En esta configuración, DDC/CI parece ser el comportamiento por defecto del monitor, no una opción visible para el usuario.

## Uso rápido

Pon `ControlMyMonitor.exe` en la misma carpeta que el script de PowerShell, o indica su ruta con `-ControlMyMonitor`.

Ejecuta:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Reset-Xiaomi-RedTint.ps1" -Monitor "Primary"
```

Si el monitor Xiaomi no es la pantalla principal de Windows, primero identifica su monitor string:

```powershell
.\ControlMyMonitor.exe /smonitors ".\monitors.txt"
notepad ".\monitors.txt"
```

Luego ejecuta el reset con el identificador detectado, por ejemplo:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Reset-Xiaomi-RedTint.ps1" -Monitor "\\.\DISPLAY2\Monitor0"
```

## Lanzador BAT con doble clic

Se incluye un lanzador simple en:

```text
scripts\Reset-Xiaomi-RedTint.bat
```

Edita la variable `MONITOR_ID` en ese archivo si es necesario.

## Notas de diagnóstico

La investigación encontró que:

- forzar `VCP 12 / Contrast = 50` no corrigió el tinte rojo;
- alternar `VCP 10 / Brightness` entre los valores de brillo de ECO y Normal no lo corrigió;
- el workaround de preview/hover en el OSD corrigió la imagen sin exponer una diferencia DDC/CI persistente;
- reaplicar explícitamente `VCP DC / Display Application = 0` corrigió el tinte rojo;
- cuando el espacio de color del OSD estaba en DCI-P3, aplicar `VCP DC = 0` lo devolvió a Nativo;
- a diferencia del comportamiento antes observado, en que el red tint tendía a volver después de un ciclo de apagado/encendido del monitor, el reset por DDC/CI puede a veces sobrevivir varios ciclos de apagado/encendido;
- el estado corregido también puede sobrevivir algunos ciclos de standby/recuperación causados por timeout de señal.

Más detalles en [`docs/diagnosis-summary.md`](docs/diagnosis-summary.md). Versión en español: [`docs/diagnosis-summary.es.md`](docs/diagnosis-summary.es.md).

## Nota de privacidad

Este repositorio evita intencionalmente rutas de archivos específicas del usuario, como directorios de perfil de Windows. Los ejemplos usan rutas relativas o identificadores genéricos de monitor.

## Licencia

Todavía no se ha seleccionado licencia.
