
[English](README.md) | [Español](README_ES.md)

# LazyVim – Java Customization (nvim-jdtls)

This customization improves the Java experience in **LazyVim** by configuring **nvim-jdtls** with multiple Java *runtimes* and adding a command/keymap to **switch the active JDTLS runtime** and **refresh the debug (DAP) configuration**.

Works on **macOS**.

## What it does

- Automatically detects Java installations using:

  - `/usr/libexec/java_home -v <version>`

- Registers multiple *runtimes* in **jdtls** (default is Java 17), typically:
  - Java 11
  - Java 17 (default)
  - Java 21
  - Java 25

- Adds the command:
  - `:JdtSwitchRuntime`

  which lets you select a runtime and then:
  - Updates the project configuration in JDTLS
  - Re-generates/updates main-class debug configurations (DAP)

- Adds a keymap:
  - `<leader>cjr` → **Switch Java Runtime**

## Prerequisites

- **Neovim**
- **LazyVim**
- **LazyVim extras**: `lang.java` enabled
- Installed **JDKs** you want to use (11/17/21/25, etc.)

> Important note: this configuration uses `/usr/libexec/java_home`, which is **macOS-specific**.  
> On Linux/Windows you’ll need to adapt the function that resolves JDK paths.

## Installation

1. Copy the plugin file (for example `java.lua`) into your LazyVim configuration:

   - `~/.config/nvim/lua/plugins/java.lua`

2. Restart Neovim and run `:Lazy sync` (or let Lazy sync automatically).

## Usage

### Switch runtime

- Keymap: `<leader>cjr`
- Or command: `:JdtSwitchRuntime`

When you select a runtime:

1. The change is applied to the active JDTLS runtime.
2. The project configuration is updated.
3. The DAP debug configuration is updated.

You should see notifications like:

- “Updating project configuration...”
- “Updating debug configuration...”
- “Runtime <X> ready for debug”

## Customization

If you want to add/remove versions, edit the `runtimes` list in your `nvim-jdtls` configuration and/or adjust the `jhome(<version>)` calls.

Example (general idea):

- Add Java 26 → `local home26 = jhome(26)` and then include `{ name = "JavaSE-26", path = home26 }`.

## Common issues

- **“No jdtls client found”**
  - This means JDTLS hasn’t started for the current buffer/project yet. Open a `.java` file inside a valid Java project and try again.

- **Runtimes not showing / empty paths**
  - Make sure the JDKs are installed and that `/usr/libexec/java_home -V` lists them.
  - If a version doesn’t exist on your machine, the resolved path will be empty and that runtime won’t work.
