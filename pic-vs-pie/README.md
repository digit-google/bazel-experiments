An PIE-optimized ELF executable is a program binary whose machine code has
all been compiled with `-fPIE` or `-fpie`, which ensures smaller and faster
position-independent code than using `-fPIC` or `-fpic` respectively.

Such machine code cannot be linked into ELF shared libraries, which require
the use of `-fPIC` or `-fpic` instead.

By default, Bazel builds all executables with `-fPIC`, even when generating
position-independent executables (with the _linker_ option `-fpie` which is
something different), resulting in binaries that are larger and slower than
necessary.

This directory contains several workspaces that try to mix PIE-optimized ELF
executables and PIC ELF shared libraries in a single build invocation.

Note that this only works on ELF-based host systems (i.e. Linux or BSDs),
not Windows or MacOS.

Summaries (see the `README.md` file in each sub-directory for details):

- no-transitions:
    This workspace tries to do that without using any transitions, and direct
    use of native cc_library() and cc_binary() target. This requires
    duplicating target definitions which is error prone, impractical and
    does not scale at all.

- transitions-1:
    A first attempt at using transitions to generate a PIE-optimized
    executable and a PIC shared library. This requires wrapping cc_binary()
    calls with specialized macros (defined here as `cc_executable()` and
    `cc_shared_library()` which are defined in `//:defs.bzl`).

- transitions-2:
    A second example of using transitions, and using a genrule() to generate
    the sources of a `common` static library, which is a dependency of both
    the executable and the shared library (and hence needs to be compiled
    twice).

    Unfortunately, the sample shows that by default, Bazel will run the
    `genrule()` twice, because the exec configuration is uses to run the
    genrule inherits settings from the dependent's build configuration.

- transitions-3:
    A third example of using transitions that tries to remove the duplicate
    work seen in the previous one. To do so, another transition is introduced
    to switch to a 'unique' build configuration before depending on the
    genrule(). This requires yet another wrapper (here `unique_genrule()`)
    and succeeds in running the same source-generating genrule() only once.

    Unfortunately, trying to include the generated header in dependents
    (e.g. from //src:program.cc and //src:sharedlib.cc) now fails.
