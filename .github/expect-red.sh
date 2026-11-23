#!/usr/bin/env bash
# Passes only when the one named test fails on $EXPECTED: not on a compile
# error, a timeout, setup, or any other panic.
# Usage: expect-red.sh <cargo target flags...> <exact test name>
set -u
name="${*: -1}"
out="$(mktemp)"
cargo test --locked "$@" -- --exact 2>&1 | tee "$out"
status=${PIPESTATUS[0]}
echo "::group::Red verdict for $name"
fail() {
  echo "NOT RED: $1"
  echo "::endgroup::"
  exit 1
}
[ "$status" -eq 101 ] || fail "cargo test exited $status, expected 101 (a test failure)"
grep -qF "test result: FAILED. 0 passed; 1 failed" "$out" || fail "not exactly one test run and failed"
grep -qF -- "---- $name stdout ----" "$out" || fail "the failing test is not $name"
grep -qF "$EXPECTED" "$out" || fail "the panic is not the expected assertion"
if grep -qE "timed out waiting|the daemon answers" "$out"; then
  fail "a timeout was involved"
fi
[ "$(grep -c "panicked at" "$out")" -eq 1 ] || fail "not exactly one panic"
grep -A3 "panicked at" "$out"
echo "RED CONFIRMED: $name failed on: $EXPECTED"
echo "::endgroup::"
