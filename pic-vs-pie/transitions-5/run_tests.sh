#!/bin/bash

COMMANDS_LOG=/tmp/BAZEL_COMMANDS

bazel clean
bazel build -s //src:program //src:program2 > "${COMMANDS_LOG}" 2>&1
if [[ $? != 0 ]]; then
  echo >&2 "ERROR: Unable to build test programs, for details: less ${COMMANDS_LOG}"
  exit 1
fi

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

check_genrule_configs () {
  local configs=$(grep 'SUBCOMMAND: # //src:generate_common' "${COMMANDS_LOG}" | awk '$10 == "configuration:" { print $11;}')
  local num_configs=$(echo "$configs" | tr ' ' '\n' | wc -l)
  if [[ "$num_configs" != 1 ]]; then
    echo >&2 "ERROR: Multiple configs found to run //src:generate_common genrule() action"
    for config in ${configs}; do
      config=${config%,}  # remove trailing comma
      printf "bazel config $config\n" >&2
    done
    return 1
  fi
  echo "SUCCESS: Only one genrule() invocation was performed!"
}

check_default_build () {
  bazel build "$@" >> "${COMMANDS_LOG}" 2>&1
  if [[ $? != 0 ]]; then
    echo >&2 "ERROR: Unable to build in default toolchain:"
    echo >&2 "  bazel build $@"
    return 1
  fi
  echo "SUCCESS: Default toolchain build for '$@'"
  return 0
}

# For the first program, the value comes from the common library compiled
# with -fPIE and linked statically to the executable itself.
check_program src/program "PIC mode: -fPIE" &&
\
# For the second program, the values comes from the common library compiled
# with -fPIC and linked statically to the shared library that the executable
# depends on.
check_program src/program2 "PIC mode: -fPIC" &&
\
# Verify that the generate_common command was only run once.
check_genrule_configs &&
\
# Verify that building //src:common in the default configuration works too.
check_default_build src/common &&
echo "Ok!" || echo "KO :-("
