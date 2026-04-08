# Publishing for GitHub

## What goes where

| Content | Git repo (`git push`) | GitHub **Releases** (binary) |
|--------|------------------------|-------------------------------|
| Swift sources, Xcode project, `README`, `LICENSE`, `ss/` screenshots | yes | no |
| `build/EnvSwitch.dmg` | **no** (gitignored) | **yes** — upload as release attachment |

Maintainer-specific signing data stays **local** (keychain + `export CODESIGN_IDENTITY=…` when running `scripts/package-dmg.sh`). The **signed app/DMG** embeds Apple’s usual code-signing metadata; that is normal for binaries and is not the same as committing an email into `README`.

## Pre-built DMG expectations

Unless a release explicitly says otherwise, treat uploaded **`EnvSwitch.dmg`** files as **not notarized** and **not stapled**. Say so in the release notes (template below). For the fewest Gatekeeper prompts on strangers’ Macs, the maintainer would use **Developer ID Application**, **notarize** with Apple, and **staple**—then update the release notes to match.

## One-time: push the open-source tree

From the repository root:

```bash
cd /path/to/EnvSwitch

# Optional: delete local build output (can contain absolute paths from the build machine)
rm -rf build

git config user.name "Your Name"
git config user.email "your-email@example.com"

git init -b main
git add .
git status   # must NOT list build/, xcuserdata/, or a committed .dmg
git commit -m "Initial open-source import"
```

Create an **empty** GitHub repository (no auto-generated README if this tree should be the only first commit), then:

```bash
git remote add origin https://github.com/<username>/EnvSwitch.git
git push -u origin main
```

**GitHub CLI** alternative:

```bash
gh auth login
gh repo create EnvSwitch --public --source=. --remote=origin --push
```

## Produce `build/EnvSwitch.dmg` (when a new binary is needed)

Needs Xcode and [`create-dmg`](https://github.com/create-dmg/create-dmg) (`brew install create-dmg`).

```bash
export CODESIGN_IDENTITY="Developer ID Application: Full Name On Certificate (TEAMID)"
# or Apple Development for testing; or SKIP_CODESIGN=1 for unsigned

SKIP_DMG_FINDER_LAYOUT=1 bash ./scripts/package-dmg.sh
```

Output: **`build/EnvSwitch.dmg`**. If a DMG from a previous run is still the correct binary, **skip this step** and upload that file.

## GitHub Release + attach the DMG

```bash
export TAG=v0.1.0
export GITHUB_USER=your-github-username

gh release create "$TAG" \
  --repo "$GITHUB_USER/EnvSwitch" \
  --title "EnvSwitch $TAG" \
  --notes "## EnvSwitch $TAG

### Disk image
- **File:** \`EnvSwitch.dmg\` (attached)
- **Notarization:** This build is **not** Apple-notarized / **not** stapled unless explicitly stated elsewhere. Expect possible Gatekeeper prompts; see README **Download**.

### Source
GPL-3.0-only — see \`LICENSE\` in the repository.

### System requirements
- macOS 14+
" \
  build/EnvSwitch.dmg
```

Without `gh`: create the release on github.com, paste the same notes, attach `build/EnvSwitch.dmg`.
