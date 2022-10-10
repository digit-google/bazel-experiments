Abstract:
---------

A first example that demonstrate how to build PIE-optimized ELF executables and
PIC-optimized ELF shared libraries in a single build invocation.
Currently only works on Linux.

Testing:
------

Run the `run_tests.sh` in the workspace directory.

Implementation Note:
--------------------

The idea is to use transitions to add/remove -fPIC/-fPIE flags when building
a shared library / an executable and all their transitive dependencies. In
particular:

1) A "common" library, which provides a simple common() entry point that
   returns a string describing the current PIC compilation mode (see source
   file for details).

2) A first 'program' executable that depends on the "common" lib and will
   link it statically. In this case, the `common` library and the executables
   will both be compiled with `-fPIE`.

3) A second 'program' executable that links to a 'sharedlib' shared library
   target, which links to the "common" lib. In this case, both the shared
   library and the `common` library will be compiled with `-fPIC`.

Since it is impossible to attach transitions to native rules like cc_binary()
or cc_import(), wrapper macros are provided:

- cc_executable() to wrap a cc_binary() that generates an executable. Accepts
  the same arguments except for 'linkshared'.

- cc_shared_library() to wrap a cc_binary() that generates a shared library.
  Accepts the same arguments except for `linkshared`. This macro also
  automatically provides a cc_import() target to allow linking to the shared
  library directly.

Note that two additional build configurations are being used to build the
PIE and PIC binaries here.

  //src:program   (default configuration)
    --> //src:program.binary  (PIE build config)     TRANSITION
      --> //src:common  (PIE build config)

  //src:program2   (default build config)
    --> //src:program2.binary   (PIE build config)
      --> //src:sharedlib.import  (PIC build config)   TRANSITION
        --> //src:sharedlib.shared_library  (PIC build config)
          --> //src:common  (PIC build config)

Transitions only implement changes to 'copt' and 'linkopt', which is a little
crude. A cleaner way would be to define custom C++ toolchain configs with
corresponding feature definitions that could instead be toggled on/off by
the transition.

Note that Bazel will always add an `-fPIC` flag to C++ compilation command
(which come from the default C++ toolchain config, and is thus not visible in
`settings["//command_line_option:copt"]` inside the transition implementation
function. A value like `-fPIE` being set in `copt` will still appear _after_ it
on the command-line, over-writing this previous variable.

In other words, the compile command for //src:program.cc in (PIE build config)
looks like:

```sh
 /usr/bin/gcc \
    ... \
    bazel-out/k8-fastbuild-ST-bd2abcc18995/bin/src/_objs/program.binary/program.pic.d \
    -fPIC \
    ... \
    -fPIE \
    ... \
    -c \
    src/program.cc \
    -o \
    bazel-out/k8-fastbuild-ST-bd2abcc18995/bin/src/_objs/program.binary/program.pic.o
```

Note the output path of `bazel-out/k8-fastbuild-ST-bd2abcc18995/bin` which
corresponds to the output directory for the PIE build config, which is _not_
identified by the hash `bd2abcc18995` but something else entirely (in this
specific example, `4bed65880b8240`).

The current implementation of to_shared_library_transition always adds an
`-fPIC` flag to `copt` though, which means the compilation of a shared library
or its dependencies will look contain two `-fPIC` flags, which doesn't affect
compiler results. On the other hand, it means that the (PIC build config)
will be distinct from the default configuration.

An optimization might consist in assuming that `-fPIC` is the default, and
build shared library artifacst in the default build config instead. However,
this is fragile if one uses a custom C++ toolchain configuration.

Issues / Unknowns / Future Work:
--------------------------------

It is not possible to run the //src:program target, which currently generates
a symlink to the real binary, i.e.

```sh
$ bazel run //src:program
ERROR: Cannot run target //src:program: Not executable
...
FAILED: Build did NOT complete successfully (1 packages loaded)
```

However, it is possible to run it directly from the command-line:

```sh
$ bazel-bin/src/program
PIC mode 200
```

Runfiles and data dependencies of executables may be problematic as well,
especially if they need to be generated in the default toolchain.

What happens when both 'program' and 'sharedlib' depend on a genrule()
that generates sources? If Bazel smart enough to avoid duplicate work or
are extra steps / wrappers necessary ?

When not building for an ELF system (e.g. Windows or MacOS), can we avoid
introducing intermediate targets that will do nothing? It seems that is not
possible since the build configuration is not visible when macros are
processed. Is the 'cfg' attribute configurable?
