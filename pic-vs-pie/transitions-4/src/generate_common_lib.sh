#!/bin/sh
HDR="$1"
SRC="$2"

# Generate header.
cat > $HDR <<EOF
#ifndef COMMON_H_
#define COMMON_H_

extern const char* common(void);

#endif  // COMMON_H_
EOF

# Generate source file.
cat > $SRC <<EOF
#include "common.h"

// The function returns a string describing the PIC compilation mode used
// when the library was compiled.
const char* common() {
#if defined(__PIE__)
#  if __PIC__ == 2
  return "-fPIE";
#  elif __PIC__ == 1
  return "-fpie";
#  else
  return "Unknown __PIE__ value!";
#  endif
#elif defined(__PIC__)
#  if __PIC__ == 2
  return "-fPIC";
#  elif __PIC__ == 1
  return "-fpic";
#  else
  return "Unknown __PIC__ value!";
#  endif
#else
  return "static";
#endif
}
EOF
