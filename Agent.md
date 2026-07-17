# Agent Notes

## Version Releases

Do not update package versions and installation snippets by hand. Run the
repository release helper from the root instead:

```powershell
.\scripts\update-version.ps1 <x.x.x>
```

For a normal patch release, the script updates `moon.mod`, all current
installation examples, creates the next `docs/changes/<release>(<version>).md`,
and adds it to `docs/changes/index.md`. Review and replace any generated `TODO`
entries in the release note before committing.

For a major or minor package-version change, supply the public release number
explicitly so it is not inferred:

```powershell
.\scripts\update-version.ps1 <x.x.x> -ReleaseVersion <x.x.x>
```

Use `-WhatIf` to preview the target files. Pass `-Change`, `-Verification`,
and `-Note` to populate release-note sections directly. Validate the edited
repository before committing with a `gitmoji + short desc` message.
