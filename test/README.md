# How these tests work

## ../Makefile

This provides a `test` and a `coverage` target.

The intent is that the `test` target gets run during normal package builds, and the `coverage` target gets run as part of the coverage job defined in the `debian/salsa-ci.yml` (or at some point might be incorporated into the salsa-ci/pipeline as a standard job).

### "test" target

This runs the tests using `fakechoot`. There is a wrapper in the top level of the chroot directory called `cd-exec` which is used to cd into the same directory as one was in outside the chroot, and then exec the rest of its parameters, which lets you run arbitary tests with parameters.

### "coverage" target

runs the same tests as the `test` target, but this time under `kcov`. This generates a coverage report. As long as there are more than one coverage run, the results turn up in a directory that containts the merged results, called `kcov-merged`. That is then used to produce a result line that gitlab can use as the value for its coverage badge (the jq output).

The `debian/salsa-ci.yml` file also points at the result in `kcov-merged` to allow the full report to be published, so that there is something for the coverage badge to point at.

## shunit2

The test scripts are based on shunit2, which allows one to mock most shell commands, but has the problem that shell functions cannot contain minus in their name, so one cannot do:

    fetch-url() {
        : pretend to do a fetch
    }

one can work around that with aliases, but since we needed something like fakechroot to deal with sourcing the debconf library, I just add `/mock_bin` to the PATH in `cd-exec`, and then can create `./test/chroot/mock_bin/fetch-url` to mock `fetch-url` in the tests.

The actual test is done by sourcing the script under test, to ensure that it
runs with the variable settings that you define just before that in each test
function. This is normally done within `$()` or `( )` to make sure that the test
script is in a sub-shell, and so doesn't get to break the shell running the test.

## mocked functions and magic variables

### fetch-url

Set `fetch_url_result` to the value you want to be retrieved by fetch-url, and it will write that value to the second parameter given to `fetch-url`. That's OK if there's only one interesting call to `fetch-url` in the script under test. If we need different results for different calls to `fetch-url` within a script, the mock script will need to become more clever.

### db_get

The mock script for this takes the debconf variable, and turns all slashes (/)
and dashes (-) into underscores, and then returns the value of that variable.
This means that if you want your test to act as though
`apt-setup/local0/repository` has a value of `http://some.url/` you need to do
`apt_setup_local0_repository="http://some.url/"` in the test script before
running the test.

# gitlab coverage badge ![example badge from apt-setup](https://salsa.debian.org/installer-team/apt-setup/badges/master/coverage.svg)

In order to get a coverage badge to appear on the repo. one needs to configure a badge with the following values (in the repo's Badges section - the name can just be "Coverage"):

* Link:

        https://salsa.debian.org/%{project_path}/-/jobs/artifacts/%{commit_sha}/file/debian/output/coverage/kcov-merged/index.html?job=coverage

* Badge Image URL:

        https://salsa.debian.org/%{project_path}/badges/%{default_branch}/coverage.svg
