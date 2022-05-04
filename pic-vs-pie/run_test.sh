#!/bin/bash
#
set -e

PROGRAMS=(
  pic_mode
  pic_mode_with_static_lib
  pic_mode_with_pie_lib
  pic_mode_fully_static_link
  pic_mode_fully_static_link_with_static_lib
  pic_mode_fully_static_link_with_pie_lib
  pic_mode_all_pie
)

BAZEL_TARGETS=()
for PROG in "${PROGRAMS[@]}"; do
  BAZEL_TARGETS+=(//:${PROG})
done

for MODE in "" "--force_pic" "--features=pie" "--features=fully_static_link" "--features=\"pie,fully_static_link\"" "--copt=-fPIE --linkopt=-fPIE"; do
  bazel clean
  bazel build $MODE "${BAZEL_TARGETS[@]}"

  for PROG in "${PROGRAMS[@]}"; do
    echo "=== ${PROG} === ${MODE}"
    echo -n "  "; bazel-bin/$PROG
  done
done
