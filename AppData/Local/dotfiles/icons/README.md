# Debian Terminal icon

`debian-official-swirl.png` is the exact 32×32 transparent icon originally used for Debian2. It is preserved here independently of any WSL installation directory. The old `C:\WSL\Debian2` copy disappeared when that test distro was removed.

## Attribution and license

Debian Open Use Logo (no-wordmark red swirl), Copyright © 1999 Software in the Public Interest, Inc.

- Guidance and attribution: https://www.debian.org/logos/
- Original, unchanged SVG: https://www.debian.org/logos/openlogo-nd.svg
- Upstream offers LGPL-3.0-or-later or CC-BY-SA-3.0. This copy and rendered PNG are provided under [Creative Commons Attribution-ShareAlike 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/), not the surrounding repository's license.
- The PNG transformation only scales and centers the logo on a transparent square with padding. It does not imply Debian endorsement.

## Reproduction and identity

The source and recipe were recovered from Pi session `01a06952-745b-76a3-a17c-66424d55d8a6`, which created the icon on 4 September 2026. On 5 September the official SVG was downloaded again, checked against that recorded source hash, rendered with the same recipe, and matched the historical PNG hash exactly. The PNG was also visually inspected.

| File | SHA-256 |
|---|---|
| `openlogo-nd.svg` | `89a3ca1a1bc91610edcc637457e7275a159309f4621829b2a0170e28970cac20` |
| `debian-official-swirl.png` | `96396037b9f3a834be452618d764afd7ecbde6b2ab9d421dc25e15447bea035d` |

Render with `@resvg/resvg-js` 2.6.2 and its matching platform binding. Base64-encode the SVG bytes and substitute them for `ENCODED` in this wrapper:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><image x="2" y="2" width="28" height="28" preserveAspectRatio="xMidYMid meet" href="data:image/svg+xml;base64,ENCODED"/></svg>
```

Use `new Resvg(wrapper, { background: 'rgba(0,0,0,0)' }).render().asPng()` and verify the output hash. No renderer dependency is needed to use the retained PNG.

On Windows, these assets deploy through chezmoi to `%LOCALAPPDATA%\dotfiles\icons`. They are excluded from Linux home deployment by the existing `AppData` ignore rule. The Debian4 Terminal fragment references that stable Windows path, not a distro's VHDX directory.
