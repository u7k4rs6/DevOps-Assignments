# Git / GitHub Assignment

**Name:** Utkarsh Bahuguna &nbsp;&nbsp;**Enrollment Number:** 10161

Both tasks were run in throwaway repositories; the transcripts below are the real terminal output. Raw logs are in [`outputs/`](outputs/).

---

## Task 1 — `git commit -a -m` vs `git commit -m`

### The concept

Git has three places a change can live: the **working tree** (your files), the **index / staging area** (what will go into the next commit), and the **repository** (committed history).

- `git commit -m "msg"` commits **whatever is already in the index** and nothing else. If you never ran `git add`, the index is empty and there is nothing to commit.
- `git commit -a -m "msg"` first stages **every modification and deletion of a file Git already tracks**, then commits.
- `-a` does **not** stage **untracked** files. Git has never seen them, so it has no prior version to compare against and will not guess that you want them.

### Case A — `git commit -m` with nothing staged

```bash
$ echo "change" >> file.txt      # modify a TRACKED file
$ echo "new" > newfile.txt       # create an UNTRACKED file

$ git status --short
 M file.txt
?? newfile.txt

$ git commit -m "Try without staging"
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   file.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	newfile.txt

no changes added to commit (use "git add" and/or "git commit -a")
```

Nothing was committed. The index was empty, so there was nothing to make a commit from.

Read the status codes: ` M` means modified in the working tree but **not** staged (the first column is the index, the second is the working tree). `??` means untracked.

### Case B — `git commit -a -m`

```bash
$ git commit -a -m "Auto-stage tracked changes"
[main 8a658b5] Auto-stage tracked changes
 1 file changed, 1 insertion(+)

$ git status --short
?? newfile.txt
```

`file.txt` was staged and committed in one step. **`newfile.txt` is still untracked** — `-a` skipped it entirely. The commit summary confirms it: `1 file changed`, not 2.

### Case C — an untracked file needs an explicit `git add`

```bash
$ git add newfile.txt && git commit -m "Add newfile"
[main a30101c] Add newfile
 1 file changed, 1 insertion(+)
 create mode 100644 newfile.txt

$ git status --short
  (clean)
```

Note `create mode 100644` — that line only appears when a file enters the repository for the first time.

### Case D — `-a` also stages deletions

```bash
$ rm newfile.txt
$ git status --short
 D newfile.txt

$ git commit -a -m "Remove newfile"
[main ada80ae] Remove newfile
 1 file changed, 1 deletion(-)
 delete mode 100644 newfile.txt
```

This is the part people usually miss: `-a` means "stage all changes to tracked files", and a deletion is a change. The file was removed from the repository without a single `git add` or `git rm`.

### Resulting history

```bash
$ git log --oneline
ada80ae Remove newfile
a30101c Add newfile
8a658b5 Auto-stage tracked changes
3ad5243 Initial commit
```

Four commits, and "Try without staging" is not among them — Case A really did commit nothing.

### Summary

| Command | Stages tracked modifications | Stages tracked deletions | Includes new / untracked files |
|---|---|---|---|
| `git commit -m "msg"` | No — index only | No | No |
| `git commit -a -m "msg"` | **Yes** | **Yes** | **No** |
| `git add . && git commit -m "msg"` | Yes | Yes | **Yes** |

**Practical rule:** `-a` is a convenience for the common "I edited files that already exist" case. The moment you add a new file, you need `git add`. Using `git add -A` (or `git add .`) followed by `git commit` is the habit that never surprises you.

Full log: [`outputs/03-commit-flags.txt`](outputs/03-commit-flags.txt)

---

## Task 2 — Git Cherry-Pick

### The concept

**Cherry-picking copies the *change* introduced by one commit and replays it on your current branch.** It does not merge a branch and it does not bring along the commits before it. The result is a **new commit with a new hash** carrying the same diff.

Because it replays a diff, cherry-pick can conflict exactly like a merge can — and it will, whenever the commit's changes depend on something that is not on your branch. Both outcomes are demonstrated below.

### Setup

```bash
$ mkdir git-practice && cd git-practice && git init -b main
```

Four commits on `main`:

```bash
$ git log --oneline
e7491fb Add main feature
61c3552 Add line 3
1f2fbb8 Add line 2
2d25256 Initial commit
```

Three more on a `feature` branch:

```bash
$ git switch -c feature
Switched to a new branch 'feature'

$ git log --oneline
e54aab7 Feature commit 3: hotfix in file.txt
f194c1f Feature commit 2: extend feature.txt
70f8e06 Feature commit 1: create feature.txt
e7491fb Add main feature
61c3552 Add line 3
1f2fbb8 Add line 2
2d25256 Initial commit
```

The two feature commits are deliberately different in kind:

- **Feature commit 3** edits `file.txt`, which already exists on `main`.
- **Feature commit 2** edits `feature.txt`, which was *created* by Feature commit 1 and therefore does **not** exist on `main`.

### Scenario A — a clean cherry-pick

Pick `e54aab7` ("Feature commit 3"). It touches a file that exists on `main`, so the patch applies cleanly.

