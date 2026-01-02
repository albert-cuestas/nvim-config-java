# LazyVim – Personalización para Java (nvim-jdtls)

Esta personalización mejora la experiencia Java en **LazyVim** configurando **nvim-jdtls** con múltiples *runtimes* de Java y añadiendo un comando/atajo para **cambiar el runtime activo** de JDTLS y **refrescar la configuración de depuración (DAP)**.

Valido para macOS.

## Qué hace

- Detecta automáticamente las instalaciones de Java mediante el comando:

  - ` /usr/libexec/java_home -v <version> `

- Registra varios *runtimes* en **jdtls** (por defecto Java 17), típicamente:
  - Java 11
  - Java 17 (default)
  - Java 21
  - Java 25

- Añade el comando:
  - `:JdtSwitchRuntime`

  que permite seleccionar un runtime y, después:
  - Actualiza la configuración del proyecto en JDTLS
  - Re-genera/actualiza la configuración de depuración de clases principales (DAP)

- Añade un atajo de teclado:
  - `<leader>cjr` → **Switch Java Runtime**

## Prerrequisitos

- **Neovim**
- **LazyVim**
- **LazyVim extras**: `lang.java` habilitado
- Tener instalados los **JDKs** que quieras usar (11/17/21/25, etc.)

> Nota importante: esta configuración usa `/usr/libexec/java_home`, que es propio de **macOS**.  
> En Linux/Windows tendrás que adaptar la función que resuelve las rutas de los JDK.

## Instalación

1. Copia el archivo de plugin (por ejemplo `java.lua`) en tu configuración de LazyVim:

   - `~/.config/nvim/lua/plugins/java.lua`

2. Reinicia Neovim y ejecuta `:Lazy sync` (o deja que Lazy haga la sincronización automáticamente).

## Uso

### Cambiar runtime

- Atajo: `<leader>cjr`
- O comando: `:JdtSwitchRuntime`

Al seleccionar un runtime:

1. Se aplica el cambio al runtime activo de JDTLS.
2. Se actualiza la configuración del proyecto.
3. Se actualiza la configuración de DAP para debug.

Deberías ver notificaciones del tipo:

- “Updating project configuration...”
- “Updating debug configuration...”
- “Runtime <X> ready for debug”

## Personalización

Si quieres añadir/quitar versiones, edita la lista de `runtimes` en la configuración de `nvim-jdtls` y/o ajusta las llamadas a `jhome(<version>)`.

Ejemplo (idea general):

- Añadir Java 26 → `local home26 = jhome(26)` y luego incluir `{ name = "JavaSE-26", path = home26 }`.

## Problemas comunes

- **“No jdtls client found”**
  - Significa que JDTLS aún no está arrancado para el buffer/proyecto actual. Abre un archivo `.java` dentro de un proyecto Java válido y vuelve a probar.

- **No aparecen runtimes / rutas vacías**
  - Asegúrate de que los JDKs están instalados y que ` /usr/libexec/java_home -V ` los lista.
  - Si una versión no existe en tu máquina, la ruta resultará vacía y ese runtime no funcionará.
