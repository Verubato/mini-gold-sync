# MiniGoldSync reference

## What it does

Keeps each character's gold at a target amount by automatically depositing to or
withdrawing from the warband (account) bank every time a bank window is opened. If
the character has more than the desired amount the excess is deposited; if it has
less, the difference is withdrawn from the warband bank. Per-character override
amounts and a per-character ignore flag are supported.

## Facts

| Item | Value |
| --- | --- |
| Version | 1.3.4 |
| Author | Verz |
| Interface versions (TOC) | 120100 (retail only: Midnight 12.1) |
| Saved variables | MiniGoldSyncDB |
| Slash commands | /minigoldsync, /minigold, /mgs, /mg (all open the settings panel) |
| Options location | Game options -> AddOns -> MiniGoldSync |
| Bundled libraries | MiniFramework only |
| External dependencies | None. Requires the warband bank (C_Bank API), hence retail only. |

## How the sync works

1. Fires on the BANKFRAME_OPENED event, i.e. whenever you open a bank.
2. If the current character is on the override list with Ignore checked, nothing
   happens ("Ignoring current character." is printed if messages are on).
3. The target is the character's override gold if the character is on the override
   list, otherwise the global Desired Gold value. Values are whole gold.
4. Difference = target - current gold. Positive: withdraws from the warband bank
   (capped at what the warband bank actually holds). Negative: deposits the excess.
   Zero: does nothing.
5. Withdrawals and deposits go through the account/warband bank money APIs. If the
   bank refuses (cannot withdraw/deposit) it reports failure.
6. With "Print chat messages" on, it prints the current gold, desired gold, and
   difference, then "Successfully synchronised gold." or "Failed to synchronise
   gold."

Character matching: an override row matches if its Character Name equals either the
character's plain name ("Name") or full "Name-Realm" form. The options panel
recommends including the server name but it is not required.

## Settings

Single scrollable options panel.

| Setting | Type | Default | Notes |
| --- | --- | --- | --- |
| Print chat messages | checkbox | on | Prints what happened at each bank visit. |
| Desired Gold | numeric edit box | 0 | Target gold for every character without an override. Whole gold, minimum 0, up to 12 digits. Committed on Enter or when the box loses focus. |
| Character Overrides | row grid | one empty row | Per-character rules, see below. |

### Character Overrides grid

Each row has:

| Column | Type | Default | Meaning |
| --- | --- | --- | --- |
| (X button) | remove button | - | Deletes the row. The first row cannot be deleted. |
| Ignore | checkbox | off | Skip this character entirely; its gold box is disabled while ignored. |
| Character Name | edit box (max 24 chars) | empty | "Name" or "Name-Server". |
| Override Gold | numeric edit box | 0 | Target gold for this character instead of Desired Gold. |

The "Add" button next to the first row appends a new row. Edits are committed on
Enter or when leaving the box.

There is no reset-to-defaults button; settings live in MiniGoldSyncDB.

## Version-gated behavior

- Retail 12.1 only per the TOC. There is no Classic support because the warband
  bank does not exist there.
- The settings panel cannot be opened during combat; the slash command prints
  "Can't do that during combat." instead.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| Nothing happens at the bank | The sync only runs when the bank frame opens. If the difference is 0 it does nothing. Check whether the character is on the override list with Ignore checked ("Ignoring current character." in chat). |
| "Failed to synchronise gold." | The warband bank refused the money operation: for a withdrawal, the account bank may not allow withdrawing (or holds no gold); for a deposit, depositing may not be allowed. A withdrawal of 0 (empty warband bank) also reports failure. |
| Character did not fill up to the target | Withdrawals are capped at what the warband bank holds; it withdraws what it can. |
| The chat message shows the wrong desired gold | Known quirk: the informational message always prints the global Desired Gold value even when a per-character override applies. The sync itself uses the override. |
| Override not applying | The Character Name must exactly match the character's name, either plain "Name" or "Name-Realm". Check spelling and that the row was committed (press Enter or click out of the box). |
| No chat messages at all | "Print chat messages" is unchecked. |
| Addon does not load on Classic | Expected: MiniGoldSync is retail-only. |
