# WoW Classic Hardcore Addons

Collection of addons created and updated by and for myself, compatible with Classic Hardcore 1.15.8.

All addons are provided "as is", without warranty of any kind. I do not claim ownership of the original code for the addons located in the `Updated Addons` folder. Original authors are credited via links to their respective project pages, and all modifications are strictly documented below.

---

## 🛠️ Created Addons

* **BNFriendsToggle**
    Adds a button in the friend list to toggle the display of Battle.net friends on or off.
* **CPArmor**
    Adds a small text indicator on the top left of the character panel to show armor and % physical damage reduction. Eliminates the need to open the defense tab for this specific metric.
* **DCAlert**
    Provides a warning when the client loses server connection.
* **DynamicTooltip**
    Anchors the tooltip to the cursor and replaces it by default during combat. Fixes tooltip lingering when slowly hovering and holding left-click to move the camera.
* **LanguageSwapper**
    Creates a button in the character panel to smoothly swap between known languages.
* **RDH (RaidDispelHighlight)**
    Highlights the victim's raid frame with a pulse when a dispelable debuff is applied.
* **SSB (SoulSeeker Begone)**
    Removes the occasional "-Soulseeker" suffix from player nicknames in the chat, reducing visual clutter specific to the HC environment.
* **CategoryChecker**
    Checks if an item has a category cooldown (i.e. potions) and if so shows it in the tooltip.

---

## 🔄 Updated Addons (Forks)

### [TheoryCraftClassic](https://www.curseforge.com/wow/addons/theorycraftclassic)
> *"Tells you everything about an ability, right on the tooltip."*

**Implemented Fixes:**
* Fixed the addon failing to initialize.
* Fixed missing values in the grimoire.
* Fixed outdated talent auto-detection.
* Fixed the `totalmana` Lua error.
* Fixed inconsistent HPS/DPS detection.
* Fixed the "-1000 sec" cast time display bug for certain instant cast spells.
* Fixed real-time updating for spell numbers on the UI.

### [Talented Classic](https://www.curseforge.com/wow/addons/talented-classic)
> *"A replacement talent UI that allows creation and application of templates for any class, and viewing of all talent trees in one window."*

**Implemented Fixes:**
* Fixed the inability to swap talents when dual spec is usable.

### [Account Wide Raid Profiles](https://www.curseforge.com/wow/addons/account-wide-raid-profiles)
> *"Make blizzard raid profile settings account-wide."*

**Implemented Fixes:**
* Retroported the addon to work on the classic version of the game.
* Removed the libs dependencies.
* Removed the GUI. (Use `/awrp store`, `/awrp restore` and `/awrp status` to use the addon).
* Added a global variable to store the profiles account-wide.

---

## 📄 License

* The original addons located in the `Created Addons/` folder are released under the **MIT License**.
* The modified addons located in the `Updated Addons/` folder remain under the respective original licenses of their authors (e.g., zlib/libpng). Please refer to the source files and the original project pages for more details.
