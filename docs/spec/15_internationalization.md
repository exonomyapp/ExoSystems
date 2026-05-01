# Internationalization (i18n)

## Requirement
All Exosystem applications must support 41 languages for genuine global accessibility from initial public release.

## Supported Languages

### Western Europe (9)
| Code | Language | Direction |
|---|---|---|
| `en` | English | LTR |
| `fr` | French | LTR |
| `de` | German | LTR |
| `es` | Spanish | LTR |
| `pt` | Portuguese | LTR |
| `it` | Italian | LTR |
| `nl` | Dutch | LTR |
| `sv` | Swedish | LTR |
| `el` | Greek | LTR |

### Eastern Europe (7)
| Code | Language | Direction |
|---|---|---|
| `ru` | Russian | LTR |
| `uk` | Ukrainian | LTR |
| `pl` | Polish | LTR |
| `ro` | Romanian | LTR |
| `bg` | Bulgarian | LTR |
| `cs` | Czech | LTR |
| `hu` | Hungarian | LTR |

### Russia Regional (2)
| Code | Language | Direction |
|---|---|---|
| `tt` | Tatar | LTR |
| `ce` | Chechen | LTR |

### Middle East & Central Asia (5)
| Code | Language | Direction |
|---|---|---|
| `ar` | Arabic | **RTL** |
| `fa` | Persian (Farsi) | **RTL** |
| `tr` | Turkish | LTR |
| `he` | Hebrew | **RTL** |
| `ku` | Kurdish (Kurmanji) | **RTL** |

### East Asia (4)
| Code | Language | Direction |
|---|---|---|
| `zh-Hans` | Chinese (Simplified) | LTR |
| `zh-Hant` | Chinese (Traditional) | LTR |
| `ja` | Japanese | LTR |
| `ko` | Korean | LTR |

### South Asia (4)
| Code | Language | Direction |
|---|---|---|
| `hi` | Hindi | LTR |
| `bn` | Bengali | LTR |
| `ur` | Urdu | **RTL** |
| `ta` | Tamil | LTR |

### Southeast Asia (5)
| Code | Language | Direction |
|---|---|---|
| `id` | Indonesian | LTR |
| `th` | Thai | LTR |
| `vi` | Vietnamese | LTR |
| `ms` | Malay | LTR |
| `fil` | Filipino (Tagalog) | LTR |

### Africa (5)
| Code | Language | Direction |
|---|---|---|
| `sw` | Swahili | LTR |
| `am` | Amharic | LTR |
| `ha` | Hausa | LTR |
| `yo` | Yoruba | LTR |
| `zu` | Zulu | LTR |

## RTL Support
Six languages require full Right-to-Left layout mirroring: **Arabic, Persian, Hebrew, Kurdish, Urdu**. Both Flutter and SvelteKit have first-class RTL capabilities. All UI components must use logical directional properties (`start`/`end`) instead of hardcoded `left`/`right`.

## Implementation Strategy

### Flutter Apps (ExoTalk, Exonomy, RepubLet Lite, Exocracy Lite)
- Use Flutter's built-in `flutter_localizations` package with `.arb` files.
- Each app maintains its own `lib/l10n/` directory for domain-specific strings.
- Flutter auto-detects device locale and falls back to English.

### SvelteKit + Tauri Apps (RepubLet Web, Exocracy Web)
- Use `paraglide-js` (by Inlang) for compile-time i18n with zero runtime overhead.
- Each app maintains its own `messages/` directory for domain-specific strings.

### Shared Strings
A monorepo-level `l10n/` directory may house common universal strings ("Settings", "Cancel", "Submit") shared across all apps to prevent duplication of translation effort.
