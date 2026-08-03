# Agent Skills local patches

Apply these patches from the root of the `jchidley/agent-skills` checkout.

```bash
patch_dir=/path/to/dotfiles/scripts/patches/agent-skills
for patch in "$patch_dir"/*.patch; do git apply --check "$patch"; done
for patch in "$patch_dir"/*.patch; do git apply "$patch"; done
```

Before updating an already patched checkout, remove the patches, update, and reapply them:

```bash
patch_dir=/path/to/dotfiles/scripts/patches/agent-skills
for patch in "$patch_dir"/*.patch; do git apply --reverse --check "$patch"; done
for patch in "$patch_dir"/*.patch; do git apply --reverse "$patch"; done
git pull --ff-only
for patch in "$patch_dir"/*.patch; do git apply --check "$patch"; done
for patch in "$patch_dir"/*.patch; do git apply "$patch"; done
```

If a check fails after updating, inspect whether upstream already contains the fix instead of forcing the patch.

`lat-skip-git-diff-outside-worktree.patch` prevents the Pi `lat` extension from running `git diff` when Pi's working directory is not inside a Git work tree. This avoids Git's noisy `--no-index` warning and usage output.
