# Homebrew Formula for pdrx

This directory contains the Homebrew formula so users can install pdrx (and the man page) with:

```bash
brew tap stefan-hacks/pdrx https://github.com/stefan-hacks/pdrx
brew install pdrx
```

## Updating the formula for a new release

1. Create and push a new tag (e.g. `v1.4.9`):
   ```bash
   git tag v1.4.9
   git push origin v1.4.9
   ```

2. Get the SHA256 of the new tarball:
   ```bash
   curl -sSL "https://github.com/stefan-hacks/pdrx/archive/refs/tags/v1.4.9.tar.gz" | shasum -a 256
   ```

3. Edit `Formula/pdrx.rb`: update the `url` version in the path, the `sha256` value, and the version in the `test do` block.

4. Commit and push the formula change.

## "Failed to download resource" when running brew install

This usually means the **Git tag** for the formula’s version does not exist on GitHub. The formula downloads `https://github.com/stefan-hacks/pdrx/archive/refs/tags/vX.Y.Z.tar.gz`, which only works if the tag `vX.Y.Z` has been pushed.

**Fix:** Create and push the tag (replace with the version in `Formula/pdrx.rb`):

```bash
git tag v1.4.8
git push origin v1.4.8
```

After the tag is on GitHub, `brew install pdrx` (and `brew upgrade pdrx`) will succeed.

Reference: [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap), [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook).
