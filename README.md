# CharacterPlannerExport

CharacterPlannerExport saves WoW: Forever character, inventory, and quest data for
the Character Planner Tool in the [version 1 format](SCHEMA.md).

Part of [Character Planner](https://github.com/thechainercygnus/character-planner):
the planner imports this file to see what the Battle.net API doesn't show.

## Install

Copy the inner **CharacterPlannerExport** folder into the client's AddOns
directory, then restart the game or run /reload. From the shared AddOns
development folder, you can also run:

    .\Install-DevelopmentAddOn.ps1 CharacterPlannerExport

## Export character data

Log in with the addon enabled to capture your character, bags, and quest log.
Visit your personal bank to capture its contents. The addon retains that bank
snapshot until it can read the bank again.

Log out, exit the game normally, or run `/reload` to write the export. Upload
the character's `SavedVariables\CharacterPlannerExport.lua` from their folder
under `_forever_\WTF\Account\<ACCOUNT>\91\` to the planner.

## Layout

The inner CharacterPlannerExport folder contains the TOC and Lua files
installed in the game. Repository documentation lives at the root.

## License

[MIT](LICENSE). World of Warcraft names and game data belong to Blizzard
Entertainment. This project isn't affiliated with or endorsed by Blizzard.
