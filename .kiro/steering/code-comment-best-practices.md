---
inclusion: always
---

# FABRIC Code Comment Best Practices

Comments explain intent, constraints, and non-obvious consequences. Code should explain mechanics through clear names, small functions, and direct control flow.

## Write comments when they add durable value

Comment:

- a game, Equipment-EX, or WEAVE behavior that is surprising or version-sensitive;
- a deliberate trade-off, invariant, safety check, or performance constraint;
- a workaround whose removal would otherwise seem obvious;
- a public API contract or a required ordering between operations;
- a non-obvious mapping between FABRIC state and game state.

Do not comment:

- a direct restatement of the next line;
- temporary implementation narration;
- obsolete investigation notes better kept in steering/specification artifacts;
- commented-out code. Remove it; version control preserves history.

## Style

- Prefer one short sentence immediately above the code it explains.
- State *why* and the expected consequence, not merely *what* the code does.
- Use complete, specific language. Avoid “hack”, “TODO”, “magic”, and unexplained acronyms.
- Keep comments accurate when changing adjacent behavior; stale comments are defects.
- Do not put task information in implementation source: comments and docstrings must not reference task numbers, task titles, task status, specification phases, or task-list identifiers. Describe the durable implementation reason instead; planning traceability belongs only in the specification, task list, commit history, or review notes.
- Keep REDscript source lines at or below the project's 120-character width. Split long expressions and messages at a logical boundary rather than hiding behavior in an abbreviated name.

## API docstrings

Every class and function must have a docstring immediately above its declaration. Keep it proportionate for small private helpers, but make the contract complete:

- Classes: state the class’s purpose, its owner/lifecycle, and the important invariants or dependencies it maintains.
- Functions: state the purpose, how the implementation achieves it at the relevant level, every parameter and its meaning, the return value (including safe-default behavior), and errors, failure conditions, or side effects.
- Explicitly say `None` for parameters, return value, or errors where applicable; do not leave a reader to infer that a category was considered.
- Document public APIs in enough detail for an adapter or another module to call them without reading the implementation. For private helpers, document the invariant they preserve and any non-obvious preconditions.

Use a compact doc-comment form appropriate to the language, for example:

```redscript
/**
 * Rebuilds the usage cache from Equipment-EX saved outfits.
 *
 * Iterates OutfitSystem once, retaining complete ItemIDs in hash buckets so a hash collision cannot
 * become an identity match.
 *
 * @param None.
 * @return None; replaces the in-memory cache on success.
 * @errors If OutfitSystem is unavailable, leaves an empty cache and emits a diagnostic.
 */
public func RebuildFull() {
```
- Do not use comments to compensate for unclear naming or oversized functions—improve the code first.

## FABRIC-specific requirements

- Document every dependency-sensitive hook with the target class/method and the behavior verified by the relevant steering artifact.
- Explain why `ItemID` must be treated as complete identity (including `rng_seed`) whenever code derives or uses association keys. If using `GetCombinedHash()`, state that it is only the map-key implementation detail and that the full ID remains available for equality/diagnostics.
- Explain that FABRIC performs an authoritative full rebuild after supported mutation boundaries because the available hook does not provide a reliable per-outfit payload. Do not describe snapshot or incremental mutation behavior unless that architecture is deliberately reintroduced.
- When handling WEAVE, document that rename is add-then-delete and that sync-restored references can lose per-instance precision.
- Document UI hot paths that must remain O(1), especially marker refreshes. Never leave an outfit scan in an item-render path without an explicit, exceptional justification.
- Document each fallback or safe-disable path with the observable behavior and diagnostic action.

## TODO and FIXME policy

- Use `TODO(owner or issue):` only for a concrete, externally tracked follow-up.
- Use `FIXME(issue):` only for a known defect with a defined failure mode.
- Each TODO/FIXME must identify the trigger for removal or resolution.
- Do not add a TODO when the work is already represented by a task in `.kiro/specs/fabric-mod/tasks.md`; leave no source comment for it. Source comments must not link to or otherwise reference task numbers.

## Examples

```redscript
// UI refreshes are O(1): the association index is maintained by authoritative full rebuilds.
let count = FabricService.Get().GetUsageCount(itemID);

// WEAVE synchronization is refreshed at FABRIC's next supported rebuild boundary.
```

```powershell
# Refuse an arbitrary directory so development install cannot copy scripts outside a valid game root.
if (-not (Test-Path -LiteralPath $gameExecutable)) { throw 'Invalid game root.' }
```
