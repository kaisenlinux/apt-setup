#!/usr/bin/busybox sh

SCRIPT="generators/60local"

oneTimeSetUp() {
    # Define global variables for command output.
    sourceslist="${SHUNIT_TMPDIR}/sources.list"
    ROOT=${SHUNIT_TMPDIR}/_root_
    mkdir -p ${ROOT}/tmp ${ROOT}/etc/apt/keyrings/
}

setUp() {
    rm -f "${sourceslist}"

    # clear out settings between tests
    for x in _DEVEL_ local0 local1; do
        for y in source repository comment key; do
            unset apt_setup_${x}_${y}
        done
    done
    unset db_go_ret

    # provide a default fetch result, that can be overriden
    export fetch_url_result="pretend binary GPG key"
}

test_no_locals() {
    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: $output" '[ 0 = $result ]'
    assertFalse "'${sourceslist}' should not have been created" "[ -e '${sourceslist}' ]"
}

test__DEVEL_repo() {
    apt_setup__DEVEL__repository="file:///foo/bar"
    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: $output" '[ 0 = $result ]'
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertTrue "'${sourceslist}' should contain '${apt_setup__DEVEL__repository}'" "grep -q '${apt_setup__DEVEL__repository}' '${sourceslist}'"
}

test_comment() {
    apt_setup_local0_repository="http://some.url/"
    apt_setup_local0_comment="my favourite stuff"
    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: $output" '[ 0 = $result ]'
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local0_repository}'" "grep -q '${apt_setup_local0_repository}' '${sourceslist}'"
}

test_options() {
    touch "$ROOT/tmp/key0.pub"
    apt_setup_local0_repository="http://some.url/"
    apt_setup_local0_options="check-valid-until=false"
    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: '$output'" "[ 0 -eq $result ]"
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local0_repository}'" "grep -q '${apt_setup_local0_repository}' '${sourceslist}'"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local0_options}'" "grep -q '${apt_setup_local0_options}' '${sourceslist}'"
    # head -v "${sourceslist}"
}

test_options_and_key() {
    touch "$ROOT/tmp/key0.pub"
    apt_setup_local0_repository="http://some.url/"
    apt_setup_local0_options="check-valid-until=false"
    apt_setup_local0_comment="some_comment"
    apt_setup_local0_key=zzzz # we're mocking fetch_url, so this setting isn't actually used
    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: '$output'" "[ 0 -eq $result ]"
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local0_repository}'" "grep -q '${apt_setup_local0_repository}' '${sourceslist}'"
    assertTrue "'${sourceslist}' should contain 'signed-by=/etc/apt/keyrings/${apt_setup_local0_comment}.gpg'" "grep -q 'signed-by=/etc/apt/keyrings/${apt_setup_local0_comment}.gpg' '${sourceslist}'"
    assertTrue "'${ROOT}/etc/apt/keyrings/${apt_setup_local0_comment}.gpg' should contain '${fetch_url_result}'" "grep -q '${fetch_url_result}' '${ROOT}/etc/apt/keyrings/${apt_setup_local0_comment}.gpg'"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local0_options}'" "grep -q '${apt_setup_local0_options}' '${sourceslist}'"
}

test_source() {
    touch "$ROOT/tmp/key0.pub"
    apt_setup_local0_repository="http://some.url/"
    apt_setup_local0_source=true
    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: '$output'" "[ 0 -eq $result ]"
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertTrue "'${sourceslist}' should contain 'mumble'" "grep -q '${apt_setup__DEVEL__repository}' '${sourceslist}'"
}

test_gpg_asc() {
    touch "$ROOT/tmp/key0.pub"
    apt_setup_local0_repository="http://some.url/"
    apt_setup_local0_source=true
    fetch_url_result='-----BEGIN PGP PUBLIC KEY BLOCK-----'

    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: '$output'" "[ 0 -eq $result ]"
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local0_repository}'" "grep -q '${apt_setup_local0_repository}' '${sourceslist}'"
}

test_failed_fetch() {
    touch "$ROOT/tmp/key0.pub"
    apt_setup_local0_repository="http://some.url/"
    apt_setup_local0_source=true
    apt_setup_local0_key=zzzz # we're mocking fetch_url, so this setting isn't actually used
    # simulate a failure of fetch_url
    fetch_url_result='fail'
    # make it look like the user doesn't want to retry
    db_go_ret=false

    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertFalse "command should have failed" "[ 0 -eq $result ]"
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertFalse "'${sourceslist}' should contain '${apt_setup_local0_repository}'" "grep -q '${apt_setup_local0_repository}' '${sourceslist}'"
}

test_ignore_failed_fetch() {
    touch "$ROOT/tmp/key0.pub"
    apt_setup_local0_repository="http://some.url/"
    apt_setup_local0_source=true
    apt_setup_local0_key=zzzz # we're mocking fetch_url, so this setting isn't actually used
    # simulate a failure of fetch_url
    fetch_url_result='fail'
    # make it look like the user wants to ignore the failure
    db_go_ret=true
    apt_setup_local_key_error=Ignore

    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: '$output'" "[ 0 -eq $result ]"
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local0_repository}'" "grep -q '${apt_setup_local0_repository}' '${sourceslist}'"
}

test_multi_repo() {
    touch "$ROOT/tmp/key0.pub"
    apt_setup_local0_repository="http://some.url/"
    apt_setup_local0_source=true
    apt_setup_local1_repository="https://someother.url/"
    fetch_url_result='fail'
    apt_setup_local_key_error=Ignore
    db_go_ret=true

    output=$(. $SCRIPT "${sourceslist}" 2>&1)
    result=$?
    assertTrue "command failed with this output: '$output'" "[ 0 -eq $result ]"
    assertTrue "'${sourceslist}' should have been created" "[ -e '${sourceslist}' ]"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local0_repository}'" "grep -q '${apt_setup_local0_repository}' '${sourceslist}'"
    assertTrue "'${sourceslist}' should contain '${apt_setup_local1_repository}'" "grep -q '${apt_setup_local1_repository}' '${sourceslist}'"
    # head -v "${sourceslist}"
}

# load shunit2
. shunit2
