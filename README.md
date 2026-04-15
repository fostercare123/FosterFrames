# FosterFrames v3.2 [Modernized]

FosterFrames is a high-performance, minimalist unit frame suite designed for competitive PvP on Turtle WoW. Refactored for **Lua 5.0**, it leverages a modern "Single Source of Truth" architecture and requires **SuperWOW** and **UnitXP** to function.

## Core Mandates
- **Performance First:** Optimized `OnUpdate` loops with cached dependency checks to ensure zero frame-rate impact during intense combat.
- **Low Coupling & High Cohesion:** A clean separation between data logic (`FosterFramesCore`) and visual representation (`FosterFrames.UI`).
- **Namespace Isolated:** All addon data is encapsulated within the `FosterFrames` global table to prevent collisions with other addons.

## Key Features

### 1. Modernized State Management
- **Single Source of Truth:** `playerList` is managed exclusively by the Core. UI components query data dynamically, eliminating memory leaks and data desyncs.
- **Dependency Caching:** SuperWOW and UnitXP detection is performed once at login and cached, removing expensive type-checks from the render path.

### 2. DLL-Enhanced Unit Frames
- **SmoothBar Tech:** Fluid health and mana transitions (supports Rage, Energy, and Mana).
- **Precise Data:** Leverages UnitXP for exact health values and power updates.
- **Spec Detection:** Dynamic Spec-specific icons via SuperWOW hooks.

### 3. Battleground Intelligence
- **Auto-Sync:** Frames automatically populate/depopulate based on the Battleground scoreboard.
- **EFC Tracking:** Integrated Warsong Gulch Flag Carrier tracking with distance estimates (<10yd to 30yd).
- **Hard-Coded Visibility:** Frames are guaranteed to show in BGs (WSG, AB, AV, etc.) regardless of global settings.
- **AV Support:** Optimized for 40-man Alterac Valley with Smart Distance Sorting.

### 4. Combat Awareness
- **Integrated Castbars:** High-precision enemy castbars on both the unit frames and the default TargetFrame.
- **Trinket Detection:** Visual cooldown tracking for enemy PvP Insignias.
- **CC Announcement:** Automated "SAY" and "BATTLEGROUND" announcements when the player is Sapped or Polymorphed.

## Slash Commands
- `/ffs` or `/fosterframes`: Open the Settings menu.
- `/ffd`: Access modernized debug tools (Direct Core data inspection).
- `/ffc`: Access core logic status and dependency checks.

## Technical Dependencies
- **SuperWOW.dll:** Required for GUID tracking, spell casting info, and spec detection.
- **UnitXP_SP3.dll:** Required for high-precision health and smooth status bar updates.
- **Nampower (Optional):** Enhanced communication and packet handling.

---
*Note: This addon is designed for the 1.12.1 (Turtle WoW) client. Ensure your DLLs are up to date to avoid FrameXML errors.*
