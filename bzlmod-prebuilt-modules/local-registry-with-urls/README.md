This example tries to use a custom registry defined in a local directory.
Note that the registry itself still references modules by URL (and thus will
download them on demand).

The `registry/` directory contains the registry's content, it is a tiny copy
of the Bazel Central Registry that only contains module metadata for `platforms`
and `bazel_skylib`.

Because the `--registry` option takes a URL, and that `file://` can only contain
absolute paths, the `.bazelrc`  file *must* be generated by a script named
`generate-bazelrc.sh`

For testing:

```
$ ./generate-bazelrc.sh
$ cd test-1
$ bazel clean --expunge && bazel build //:hello
$ cat bazel-bin/hello1.txt
Hello World!
```