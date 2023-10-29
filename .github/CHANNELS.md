`master`

The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things.

`dev`

The latest fully-tested build. Usually functional, but see Bad Builds for a list of known "bad" dev builds. We continually try to roll master to dev. Doing so involves running many more tests than those that we run during master development, which is why this is not the same to master.

`beta`

Every month, we pick the "best" dev build of the previous month or so, and promote it to beta. These builds have been tested.

`stable`

When we believe we have a particularly useful build, we promote it to the stable channel. We intend to do this more or less every quarter, but this may vary. We recommend that you use this channel for all production app releases. We may ship hotfixes to the stable channel for high-priority bugs, although we intend to do this rarely.
