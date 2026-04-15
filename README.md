# FosterFrames v3.1 [DLL-Enhanced]

FosterFrames is a high-performance, minimalist unit frame suite designed for competitive PvP on Turtle WoW. It is built strictly for **Lua 5.0** and requires **SuperWOW** and **UnitXP** to function. By offloading data processing to C++ hooks, FosterFrames provides real-time enemy tracking and specialized features impossible with the standard 1.12.1 API.

## Core Mandates
- **Performance First:** Minimal CPU overhead; updates are throttled and event-driven.
- **DLL Driven:** Relies on SuperWOW for GUID-based unit tracking and UnitXP for precise health/power data.
- **PvP Focused:** Automated visibility in Battlegrounds and advanced CC/Trinket detection.

## Key Features

### 1. DLL-Enhanced Unit Frames
- **SmoothBar Tech:** Fluid health and mana transitions (supports Rage, Energy, and Mana).
- **Precise Data:** Leverages UnitXP for exact health values and power updates without unit-throttling.
- **Spec Detection:** Dynamic Spec-specific icons via SuperWOW hooks.

### 2. Battleground Intelligence
- **Auto-Sync:** Frames automatically populate/depopulate based on the Battleground scoreboard.
- **EFC Tracking:** Integrated Warsong Gulch Flag Carrier tracking with distance estimates (<10yd to 30yd).
- **Hard-Coded Visibility:** Frames are guaranteed to show in BGs (WSG, AB, AV, etc.) regardless of global settings.
- **AV Support:** Optimized for 40-man Alterac Valley with Smart Distance Sorting.

### 3. Combat Awareness
- **Integrated Castbars:** High-precision enemy castbars on both the unit frames and the default TargetFrame.
- **Trinket Detection:** Visual cooldown tracking for enemy PvP Insignias.
- **CC Announcement:** Automated "SAY" and "BATTLEGROUND" announcements when the player is Sapped or Polymorphed.
- **World Scanning:** (SuperWOW) Scans combat logs for hidden enemy units and broadcasts spotted targets to your group.

### 4. Customization & UI
- **Flexible Layouts:** Block, Vertical, and Horizontal layouts with adjustable group sizes.
- **Raid Targeting:** Integrated custom Raid Target menu (Right-Click) and on-screen RT announcements.
- **Settings GUI:** Modern settings menu for scale, layout, and feature toggles.

## Slash Commands
- `/ffs` or `/fosterframes`: Open the Settings menu.
- `/ffd`: Access debug tools (Player data, CC testing).
- `/ffc`: Access core logic status and dependency checks.

## Technical Dependencies
- **SuperWOW.dll:** Required for GUID tracking, spell casting info, and spec detection.
- **UnitXP_SP3.dll:** Required for high-precision health and smooth status bar updates.
- **Nampower (Optional):** Enhanced communication and packet handling.

---
*Note: This addon is designed for the 1.12.1 (Turtle WoW) client. Ensure your DLLs are up to date to avoid FrameXML errors.*
