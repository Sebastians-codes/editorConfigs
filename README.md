# VS Code Setup Guide

This guide will help you set up VS Code with the same extensions,
settings, and keybindings used in this project.

## Prerequisites

- VS Code installed
- Git installed

## Installation Steps

### 1. Clone or Pull Settings and Keybindings

If your `.vscode` directory (containing `settings.json` and
`keybindings.json`) is in your GitHub repo, it will be synced
automatically when you clone or pull the repository.

### 2. Install Extensions

Save the following extensions list as `extensions.txt` in your
project root:


artlaman.chalice-icon-theme eamodio.gitlens esbenp.prettier-vscode
expo.vscode-expo-tools ms-dotnettools.csdevkit ms-dotnettools.csharp
ms-dotnettools.vscode-dotnet-runtime mvllow.rose-pine
qufiwefefwoyn.kanagawa redhat.vscode-yaml rust-lang.rust-analyzer
steoates.autoimport streetsidesoftware.code-spell-checker
streetsidesoftware.code-spell-checker-swedish usernamehw.errorlens
vscodevim.vim ziglang.vscode-zig


Then run:

```bash
**Linux/macOS:**
cat extensions.txt | xargs -I {} code --install-extension {}

Windows (PowerShell):

Get-Content extensions.txt | ForEach-Object { code -
-install-extension $_ }

### 3. Verify Setup

Restart VS Code and confirm:

• ✅ Extensions appear in the Extensions panel
• ✅ Your color theme (Rose Pine or Kanagawa) is active
• ✅ Custom settings are applied
• ✅ Keybindings are working

## What's Included

### Extensions

• GitLens - Enhanced Git integration
• C# Dev Kit - C# development tools
• Prettier - Code formatter
• Rust Analyzer - Rust language support
• Vim - Vim key bindings
• Error Lens - Inline error display
• And more...

### Settings

Project-specific settings in .vscode/settings.json

### Keybindings

Custom keybindings in .vscode/keybindings.json

## Troubleshooting

If extensions don't install automatically:

1. Update VS Code to the latest version
2. Try installing extensions individually through the VS Code UI
3. Check the VS Code output panel for error messages
