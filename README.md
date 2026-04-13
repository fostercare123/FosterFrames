# FosterFrames v3.0 [Modernized]
Optimized for Turtle WoW (SuperWOW / UnitXP)

## Overview
FosterFrames is a high-performance enemy tracking and unit frame addon designed primarily for Battlegrounds, now enhanced with Open World discovery. It provides a strategic overview of enemy players, their health, resources, and casting states.

## Key Features
*   **Real-Time Enemy List:** Automatically populates with enemies in Battlegrounds (via Scoreboard) and Open World (via Combat Log discovery).
*   **SuperWOW Casting System:** Utilizes DLL-injected functions for 100% accurate cast bars for Target and Mouseover units, including latency and interruptibility.
*   **UnitXP Integration:** Displays actual Health and Mana values instead of percentages, leveraging real-time data from the UnitXP DLL.
*   **Tactical Cast Bars:** Visual indicators for non-interruptible spells (Grey border) and accurate timers.
*   **WSG Support:** Specialized tracking for Flag Carriers, including health updates and proximity alerts.
*   **Raid Targeting:** Integrated menu for quickly assigning and announcing Raid Icons to enemy players.

## Modernization (v3.0)
*   **Removed Legacy Code:** All manual "best-guess" combat log parsing for casts and buffs has been stripped out.
*   **Optimized Performance:** Drastically reduced CPU overhead by removing dozens of redundant event listeners and massive legacy spell databases.
*   **Clean Slate:** Reset saved variables and legacy architecture to function as a modern, DLL-dependent addon.

## Controls
*   /ffs - Open Settings Menu
*   /ffd - Debug Mode
*   Left-Click: Target Player
*   Right-Click: Open Raid Icon Menu
