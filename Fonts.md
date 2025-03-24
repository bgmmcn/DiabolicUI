# World of Warcraft WotLK Font Overview

This table provides an overview of the main font files used in the Wrath of the Lich King client, their typical replacements, and where they are used in the game interface.

| File Name      | Font Used (Replacement)          | Usage Description                                                         |
|----------------|----------------------------------|---------------------------------------------------------------------------|
| `ARIALN.TTF`   | *Noto Sans*                      | Standard text, often used as fallback (e.g., chat, tooltips).             |
| `FRIZQT__.TTF` | *Noto Serif*                     | Default font used for most UI text (dialogs, quest descriptions, etc.).   |
| `MORPHEUS.TTF` | *Exocet Blizzard OT Light*       | Used for zone intro and ambient messages (e.g., area names on maps).      |
| `skurri.ttf`   | *Exocet Blizzard OT Medium*      | Used for titles and stylized effects (e.g., damage numbers, headings).    |

## 🔧 Notes

- If you want to override default WoW fonts, create a `Fonts` folder in your main WoW directory and place your `.ttf` files there using **exact file names**.
- For example, to replace `FRIZQT__.TTF` with your own font:
- Rename your font file to `FRIZQT__.TTF`
- Place it in: `World of Warcraft\Fonts\`

> ⚠️ The names must match !
