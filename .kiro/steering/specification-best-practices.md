---
inclusion: always
---

# FABRIC Specification Best Practices

Keep the design, requirements, and task list current-state and implementation-focused. Record only the selected behavior, constraints, interfaces, acceptance criteria, and concrete file ownership needed to build or verify FABRIC. Do not preserve rejected approaches, experiment logs, or decision history in specification artifacts.

Do not use `tasks.md` as a session journal. Do not add dated progress notes, failed probes, discarded alternatives, conversational history, or a chronology of decisions there. A completed task should state the final implemented result and, where useful, the durable validation criterion.

Put reusable technical discoveries and constraints in the relevant steering file: language/compiler behavior in REDscript steering, game hook facts in vanilla steering, and third-party API facts in that dependency's steering. Keep third-party steering limited to that dependency and its own prerequisites; do not describe FABRIC or other dependents there.

## Dependency research versus FABRIC architecture

Per-mod steering folders are dependency research artifacts. Each file must describe only the named mod: its source layout, runtime behavior, public API, configuration, own prerequisites, and the concrete game hooks or fields that it adds. Do not place FABRIC behavior, FABRIC integration advice, FABRIC test plans, implementation choices, or claims about what FABRIC should infer from that mod in these folders.

### Hook and injection documentation standard

Do not document a hook as only a decorator, target class, or method name. For every material game hook, replacement, injected field, native extension, or event listener, explain:

1. **Trigger and host flow** — when the game invokes the target and what user/game action reaches it.
2. **Reason** — the mod feature that requires the interception or injected state.
3. **Behavior** — what the mod reads, changes, creates, suppresses, queues, or delegates to `wrappedMethod`.
4. **Resulting effect** — the observable state, UI, persistence, asset, or gameplay outcome.
5. **Scope and lifecycle** — relevant conditions, initialization/cleanup, virtualized-widget reuse, persistence, or version/module guards.

Group mechanically similar hooks when they implement one flow, but preserve enough detail to trace that flow from its trigger to its effect. Include source file and exact target method(s) when known. A target-only inventory is acceptable as an appendix, never as the whole explanation.

Cross-mod context belongs in `.kiro/specs/fabric-mod/`, not in dependency steering. Record FABRIC's selected dependency roles, compatibility boundaries, identity rules, hook choices, validation scenarios, fallbacks, and release claims in `design.md` and/or `requirements.md`; place actionable implementation and validation work in `tasks.md`.

Use this split when documenting a discovery:

| Information | Destination |
|---|---|
| A mod's `@wrapMethod` target, exported API, configuration setting, or runtime behavior | That mod's steering folder |
| A game-native API or controller behavior | `steering/vanilla/` |
| A language/compiler constraint | `steering/redscript/` |
| FABRIC's decision to use, avoid, combine, or validate one or more mods | `specs/fabric-mod/design.md` and/or `requirements.md` |
| Remaining FABRIC implementation or test work | `specs/fabric-mod/tasks.md` |

When a discovery changes the selected solution, update the design and requirements with the final decision, then update the task entry only with the concrete implementation work that remains or was completed. Use version control and review history for the investigation trail.
