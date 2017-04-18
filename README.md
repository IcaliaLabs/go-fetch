# Go Fetch!

A code fetcher Docker Container


## Usage:

Checkout a branch from a private github repo into the named volume `example-1`:

```
docker run --rm \
-v test_repos:/repos \
-v example-1:/example-1 \
icalialabs/go-fetch checkout \
--user [YOUR USERNAME] \
--password '[YOUR PASSWORD OR ACCESS TOKEN]' \
--github [YOUR GITHUB NAMESPACE]/[YOUR REPO PROJECT] example-1 origin/master

# Once finished you can launch stuff - such as codeclimate - over the code checked out in volume example-1:

docker run --rm \
--env CODECLIMATE_CODE=example-1 \
--env CODECLIMATE_TMP=/tmp \
--volume example-1:/code \
--volume /tmp:/tmp/cc \
--volume /var/run/docker.sock:/var/run/docker.sock \
codeclimate/codeclimate analyze -f json
```

You can also checkout a particular commit from a public github repo into the named volume `example-2`:

```
docker run --rm \
-v test_repos:/repos \
-v example-2:/example-2 \
icalialabs/go-fetch checkout \
--github IcaliaLabs/go-fetch example-2 6688d6fd62e0f97819b353f3fc3e91e61abf10bc
```

Extract a list of code fragments from a public github repo into using the named volume `example-3`:

```
docker run --rm \
-v test_repos:/repos \
-v example-3:/example-3 \
icalialabs/go-fetch extract \
--github IcaliaLabs/go-fetch example-3 6688d6fd62e0f97819b353f3fc3e91e61abf10bc \
README.md:L1-L2 \
LICENSE:L12-L13
```
