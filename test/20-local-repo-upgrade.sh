#!/usr/bin/busybox sh

SCRIPT="post-base-installer.d/03apt-local-repo-upgrade"

test_no_extra_repo() {
    output=$(. $SCRIPT)
    assertNotContains "No extra repo requires no apt upgrade" "$output" "upgrade"
    assertNotContains "No HTTPS needs no ca-certificates" "$output" "ca-certificates"
}

test_file_uri() {
    apt_setup_local0_repository="file:///foo/bar"
    output=$(. $SCRIPT)
    assertContains "extra repo requires apt upgrade" "$output" "upgrade"
    assertNotContains "No HTTPS needs no ca-certificates" "$output" "ca-certificates"
}

test_devel_https() {
    apt_setup__DEVEL__repository="https://foo/bar"
    output=$(. $SCRIPT)
    assertContains "extra repo requires an apt upgrade" "$output" "upgrade"
    assertContains "HTTPS needs ca-certificates" "$output" "ca-certificates"
}

test_devel_http() {
    apt_setup__DEVEL__repository="http://foo/bar"
    output=$(. $SCRIPT)
    assertContains "extra repo requires an apt upgrade" "$output" "upgrade"
}

test_local0_https() {
    apt_setup_local0_repository="https://foo/bar"
    apt_setup_local1_repository="http://foo/bar"
    output=$(. $SCRIPT)
    assertContains "extra repo requires an apt upgrade" "$output" "upgrade"
    assertContains "HTTPS needs ca-certificates" "$output" "ca-certificates"
}

test_local0_http() {
    apt_setup_local0_repository="http://foo/bar"
    output=$(. $SCRIPT)
    assertContains "extra repo requires an apt upgrade" "$output" "upgrade"
}

test_local0_http_local1_https() {
    apt_setup_local0_repository="http://foo/bar"
    apt_setup_local1_repository="https://foo/bar"
    output=$(. $SCRIPT)
    assertContains "extra repo requires an apt upgrade" "$output" "upgrade"
    assertContains "HTTPS needs ca-certificates" "$output" "ca-certificates"
}

# load shunit2
. shunit2
