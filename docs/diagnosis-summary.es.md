# Resumen de diagnóstico

Versión en inglés: [`diagnosis-summary.md`](diagnosis-summary.md).

Este documento resume la investigación realizada sobre el problema de tinte rojo o **red tint** en el Xiaomi Mini LED Gaming Monitor G Pro 27i.

## Contexto

El monitor puede mostrar un tinte rojo después de ciertos cambios de estado. Un workaround manual conocido consiste en abrir el OSD del monitor, pasar desde el perfil deseado, por ejemplo Normal, a otro perfil como ECO, y luego volver a Normal.

El objetivo fue descubrir si ese efecto correctivo podía reproducirse mediante DDC/CI.

## Ambiente de prueba y limitaciones

El resultado fue obtenido en una configuración muy específica:

- una unidad del Xiaomi Mini LED Gaming Monitor G Pro 27i;
- usado como monitor externo conectado a un notebook;
- configurado como pantalla principal de Windows;
- HDR desactivado;
- FreeSync desactivado;
- local dimming desactivado;
- tasa de refresco de 60 Hz;
- Windows con ControlMyMonitor para enviar comandos DDC/CI.

No se han probado exhaustivamente los siguientes casos:

- HDR activado;
- FreeSync activado;
- local dimming activado;
- tasas de refresco distintas de 60 Hz;
- otros cables o puertos;
- otras configuraciones de conexión;
- computadores de escritorio;
- otras GPU o drivers de GPU;
- otras unidades del mismo monitor.

Por lo tanto, esto debe tratarse como un hallazgo funcional para un ambiente observado, no como una corrección plenamente generalizada para todas las configuraciones posibles.

## Nota sobre disponibilidad de DDC/CI

En el OSD del monitor probado no se encontró una opción para activar o desactivar DDC/CI. En esta configuración, DDC/CI parece ser el comportamiento por defecto del monitor, no una opción visible para el usuario.

El requisito real es que el monitor Xiaomi sea alcanzable mediante DDC/CI desde Windows y ControlMyMonitor.

## Observación inesperada sobre persistencia

Se observó un comportamiento inesperado después de aplicar el reset mediante DDC/CI.

Antes de este workaround DDC/CI, el red tint tendía a reaparecer después de un ciclo de apagado y encendido del monitor. En otras palabras, el workaround manual desde el OSD no parecía producir una corrección capaz de sobrevivir un nuevo ciclo de encendido del monitor; normalmente el red tint volvía a aparecer en un encendido nuevo.

Después de aplicar el reset por DDC/CI, sin embargo, el estado corregido puede a veces mantenerse activo durante varios ciclos de apagado y encendido del monitor. Esto significa que el red tint no necesariamente vuelve cada vez que el monitor se apaga y se vuelve a encender después de aplicar el comando DDC/CI.

Una observación preliminar relacionada es que el estado corregido también parece sobrevivir al menos algunos ciclos de standby y recuperación. Por ejemplo, cuando el computador se apaga o deja de enviar señal y el monitor entra en standby después de un timeout de señal, la imagen puede mantenerse corregida cuando vuelve la señal al encender nuevamente el computador.

Esta persistencia todavía no está comprendida. Podría depender del estado del firmware del monitor, del estado del OSD, de algún caché de estado DDC/CI, del comportamiento frente a pérdida y recuperación de señal, del estado de energía o de otra condición interna. Requiere pruebas controladas adicionales.

En esta etapa debe documentarse solo como observación preliminar, no como comportamiento garantizado.

## Observación sobre espacio de color / gamut

Una observación posterior sugiere que el comando exitoso está vinculado con la ruta interna de imagen/color del monitor.

Cuando el espacio de color del OSD estaba configurado en **DCI-P3**, aplicar:

```powershell
ControlMyMonitor.exe /SetValue <monitor> DC 0
```

devolvió el monitor a espacio de color **Nativo**.

