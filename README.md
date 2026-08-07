# Bug report assets

Diagnostic logs from in-app bug reports land here, committed by the report
relay under `logs/<year>/<month>/<timestamp>-<random>.jsonl.gz`. Each one is
linked from the issue it belongs to.

Nothing here is code and nothing builds from this branch, which is the point:
the relay authenticates with a GitHub App token narrowed to `contents: write`,
so keeping these commits off the default branch means a leaked token can only
ever reach a branch nobody ships from.

The branch has to exist before the first report — the Contents API commits to
an existing branch but will not create one.
