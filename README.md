# FosterFrames v3.0 [Modernized]
**The Professional Enemy Tracking Suite for Turtle WoW.**

FosterFrames is a high-performance, DLL-enhanced unit frame addon designed for elite PvP. It leverages the modern C++ hooks of **SuperWOW** and **UnitXP** to provide data and features previously impossible in the 1.12.1 engine.

## 🚀 Pro Features
*   **Zone-Wide Radar (Network Effect):** If *one* person in your raid spots an enemy (via the 200yd combat log), they appear on *everyone's* frames instantly via Peer-to-Peer synchronization.
*   **DLL-Perfect Cast Bars:** 100% accurate casting data from **SuperWOW**, including latency, channeled spells, and grey-bordered "non-interruptible" indicators.
*   **Real-Time Health & Mana:** Actual numeric values (not percentages) powered by the **UnitXP** DLL.
*   **Smart Distance Sorting:** Automatically sorts the unit list by proximity, placing the nearest (and most dangerous) enemies at the top.
*   **CC Announcements:** Automatically alerts your team in `/say` and `/bg` when you are **Sapped** or **Sheeped**.
*   **Battleground Optimization:**
    *   **AV Cap:** Automatically limits the display to 15 players in 40v40 matches to keep your screen clear.
    *   **Scoreboard Sync:** Strict synchronization removes players who leave the BG instantly, preventing "ghost" frames.
*   **Spec-Specific Icons:** Automatically detects and displays specialization icons (e.g., Shadow, Arms, Restoration) for instant target prioritization.
*   **Tactical WSG Suite:** Real-time health, distance tracking, and low-health alerts for Flag Carriers.

## 🛠️ Commands
*   `/ffs` - Open the Intuitive 4-Tab Settings Menu (General, Tactical, Automation, Appearance).
*   `/ffc` - Display current player list data and sync status.
*   `/ffd` - Debug mode for developers.

## 🖱️ Interaction
*   **Left-Click:** Target the enemy player.
*   **Right-Click:** Open the Raid Icon menu (Skull, Moon, etc.).
*   **Drag Frames:** Open settings (`/ffs`) and click **Unlock** in the General tab.

## 📦 Requirements
This addon is **DLL-Dependent**. You must have these in your Turtle WoW folder:
1.  **SuperWoW.dll** (Essential for casting, GUIDs, and 200yd scanning)
2.  **UnitXP_SP3.dll** (Essential for real health/mana values)
3.  **Nampower.dll** (Recommended for optimized communication)

---
*Developed for the Turtle WoW community to bridge the gap between classic gameplay and modern technical standards.*
