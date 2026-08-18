# LiquidMessenger

A premium iOS messenger built with pure SwiftUI (zero third-party dependencies), featuring a Liquid Glass-inspired design system, floating navigation, full chat experience with realistic mock data, and a **GitHub Actions-first build pipeline** — you never need a Mac or Xcode locally.

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
│   ├── App/                           ← entry point, app state, router
│   ├── DesignSystem/                  ← tokens + Glass components + FloatingTabBar
│   ├── Models/                        ← User, Chat, Message, Contact, Call
│   ├── Services/                      ← mock services + persistence + haptics
│   ├── ViewModels/                    ← chat list, chat detail, profile, settings
│   ├── Views/                         ← screens
│   ├── Components/                    ← chat row, bubbles, input bar, avatars
│   ├── Support/Info.plist
│   └── Resources/Assets.xcassets
├── .github/workflows/build_ipa.yml
├── .gitignore
└── README.md
```

## Features

- Liquid Glass design system (`GlassBackground`, `GlassCard`, `GlassButton`, `GlassCircleButton`, `GlassTabBar`, `GlassTextField`, `GlassSheet`, `GlassBadge`) with material layering, gradient tinting, specular strokes — iOS 16-safe (no dependency on newer-only APIs)
- Floating capsule tab bar + circular compose FAB with haptics, badges and animated selection
- Chat list: search, pinned/muted/archived/unread states, swipe actions, lazy rendering, 20+ seeded chats
- Chat detail: bubbles, date separators, delivery states (`sent/delivered/read/failed`), reactions, reply, context menu, typing indicator, simulated incoming replies
- Message types: text, image, video, file, voice, location, system
- Input bar: expanding field, attachment menu, voice-record UI, reply mode, keyboard-safe
- Contacts, Calls, Profile, Edit Profile (validated), Settings (appearance / notifications / privacy / data & storage)
- Theme switching (System/Light/Dark) + accent colors, persisted
- Local persistence via `UserDefaults + Codable`
- Haptic feedback service, Dynamic Type, VoiceOver labels, reduced-motion support
