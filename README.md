<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
<img src="https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge"/>

# 🌿 Green Algeria — الجزائر خضراء

**تطبيق جزائري لإعادة التشجير وتتبع الأشجار بشكل جماعي**

*Together we build a greener Algeria — معاً نصنع الفرق*

[![Version](https://img.shields.io/badge/Version-v3.6.5-606C38?style=flat-square)](https://github.com/sam22ir/Green-algeria)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-5A7233?style=flat-square)](https://github.com/sam22ir/Green-algeria)
[![Language](https://img.shields.io/badge/Language-Arabic%20%7C%20English-2D2D2D?style=flat-square)](https://github.com/sam22ir/Green-algeria)

</div>

---

## 📖 About the Project

**Green Algeria** is a national environmental initiative built as a Flutter application to empower Algerian volunteers to document tree planting, join national and provincial campaigns, and collectively track Algeria's reforestation progress.

The app covers all **69 Algerian Wilayas**, supports full **Arabic (RTL)** and English localization, and works **offline** — no internet connection required to plant a tree.

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🗺️ **Interactive Map** | Plant trees directly on an OpenStreetMap-powered map of Algeria |
| 🌳 **Tree Documentation** | Record species, location, and date of every planting |
| 📣 **Campaign System** | Join national, provincial, and local reforestation campaigns |
| 🏆 **Leaderboard** | Compete with volunteers across all 69 wilayas |
| 🔔 **Push Notifications** | Real-time FCM alerts for campaigns and national events |
| 📶 **Offline Mode** | Queue plantings locally — auto-syncs when back online |
| 🌙 **Dark Mode** | Full handcrafted dark theme (never auto-inverted) |
| 🌐 **Bilingual** | Arabic (RTL) + English (LTR) with easy_localization |
| 👥 **Role System** | Volunteer → Local Organizer → Provincial Organizer → Initiative Owner → Developer |
| 🛡️ **Admin Dashboard** | Role-adaptive dashboard for managing campaigns, users, and notifications |

---

## 🛠️ Tech Stack

```
Flutter (Stable)          → Cross-platform mobile & web framework
Supabase                  → PostgreSQL database + RLS + Realtime + Auth
Firebase (Auth + FCM)     → Google Sign-In + Push Notifications
flutter_map               → OpenStreetMap-based interactive maps
sqflite                   → Local SQLite for offline queue
easy_localization         → AR/EN translation system
GoRouter                  → Declarative navigation
```

---

## 🎨 Design System

The app uses a custom **Soft Organic Palette** — all colors are handcrafted design tokens:

| Token | Color | Usage |
|-------|-------|-------|
| `olive-grove` | `#606C38` | Primary buttons, active nav |
| `moss-forest` | `#5A7233` | Borders, deep elements |
| `linen-white` | `#FBFBF7` | App background |
| `slate-charcoal` | `#2D2D2D` | Headings |
| `olive-grey` | `#6B705C` | Secondary text |

All UI designs are created exclusively in **Google Stitch MCP** for design system consistency.

---

## 📱 App Screens

```
🔐 Auth          → Sign In · Sign Up (with Wilaya) · Forgot Password · Reset Password
🏠 Home          → Campaign Countdown · Live Tree Counter · Campaign Feed
🗺️ Map           → All tree pins · Campaign zones · GPS location
📣 Campaigns     → National · Provincial · Local Initiatives · Past Campaigns
🏆 Leaderboard   → Individual rankings · Province rankings · Public profiles
👤 Profile       → Stats · Planting history · Settings · Admin Dashboard
```

---

## 🗄️ Database Schema

All data lives in **Supabase** with **Row Level Security (RLS)** enabled on every table.

| Table | Purpose |
|-------|---------|
| `users` | Profiles, roles, provinces, FCM tokens |
| `planted_trees` | Every documented tree (GPS + species + planter) |
| `campaigns` | National / Provincial / Local campaigns |
| `tree_species` | 30+ species database (AR + EN + scientific) |
| `leaderboard_cache` | DB-trigger-refreshed rankings |
| `notifications` | Admin-sent push notifications |
| `upgrade_requests` | Volunteer → Organizer promotion requests |
| `bug_reports` | In-app problem reporting |

---

## 👥 Role Hierarchy

```
🔧 Developer (Saadi Samir)          → Full system access
🌟 Initiative Owner (Fouad Mo'alla) → National campaigns + notifications
🏛️ Provincial Organizer             → Province-level campaigns
📍 Local Organizer                  → Local / semi-individual campaigns
🌱 Volunteer (default)              → Plant trees + join campaigns
```

> ⚠️ Privileged roles are assigned **manually** via Supabase Dashboard only — never via the app.

---

## 🚀 Version History

| Version | Highlights |
|---------|-----------|
| v3.6.5 | Tree popup fixes · Stitch MCP redesigns · Notification tabs |
| v3.6 | Map fixes · Background notifications · Profile→Map navigation |
| v3.5 | Past campaigns screen · Arabic countdown units |
| v3.4 | Public profiles · Province detail · Notification history |
| v3.3 | Logo integration · Map zone interaction · ChoiceChip filters |
| v3.0 | Premium leaderboard redesign · Campaign termination |
| v2.1 | Admin dashboard · i18n system · Offline mode |

---

## 🔐 License & Intellectual Property

This project is **proprietary software**. See [LICENSE](./LICENSE) for full terms.

> **All rights reserved © 2026 Saadi Samir.**
> Redistribution, modification, or republication under a different name is strictly prohibited.

---

## 👨‍💻 Credits

<table>
  <tr>
    <td align="center">
      <b>Saadi Samir</b><br/>
      Developer & Architect<br/>
      <a href="https://github.com/sam22ir">@sam22ir</a> · <a href="https://instagram.com/sam__22__ir">Instagram</a>
    </td>
    <td align="center">
      <b>Fouad Mo'alla</b><br/>
      Initiative Owner<br/>
      <i>MabadaMedia</i>
    </td>
  </tr>
</table>

---

<div align="center">

*🌿 Green Algeria — الجزائر خضراء*
*Built with ❤️ using Google Antigravity IDE · Stitch MCP · Supabase MCP · Firebase MCP*

</div>
