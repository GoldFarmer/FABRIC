# Nexus Mods BBCode

Nexus Mods listing bodies use BBCode, not Markdown. Keep repository metadata, such as the listing name and short description, in Markdown; use BBCode only for the full listing body pasted into Nexus's rich-text editor.

## Supported authoring pattern

Use the conservative formatting subset below unless the Nexus editor preview confirms another tag works:

```bbcode
[size=4][b]Section heading[/b][/size]
[b]Emphasis[/b]
[color=#D4D4D8]Secondary text[/color]
[list]
[*]Bullet
[/list]
[list=1]
[*]Ordered step
[/list]
[url=https://example.com]Link label[/url]
```

Do not use Markdown headings, emphasis, links, tables, backticks, or fenced code blocks in the text pasted into Nexus. Represent comparison tables as short labeled lists instead; this is more portable in Nexus's BBCode editor and easier to read on narrow layouts.

## Listing structure

Keep the short description separate from the full listing body. State the player-facing purpose first, then installation, features, requirements, related mods and credits, and acknowledgements. Distinguish required dependencies from optional integrations. Link each referenced mod to its Nexus page and each credited author to their Nexus profile.

## Validation

Count the plain short-description text against Nexus's current character limit; markup is not part of that field. Before publishing, paste the body into Nexus's editor and use its preview to verify headings, lists, and links. Re-check third-party mod names, authors, links, and compatibility statements against their current official Nexus pages before release.
