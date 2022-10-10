#!/bin/bash

bazel build //src:program //src:program2

check_program () {
  local OUT="$(bazel-bin/$1)"
  local EXPECTED="$2"
  if [[ "${OUT}" != "${EXPECTED}" ]]; then
    echo >&2 "ERROR: Program $1 return [${OUT}], expected [${EXPECTED}]"
    return 1
  fi
  echo "SUCCESS: Program $1 returned [${OUT}] as expected."
  return 0
}

EXPECTED_fpic_MODE="PIC mode: -fpic"
EXPECTED_fPIC_MODE="PIC mode: -fPIC"
EXPECTED_fpie_MODE="PIC mode: -fpie"
EXPECTED_fPIE_MODE="PIC mode: -fPIE"

# For the first program, the value comes from the common library compiled
# with -fPIE and linked statically to the executable itself.
check_program src/program "${EXPECTED_fPIE_MODE}" &&
\
# For the second program, the values comes from the common library compiled
# with -fPIC and linked statically to the shared library that the executable
# depends on.
check_program src/program2 "${EXPECTED_fPIC_MODE}" &&
\
echo "Ok!" || echo "KO :-("
