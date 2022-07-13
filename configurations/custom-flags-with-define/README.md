Demonstrate how to use a --define build configuration variable to change
the output of a rule. In this example, using `--define=foo=True` when invoking
`bazel build` will add an extra line to the `bazel-bin/hello2.txt` file.

```sh
$ bazel build //:hello2
INFO: Analyzed target //:hello2 (5 packages loaded, 15 targets configured).
INFO: Found 1 target...
Target //:hello2 up-to-date:
  bazel-bin/hello2.txt
INFO: Elapsed time: 0.476s, Critical Path: 0.03s
INFO: 4 processes: 3 internal, 1 linux-sandbox.
INFO: Build completed successfully, 4 total actions

$ cat bazel-bin/hello2.txt
Hello World!

$ bazel build --define=foo=True //:hello2
INFO: Build option --define has changed, discarding analysis cache.
INFO: Analyzed target //:hello2 (0 packages loaded, 15 targets configured).
INFO: Found 1 target...
Target //:hello2 up-to-date:
  bazel-bin/hello2.txt
INFO: Elapsed time: 0.218s, Critical Path: 0.03s
INFO: 3 processes: 2 internal, 1 linux-sandbox.
INFO: Build completed successfully, 3 total actions

$ cat bazel-bin/hello2.txt
FOOFOOFOO
Hello World!
```

