# Release

Read before preparing a release or writing CHANGELOG.md.

## Steps

1. Changes merged into `main` via PRs.
2. Bump `version` in `mod.json` (and `requires.app` if new app features are
   used).
3. Add a `## <version>` section to `CHANGELOG.md` — short plain bullets,
   credit the authors (layout below).
4. Update README.md if NPCs, coordinates or credits changed.
5. The zip is built automatically by `.github/workflows/release.yml`:
   `standart-npc-<version>.zip`, files inside a `standart-npc/` folder,
   **without** README.md, assets/, CLAUDE.md, docs/, tools/, tests/, .git,
   .github, .gitattributes. To check the build before a release: Actions →
   "Build release zip" → Run workflow, then download the zip from the run's
   Artifacts. CHANGELOG.md ships in the zip; the workflow fails a release
   whose version has no `## <version>` section in it (only a warning on a
   manual run).
6. Before tagging: `node tests/play.cjs` passes in both eras (it makes the
   smoke checks too), tabs check, same version everywhere, README
   coordinates, credits.
7. Publish a GitHub release with tag and title `v<version>` (e.g. `v4.9.5`)
   and the CHANGELOG.md section as description. Don't attach the zip by
   hand: the workflow builds it and attaches it to the release. If the tag
   is not `v<version>` from mod.json, the workflow fails and attaches
   nothing.

## Collected release

When MondoTruth wants several fixes in one release: branch `<version>` from
`main`, task PRs `--base <version>`, one final PR to `main` with all
`Closes #N` (GitHub closes issues only on the merge into `main`;
delete_branch_on_merge is on). Otherwise task branches go straight to
`main`.

## CHANGELOG.md section layout

- Requirement lines on top (e.g. "Requires app 1.5.5").
- `### Renewal and Pre-renewal` for everything that applies to both, never
  repeated; then `### Renewal only` and/or `### Pre-renewal only` only when
  such items exist. Small era differences inside a shared item go inline,
  e.g. "(on Renewal)".
- Items not tested in game get "(Not tested in game yet.)" when MondoTruth
  says so.
- A `## Next version` heading (not a version, the app skips it) can collect
  lines for unreleased work; rename it to the real version on release.

## What the app's registry expects

Entry `registry/mods/standart-npc/mod.json` in the app repo points at our
releases, asset `standart-npc-*.zip`.

- Only a **full release** is offered to players (`releases/latest`); drafts
  and pre-releases never are — use a pre-release to test with a few people.
- Tags only go up; compared as dotted numbers.
- `requires.app` in the release's mod.json is checked before installing: a
  player on an older app keeps the old version and is told why. Raise it
  whenever we use something new in the app.
- Refused: zip over 50 MB, unpacked over 96 MB or 2000 files, links, `../`
  paths, a mod.json the app cannot read (unknown `requires` keys, bad
  settings).
- Players read the release notes on Settings → Mods → Updates ("What's
  new", a few lines and Show all; app 1.5.1). With
  Flux159/ragnarokoffline.app#437 they see the notes of every release the
  update skips, not only the latest — write them for players.

## Licence

MIT (`LICENSE`, PR #27). Exceptions are scripts based on rAthena's own
(`warper`, `jobmaster`, `resetnpc`, `stylist`): they stay GPL-3.0
(`LICENSE-GPL-3.0`) and say so in their header. A new script copied from
rAthena's `npc/` gets the same header line and an entry in `LICENSE`.