```bash
$ git switch main
Switched to branch 'main'

$ ls
file.txt
main.txt

$ git cherry-pick e54aab7
[main e653f26] Feature commit 3: hotfix in file.txt
 Date: Sat Sep 5 15:00:00 2026 +0530
 1 file changed, 1 insertion(+)

$ cat file.txt
Hello
Line 2
Line 3
Hotfix line

$ git log --oneline -3
e653f26 Feature commit 3: hotfix in file.txt
e7491fb Add main feature
61c3552 Add line 3
```

The hotfix is now on `main` as commit `e653f26`, while the original on `feature` is still `e54aab7`. **Different hash, same change** — and notice Git preserved the original *author date* (`Sat Sep 5 15:00:00`) while giving the commit a new committer date.

### Scenario B — a cherry-pick that conflicts

Now pick `f194c1f` ("Feature commit 2"). That commit *modifies* `feature.txt`, but on `main` that file does not exist, because Feature commit 1 was never picked.

```bash
$ git cherry-pick f194c1f
CONFLICT (modify/delete): feature.txt deleted in HEAD and modified in f194c1f (Feature commit 2: extend feature.txt).  Version f194c1f (Feature commit 2: extend feature.txt) of feature.txt left in tree.
error: could not apply f194c1f... Feature commit 2: extend feature.txt
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git cherry-pick --continue".
hint: You can instead skip this commit with "git cherry-pick --skip".
hint: To abort and get back to the state before "git cherry-pick",
hint: run "git cherry-pick --abort".
```

**This is the expected result, not a mistake.** It is the single most important thing to understand about cherry-picking: a commit is a *diff against its own parent*, and if that parent context is missing on the target branch, Git cannot apply it silently.

A `modify/delete` conflict specifically means: one side changed the file, the other side does not have it. From `main`'s point of view, `feature.txt` "does not exist", which Git expresses as "deleted in HEAD".

```bash
$ git status --short
DU feature.txt
```

`DU` = **D**eleted by us, **U**pdated by them — the two-letter conflict code for exactly this situation.

### Resolving it

Git already left the incoming version on disk, so accepting it just means staging the file and continuing:

```bash
$ cat feature.txt          # git left the incoming version in the tree
Feature 1
Feature 2

$ git add feature.txt
$ git cherry-pick --continue --no-edit
[main 05627df] Feature commit 2: extend feature.txt
 Date: Sat Sep 5 15:00:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 feature.txt
```

Note `2 insertions(+)` here versus `1 insertion(+)` in the original commit: on `feature` this commit only added the second line, but on `main` it had to bring the whole file, because line 1 came from the commit we did not pick.

### Verification

```bash
$ git log --oneline --graph --all
* e54aab7 Feature commit 3: hotfix in file.txt
* f194c1f Feature commit 2: extend feature.txt
* 70f8e06 Feature commit 1: create feature.txt
| * 05627df Feature commit 2: extend feature.txt
| * e653f26 Feature commit 3: hotfix in file.txt
|/
* e7491fb Add main feature
* 61c3552 Add line 3
* 1f2fbb8 Add line 2
* 2d25256 Initial commit

$ ls
feature.txt  file.txt  main.txt

$ cat feature.txt
Feature 1
Feature 2
```

The graph shows the divergence clearly: the two picked commits exist **twice**, once on each branch, with different hashes. `Feature commit 1` was never brought over — cherry-pick takes only what you name.

| | original (on `feature`) | cherry-picked copy (on `main`) |
|---|---|---|
| Feature commit 3 | `e54aab7` | `e653f26` |
| Feature commit 2 | `f194c1f` | `05627df` |
| Feature commit 1 | `70f8e06` | *not picked* |

### Useful cherry-pick options

```bash
git cherry-pick <hash1> <hash2>   # several commits, in the order given
git cherry-pick <hash1>..<hash2>  # a range, EXCLUDING hash1
git cherry-pick <hash1>^..<hash2> # a range, INCLUDING hash1
git cherry-pick -n <hash>         # apply to the working tree but do not commit
git cherry-pick -x <hash>         # append "(cherry picked from commit ...)" to the message
git cherry-pick --continue        # after resolving a conflict
git cherry-pick --skip            # drop this commit and move to the next
git cherry-pick --abort           # undo everything, return to the pre-pick state
```

`-x` is worth knowing: it records the source hash in the message, so months later you can tell where a duplicated commit came from.

### When to cherry-pick — and when not to

**Use it for:** backporting a single hotfix to a release branch; recovering one commit from a branch you are otherwise abandoning; moving a commit made on the wrong branch.

**Avoid it for:** moving many commits (rebase or merge instead). Cherry-picking duplicates history, and duplicated commits confuse later merges — Git sees two commits with the same content but different identities and may replay the conflict all over again.

Full log: [`outputs/03-cherry-pick.txt`](outputs/03-cherry-pick.txt)

---

**Previous:** [Shell Scripting](../Shell%20Scripting/README.md) · **Next:** [Network Fundamentals](../Networking/README.md) · [Back to index](../README.md)

*Utkarsh Bahuguna · 10161*
