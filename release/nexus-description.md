# FABRIC — Equipment-EX outfit markers

FABRIC shows which saved outfits use each clothing item. It adds a configurable marker to used item cards and lists the associated outfit names in the normal item tooltip.

FABRIC supports Equipment-EX Wardrobe, player Inventory and stash, and Virtual Atelier catalog cards. Owned cards use their exact item instance; catalog cards use the clothing record, so duplicate owned items are represented accurately while store listings remain useful.

## Requirements

- Cyberpunk 2077 with compatible REDscript and RED4ext installations
- Equipment-EX
- Codeware

Mod Settings is optional and provides controls for the marker icon, color, and corner. Without it, FABRIC uses the shipped defaults. WEAVE is optional; FABRIC refreshes its cache at supported game boundaries, but WEAVE does not currently provide a public event for immediate JSON-sync reconciliation.

## Installation

Extract the release ZIP into the Cyberpunk 2077 game directory.

No shared `r6\scripts\Logs.reds` file is required or included for the release build.

## Project links

- [Source code and documentation](https://github.com/GoldFarmer/FABRIC)
- [Report a bug or compatibility issue](https://github.com/GoldFarmer/FABRIC/issues)

Nexus hosts the release download.

## Development disclosure

FABRIC was developed using Kiro IDE with assistance from OpenAI Codex. AI was used as a coding and documentation collaborator for research, implementation drafts, and testing support. GoldFarmer directed the work, reviewed changes, and performed in-game validation.
