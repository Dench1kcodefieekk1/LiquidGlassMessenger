# LiquidMessenger

A premium iOS messenger built with pure SwiftUI (zero third-party dependencies), featuring Telegram-style authentication, a Liquid Glass-inspired design system, floating navigation with drag gesture, a fluid morphing message-send animation, and a **GitHub Actions-first build pipeline** — you never need a Mac or Xcode locally.

## Requirements (Windows developer)

- Windows PC
- Git
- GitHub account + a repository

**No Xcode, no macOS, no certificates, no provisioning profiles required locally.**

## How the build works

```text
Windows → Git → GitHub → Actions → macOS runner → Xcode/xcodebuild → IPA artifact
```

The repository does **not** contain a hand-written `*.xcodeproj` (those are fragile to author by hand and noisy in git). Instead the single source of truth is [`project.yml`](project.yml) (an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec). GitHub Actions generates a deterministic `LiquidMessenger.xcodeproj` from it on every build, then compiles with `xcodebuild`. XcodeGen is preinstalled on GitHub `macos-latest` runners (auto-installed via Homebrew as a fallback).

## Upload the project

```powershell
cd LiquidMessenger
git init
git add .
git commit -m "LiquidMessenger"
git branch -M main
git remote add origin https://github.com/<your-username>/LiquidMessenger.git
git push -u origin main
```

## Trigger the build & get the IPA

1. Open your repository on GitHub → **Actions** tab.
2. The **Build iOS IPA** workflow runs automatically on every push (or click **Run workflow** for a manual run).
3. Open the completed run → **Artifacts** section.
4. Download **`LiquidMessenger-iOS-unsigned`** (`LiquidMessenger.ipa`).

## What "unsigned IPA" means

> The GitHub Actions workflow produces an **unsigned/unprovisioned** build artifact.
> An unsigned IPA is **not** equivalent to a normally signed App Store / TestFlight application.
> Actual device installation requires an appropriate signing/provisioning method.

The pipeline intentionally requires **no** Apple Developer account, certificates, provisioning profiles, or App Store Connect keys. The artifact proves the project compiles end-to-end and can be inspected/sideloaded with third-party signing tooling at your own discretion.

## Adding real signing later

1. Store your distribution certificate (`.p12`, base64) and provisioning profile (base64) as GitHub **repository secrets**.
2. In the workflow: decode both into the runner, create a temporary keychain, `xcode-select` your exact Xcode, then:
   - remove `CODE_SIGNING_ALLOWED=NO` overrides,
   - set `CODE_SIGN_STYLE=Manual`, `PROVISIONING_PROFILE_SPECIFIER`, `CODE_SIGN_IDENTITY="Apple Distribution"`,
   - `xcodebuild archive` + `xcodebuild -exportArchive` with an `ExportOptions.plist`.

## Changing the bundle identifier

Edit `PRODUCT_BUNDLE_IDENTIFIER` in [`project.yml`](project.yml) (target settings, `base`). The project is regenerated automatically on the next Actions run.

## Project layout

```text
LiquidMessenger/
├── project.yml                        ← XcodeGen spec (source of truth for the .xcodeproj)
├── LiquidMessenger/
│   ├── App/                           ← entry point, app state, router, ThemeManager
│   ├── DesignSystem/                  ← tokens + Glass components + FloatingTabBar
│   ├── Models/                        ← User, Chat, Message, Contact, Call
│   ├── Services/                      ← local services + persistence + haptics
│   ├── ViewModels/                    ← chat list, chat detail, profile, settings
│   ├── Views/                         ← screens (Welcome, Phone, OTP, chats, settings)
│   ├── Components/                    ← chat row, bubbles, input bar, avatars
│   ├── Support/                       ← Info.plist, CountryCodes
│   └── Resources/Assets.xcassets
├── .github/workflows/build_ipa.yml
├── .gitignore
└── README.md
```

## Features

- Telegram-style local authentication: Welcome → Phone (country code with live flag + auto-focus handoff) → OTP (`11111`), session persisted via `@AppStorage("isLoggedIn")`, logout in Settings
- Clean chat list: **no demo chats** — the only default conversation is **Saved Messages** (personal notes, persisted locally, polished empty state)
- Fluid **morphing send animation**: the input text detaches, flies up and settles into the conversation as a real bubble (state machine + springs, Reduce Motion fallback)
- Liquid Glass design system (`GlassBackground`, `GlassCard`, `GlassButton`, `GlassCircleButton`, `GlassTextField`, `GlassSheet`, `GlassBadge`) with material layering, gradient tinting, specular strokes — iOS 16-safe (no dependency on newer-only APIs)
- Floating capsule tab bar + circular compose FAB with haptics, badges, animated selection and **interactive drag across tabs**
- Chat list: search, pinned/muted/archived/unread states, swipe actions, lazy rendering
- Chat detail: bubbles, date separators, delivery states (`sent/delivered/read/failed`), reactions, reply, context menu, typing indicator
- Message types: text, image, video, file, voice, location, system
- Input bar: expanding field, attachment menu, voice-record UI, reply mode, keyboard-safe
- My Profile (Telegram style): avatar, name, @username, phone from auth, location, date of birth — all editable and persisted; username validation
- Contacts, Calls, Settings (appearance / notifications / privacy / data & storage)
- Theme switching (System/Light/Dark) via one `@AppStorage("appTheme")` source of truth + live accent colors via `@AppStorage("accentColor")`
- Local persistence via `UserDefaults + Codable` (profile, settings, chats, messages)
- Haptic feedback service, Dynamic Type, VoiceOver labels, reduced-motion support
