# Go Fetch!

A code fetcher Docker Container

## Usage:

### Fetch

Fetches a repo in the repo library at volume `test-repos` from a private github repo:

```
docker run --rm \
--volume test-repos:/repos \
icalialabs/go-fetch fetch \
--user [YOUR USERNAME] \
--password '[YOUR PASSWORD OR ACCESS TOKEN]' \
--github [YOUR GITHUB NAMESPACE]/[YOUR REPO PROJECT]
```

You can also prune removed branches from remote by using the `--prune` flag. Note also that public
github repos won't need `--user` nor `--password` options:

```
docker run --rm \
 --volume test-repos:/repos \
 icalialabs/go-fetch fetch \
 --prune \
 --github IcaliaLabs/go-fetch
```

**NOTE**: The credentials you provide to execute the fetch will be cleared from the git remote right
after the code is fetched. Go Fetch does not - nor will - store your credentials anywhere else. Be
warned, however, that the Docker engine may be logging every run, which can potentially include the
command arguments, so be careful!

### Checkout

Executes a checkout of a branch or commit from a fetched repo in the library at volume `test-repos`
into the volume `example-1`:

```
docker run --rm \
 --volume test-repos:/repos \
 --volume example-1:/example-1 \
 icalialabs/go-fetch checkout \
 --github IcaliaLabs/go-fetch \
 --treeish origin/master \
 example-1
```

You can also fetch the repo latest updates right before the checkout occurs by passing the `--fetch`
flag - You can use all of the `fetch` command options & flags:

```
docker run --rm \
 --volume test-repos:/repos \
 --volume example-1:/example-1 \
 icalialabs/go-fetch checkout \
 --fetch \
 --treeish 3bd425248451564c04e64d4bd2b9d8bb0e6b7f5c \
 --github IcaliaLabs/go-fetch example-1
```

Remember, on this and the next commands you only need to pass the user/password when *fetching* from
a private repo. This and the following commands won't fetch updates from the origin unless you send
the `--fetch` flag.

### List Files

You can get a list of the files in a particular revision or branch - by default, it will list the
files in `origin/master`:

```
docker run --rm \
 --volume test-repos:/repos \
 icalialabs/go-fetch list_files \
 --github IcaliaLabs/go-fetch \
 --treeish 6688d6fd62e0f97819b353f3fc3e91e61abf10bc
```

### Extract content

You can extract contents from a particular commit or branch by giving a list of locations. You can
specify a fragment by appending `:L2-L12` to each path to retrieve the lines 2 through 12:

```
docker run --rm \
 --volume test-repos:/repos \
 icalialabs/go-fetch extract \
 --treeish 6688d6fd62e0f97819b353f3fc3e91e61abf10bc \
 --github IcaliaLabs/go-fetch README.md LICENSE:L12-L13
```

## Why?

In one of our projects, which is deployed on a Docker Swarm on Azure environment, it was crucial to
us to be able to fetch code from our repos into persistent/replicated  Docker volumes - which makes
the fetched files available across the entire swarm via the cloudstor volume plugin - so we can pass
it into another process in our continuous integration pipeline:

```
# You can checkout the code from a repo directly into the example-4 volume:
docker run --rm \
-v test-repos:/repos \
-v example-4:/example-4 \
icalialabs/go-fetch checkout \
--fetch \
--github IcaliaLabs/go-fetch example-1 origin/master

# Now the code is ready on the example-4 volume, so we can run another tool like codeclimate:
docker run --rm \
--env CODECLIMATE_CODE=example-4 \
--env CODECLIMATE_TMP=/tmp \
--volume example-4:/code \
--volume /tmp:/tmp/cc \
--volume /var/run/docker.sock:/var/run/docker.sock \
codeclimate/codeclimate analyze -f json
```

Although we know the use case for which this app is intended is not a common one, we know for a fact
that sometimes weird projects end up being used by more people than we imagined... so have fun!

## TODO

* [URGENT] Add option to lock the worktree (`git worktree lock`) on the `checkout` command.
* [URGENT] Add command to unlock a worktree (`git worktree unlock`).
* [URGENT] Add command to prune the worktree list (`git worktree prune`) (Maybe unlock + prune?)
* Be able to write files/content into a worktree :)
* Be able to commit and **push** changes back to origin :O
* Migrate the code to Go Lang :D