Esto sugiere que `VCP DC = 0` podría ser más que un reset estrecho del red tint. Podría forzar al firmware del monitor a recargar o reiniciar la aplicación de pantalla activa, incluyendo el estado de espacio de color/gamut. Una hipótesis posible es que el problema de red tint esté relacionado con un estado interno de espacio de color/gamut atascado, corrupto o incorrectamente aplicado.

Hasta ahora esto solo se ha observado con DCI-P3 -> Nativo. Falta probar por separado el comportamiento con Adobe RGB y sRGB.

## Herramientas usadas

- Windows PowerShell.
- NirSoft ControlMyMonitor.
- Lecturas y escrituras VCP mediante DDC/CI.

## Secuencia de diagnóstico

### 1. Captura de estados antes y después de cambios de perfil

Se capturaron tres estados:

1. Normal con red tint visible.
2. ECO seleccionado o en preview desde el OSD.
3. Normal nuevamente después de corregirse el red tint.

### 2. Candidatos descartados

#### VCP 12 / Contrast

Una diferencia inicial mostró que el contraste pasaba de `0` a `50`, pero aplicar explícitamente:

```powershell
ControlMyMonitor.exe /SetValue <monitor> 12 50
```

no corrigió el red tint.

Conclusión: probablemente era un artefacto de lectura o un estado secundario, no la causa de la corrección.

#### VCP 10 / Brightness

Una prueba más limpia de Normal a ECO y de vuelta a Normal mostró cambios de brillo:

```text
Normal -> ECO: 32 -> 20
ECO -> Normal: 20 -> 32
```

Sin embargo, alternar explícitamente el brillo:

```text
20 -> 32
```

no corrigió el red tint.

Conclusión: los cambios de brillo eran reales, pero no bastaban para activar la corrección interna.

#### VCP 60 / Input Select y VCP D6 / Power Mode

Estos códigos aparecieron en una captura inicial, pero no se usaron para la automatización porque son más riesgosos:

- `60` puede cambiar la fuente de entrada.
- `D6` puede afectar el estado de energía del monitor.

El script final intencionalmente no los usa.

## Candidato exitoso

El comando exitoso fue:

```powershell
ControlMyMonitor.exe /SetValue <monitor> DC 0
```

Esto reaplica:

```text
VCP DC / Display Application = 0
```

Corrigió el red tint sin cambiar brillo, fuente de entrada, modo de energía ni contraste.

Una comprobación posterior mostró que este mismo comando puede devolver el espacio de color del OSD desde DCI-P3 a Nativo en la unidad probada. Por lo tanto, quienes usen intencionalmente DCI-P3 deberían revisar el ajuste de espacio de color del OSD después de ejecutar el script.

## Recomendación final

Usar únicamente:

```text
VCP DC = 0
```

Evitar automatizar la fuente de entrada, el modo de energía u otros valores específicos del fabricante, salvo que pruebas adicionales demuestren que son seguros.

## Preguntas abiertas

- ¿El workaround sigue funcionando con HDR activado?
- ¿El workaround sigue funcionando con FreeSync activado?
- ¿El workaround sigue funcionando con local dimming activado?
- ¿El workaround se comporta igual con tasas de refresco superiores a 60 Hz?
- ¿El workaround se comporta igual cuando el monitor no está conectado a un notebook o no está configurado como pantalla principal de Windows?
- ¿Por qué el estado corregido puede persistir durante varios ciclos de apagado y encendido después de aplicar el comando DDC/CI, cuando la corrección manual anterior parecía no sobrevivir un nuevo encendido del monitor?
- ¿Por qué el estado corregido puede sobrevivir algunos ciclos de standby/recuperación causados por timeout de señal?
- ¿`VCP DC = 0` siempre devuelve DCI-P3 a Nativo, o solo bajo ciertos estados?
- ¿Qué ocurre si el espacio de color activo del OSD es Adobe RGB o sRGB antes de aplicar el comando?
- ¿El problema de red tint se debe a un estado interno de espacio de color/gamut atascado o incorrectamente aplicado?
- ¿La persistencia depende del firmware del monitor, del estado del OSD, del estado DDC/CI, del comportamiento frente a pérdida y recuperación de señal, del estado de color o del comportamiento de Windows/GPU?
