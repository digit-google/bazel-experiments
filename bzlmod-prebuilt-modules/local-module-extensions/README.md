This example does not try to use a custom BzlMode registry, instead a specific
`all_project_deps` module is used and provides a repo-generating extension that
allows the top-module in `test-1/MODULE.bazel` to use `use_repo()`.

Unfortunately, that doesn't work because `native.local_repository()` is not
supported yet in module extensions (this is documented as a footnote in the
[BzlMod Migration Guide](https://docs.google.com/document/d/1JtXIVnXyFZ4bmbiBCr5gsTH4-opZAFf5DMMb-54kES0/edit?usp=sharing))

Note that `prebuilt/all_project_deps/BUILD.bazel` is empty but required,
otherwise Bazel will complain when trying to load the `extensions.bzl` file.

To test it:

```sh
$ cd test-1
$ bazel build //:hello
ERROR: Traceback (most recent call last):
        File "/usr/local/google/home/digit/.cache/bazel/_bazel_digit/ca4b7c8638fddcb5ea4d58be3efad0f7/external/all_project_deps/extensions.bzl", line 4, column 38, in _all_deps_impl
                platforms = native.local_repository(
Error in local_repository: The native module can be accessed only from a BUILD thread. Wrap the function in a macro and call it from a BUILD file
ERROR: Analysis of target '//:hello' failed; build aborted: error evaluating module extension all_deps in @all_project_deps//:extensions.bzl
...
```
