# CLAUDE.md

Instructions for AI coding agents working in this repo.

## What this is

A WoW: Forever addon (Lua 5.1, interface 16001) that writes character, bag, bank and
quest data to `CharacterPlannerExportDB` (SavedVariablesPerCharacter) for the Character
Planner (`thechainercygnus/character-planner`, checked out at `D:\WoW\character-planner`)
to import. The game files are in `CharacterPlannerExport/`; repo docs at the root.

## Commands

No build or automated tests. To try a change in game:

```
..\Install-DevelopmentAddOn.ps1 CharacterPlannerExport
```

Then `/reload` in game, log out or `/reload` again to write the file, and read
`_forever_\WTF\Account\<ACCOUNT>\91\<Character>\SavedVariables\CharacterPlannerExport.lua`.

Release: bump `## Version:` in the TOC (the export's `addonVersion` reads it from there)
in a PR; the user tags `vX.Y.Z` on `main`, and `release.yml` publishes
`CharacterPlannerExport.zip`.

## Rules

- `SCHEMA.md` is the contract with the planner's parser; the planner holds the
  authoritative copy. Never change the shape of schema version 1. A breaking change is a
  new `schemaVersion`, agreed with the planner first, with its parser updated too.
- The Forever API is undocumented. Only call functions confirmed to exist in a
  ForeverAPIExplorer capture, guard optional ones, and say when you're assuming.
- Export only what the planner needs. Don't add new personal data (GUIDs, account names,
  chat, other players) to the file.
- SavedVariables are written only on logout, `/reload` or exit. Keep the bank snapshot when
  the bank isn't open; never replace it with an empty table.
- Never commit SavedVariables files or captures: they hold character data.
- Commits and pushes need the user's go-ahead. Work on a branch.
