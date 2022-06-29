This example tries to use a custom registry defined in a local directory.
The registry's `sources.json` entries try to use `file://` URLs to point
directory to the directories under `prebuilt/`  which contain the extracted
module content.

Note that the `.bazelrc` file needs to be auto-generated because its
`--registry` option requires a URL, and `file://` URLs must be absolute.

The `source.json`  files need to be auto-generated for the same reason.

This doesn't work at all, Bazel errors claiming the url could not be fetched.

```
$ ./generate-files.sh
$ cd test-1
$ bazel clean --expunge && bazel build //:hello
...
ERROR: /usr/local/google/home/digit/.cache/bazel/_bazel_digit/8db6dd4f32f4e796300308153858faa7/external/local_config_platform/BUILD.bazel:4:9: @local_config_platform//:host depends on @platforms.0.0.4//cpu:x86_64 in repository @platforms.0.0.4 which failed to fetch. no such package '@platforms.0.0.4//cpu': Missing integrity for module platforms@0.0.4
ERROR: /work2/github-digit/bazel-experiments/bzlmod-prebuilt-modules/local-registry-with-files/test-1/BUILD.bazel:4:12: While resolving toolchains for target //:hello: Target @local_config_platform//:host was referenced as a platform, but does not provide PlatformInfo
...
```
