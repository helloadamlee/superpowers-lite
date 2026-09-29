# Superpowers Lite 6.4.1

A lean Codex-native release with explicit model routing, proportional workflows,
and reproducible validation.

- Standard implementation now uses **GPT-6.1 Sol at high effort** through the
  stable `superpowers_terra_implementer` role. Mechanical work uses GPT-5.6 Luna at
  medium effort; frontier implementation and fresh independent review use GPT-6
  Astra at high effort.
- Direct and Light workflows honor existing authorization and normally stay in the
  controller. Full work uses persisted design and planning, with delegation and
  independent review where required.
- Verification and review scale to risk: per-task independent review is reserved
  for explicit high-risk boundaries, mechanical fixes need static evidence, and
  substantive fixes use scoped verification and at most one scoped re-review.
- Supported platforms and CI are **Linux and Windows PowerShell 7**. The existing
  PowerShell implementation remains; Windows PowerShell 5.1 is outside the support
  matrix.
- CI uses canonical Codex validators pinned to revision
  `c1f1467f3028bd433c8f2063ecc28dd5be206df6`. The plugin README documents the same
  reproducible setup through `CODEX_VALIDATOR_ROOT`.

## Upgrade

Update the plugin and reinstall its four custom roles. The installer refuses to
overwrite differing files, including roles from a previous release. Back up and
review only the four Superpowers TOML files, preserve local customizations, move
those exact installed files aside, then rerun the installer and its check. Never
delete your agents directory. Start a new Codex task afterward.

See the [POSIX and PowerShell 7 upgrade steps](plugins/superpowers/README.md#upgrade-existing-roles)
and [developer validator setup](plugins/superpowers/README.md#development-checks).
The [workflow changes](CHANGES.md) describe the current policy in more detail.
