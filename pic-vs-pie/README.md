An experiment to try to build Linux PIE executables with Bazel
with the native `cc_binary()` and `cc_library()` rules.

Both the `-fPIC` and `-fPIE` compiler and linker flags can
be used to generate machine code that is position-independent
(i.e. can be loaded at any address in memory). However, `-fPIC`
is required for machine code that goes into shared libraries,
while either `-fPIC` or `-fPIE` can be used for executables.

Since `-fPIE` generates slightly smaller and faster code, it
is preferred for all code that goes into executables. The Bazel
documentation states that the `--force_pic` option should ensure
that binaries are generated with `-fpie` but that clearly isn't
the case, as demonstrated by this project.

This project contains a BUILD.bazel file that provides targets
to compile a tiny executable and a dependency library that print
whether their machine code was compiled in PIC/PIE/static mode.

Then a `run_test.sh` script that will rebuild them in different
build configurations (e.g with `--force_pic`, or
`--features=fully_static_link` to see if any of these work
properly).

It looks like that only the `pic_mode_all_pie` executable is
working correctly, since it is built by forcing the compiler
and linker flag to `-fPIE` explicitly on the `cc_binary()`
and `cc_library()` target definitions, which is very
inconvenient instead of having this being handled correctly
by Bazel or its C++ toolchain definition.
