A test case for providing prebuilt Bazel modules (through BzlMod) so that
`bazel build`  will not try to download them on-demand. For context see
https://fxbug.dev/103106

This example does not try to use a custom registry, instead each module
is provided as a directory under prebuilt/ that provides its own MODULE.bazel
file.

To test it:

```sh
$ cd test-1
$ bazel build //:hello
$ cat bazel-bin/hello1.txt
Hello World!
```

The test-1/ workspace provides a top-level MODULE.bazel file that contains
`local_path_override()` directives to ensure that the `platforms` and
`bazel_skylib` repositories come directly from `../prebuilts/platforms-0.0.4` and
`../prebuilts/bazel-skylib-1.0.3` respectively.

Note that these directories' content come from their relevant original archives, i.e.:

- https://github.com/bazelbuild/platforms/releases/download/0.0.4/platforms-0.0.4.tar.gz
- https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz

But that some files had to be *manually* added to work with BzlMod, i.e.:

- prebuilt/platforms-0.0.4/MODULE.bazel
  A copy of https://github.com/bazelbuild/bazel-central-registry/blob/main/modules/platforms/0.0.4/MODULE.bazel
  Required otherwise Bazel will complain with:

```sh
$ bazel build --nobuild '//:*'
ERROR: $BAZEL_OUTPUT_BASE/a37b38a8f3bb364f466d2357993f4754/external/platforms/MODULE.bazel (No such file or directory)
...
```

- prebuilt/bazel-skylib-1.0.3/MODULE.bazel
  A copy of https://github.com/bazelbuild/bazel-central-registry/blob/main/modules/bazel_skylib/1.0.3/MODULE.bazel
  Require otherwise `bazel build` will error with:

```
$ bazel build --nobuild '//:*'
ERROR: $BAZEL_OUTPUT_BASE/a37b38a8f3bb364f466d2357993f4754/external/bazel_skylib/MODULE.bazel (No such file or directory)
...
```

- prebuilt/bazel-skylib-1.0.3/WORKSPACE.bazel
  A symlink to the workspace.bzl file in the same directory. Without this, bazel would complain with
  an error that the directory has no WORKSPACE file (even though it has a MODULE.bazel file).

´''sh
$ bazel build --nobuild '//:*'
ERROR: <builtin>: fetching local_repository rule //external:bazel_skylib: java.io.IOException: No WORKSPACE file found in $BAZEL_OUTPUT_BASE/a37b38a8f3bb364f466d2357993f4754/external/bazel_skylib
ERROR: No WORKSPACE file found in $BAZEL_OUTPUT_BASE/a37b38a8f3bb364f466d2357993f4754/external/bazel_skylib
...

$ tree ~/.cache/bazel/_bazel_digit/a37b38a8f3bb364f466d2357993f4754/external/
$BAZEL_OUTPUT_BASE/a37b38a8f3bb364f466d2357993f4754/external/
├── bazel_skylib -> $EXAMPLE_DIR/prebuilt/bazel-skylib-1.0.3
├── bazel_tools -> $BAZEL_OUTPUT_BASE/install/41b71f1bb3ce13f20cfeeb31a9357113/embedded_tools
├── @bazel_tools.marker
├── platforms -> $EXAMPLE_DIR/prebuilt/platforms-0.0.4
└── @platforms.marker
...
'''
