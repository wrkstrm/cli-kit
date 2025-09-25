# Toolbox

A command line tool.

## Random strings and emoji

Generate random characters:

```bash
swift run --package-path code/mono/apple/spm/clis/cli-kit swift-cli-kit random --length 6 --kind ascii
```

Generate a random emoji from curated sets (status, momentum, work, conventions/all):

```bash
swift run --package-path code/mono/apple/spm/clis/cli-kit swift-cli-kit random \
  --kind emoji --category conventions --length 1
```
