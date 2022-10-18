This example shows a regression in the latest Bazel 6 pre-release candidate (and ToT)
where `cc_library()` data dependences do not see their `runfiles` values passed properly
to the library / dependent.

See defs.bzl which defines a custom `my_data_dep()` rule whose implementation function
simply returns a `DefaultInfo(runfiles = ctx.runfiles(...))` value, and a `cc_library()`
that depends on it through its `data` attribute.

Use `bazel build //:print_runfiles` to print the runfiles of the `cc_library()`,
with Bazel 5.3.1, this prints a list of a single `foo.txt` file, which is correct.

With Bazel ToT (as of 2022-10-18), this prints an empty list.

I could bisect the Bazel sources to see that the regression was introduced by commit
333d579442a056e721b6b02647a1aa27ffe4f111 which flips the implementation of `cc_library()`
from the hard-coded Java CcLibrary class, to the `cc_library.bzl` Starlark implementation.

Further inspection shows that the following code in that file is responsible for the
regression:

```
         if data_dep[DefaultInfo].data_runfiles.files:
             runfiles_list.append(data_dep[DefaultInfo].data_runfiles)
         else:
             runfiles_list.append(ctx.runfiles(transitive_files = data_dep[DefaultInfo].files))  # HERE

```
Changing the _else_ clause to instead propagate `default_runfiles` as in:

```
         if data_dep[DefaultInfo].data_runfiles.files:
             runfiles_list.append(data_dep[DefaultInfo].data_runfiles)
         else:
             runfiles_list.append(data_dep[DefaultInfo].default_runfiles)

```

Solves the issue. It is however very hard to see if this matches the previous behavior from the
Java code, due to an exquisite number of indirections in it :) The following could be found though:

1) Data dependencies from CcLibrary targets are propagated by calling `RunFiles.Builder.addDataDeps()`
on [1](https://cs.opensource.google/bazel/bazel/+/master:src/main/java/com/google/devtools/build/lib/rules/cpp/CcLibrary.java;drc=3e13f4cbb60bfcd7edd3949184cda42f0785fe54;l=454)

2) The `addDataDeps()` methods will call ` RunfilesProvider.DATA_RUNFILES` for each data dependency
   of the library [2](https://cs.opensource.google/bazel/bazel/+/master:src/main/java/com/google/devtools/build/lib/analysis/Runfiles.java;drc=c8b7ed3fecbcee39bf1557fc3d608f42baaffdcd;l=937)

3) The `DATA_RUNFILES` callable will use `RunFilesProvider.getDataRunFiles()` for each dependency,
   on the `RunFiles` instance returned by `TransitiveInfoCollection.getProvider(RunfilesProvider.class)`
   [3](https://cs.opensource.google/bazel/bazel/+/master:src/main/java/com/google/devtools/build/lib/analysis/RunfilesProvider.java;drc=c8b7ed3fecbcee39bf1557fc3d608f42baaffdcd;l=71)

4) The `getDataRunFiles()` method simply returns the value that was set when creating
   the `RunFilesProvider` instance for the dependency.

   `RunFiles` values are created only via `RunFilesProvider.simple()`, which copies the same
   values both to `defaultRunFiles` and `dataRunFiles`, or via `RunFilesProvider.withData()`,
   which separates them [4](https://cs.opensource.google/bazel/bazel/+/master:src/main/java/com/google/devtools/build/lib/analysis/RunfilesProvider.java;drc=c8b7ed3fecbcee39bf1557fc3d608f42baaffdcd;l=80)

5) The `DefaultInfo(runfiles = ...)`  expression is parsed by the `parseDefaultProviderFields()`
   method in [5](https://cs.opensource.google/bazel/bazel/+/master:src/main/java/com/google/devtools/build/lib/analysis/starlark/StarlarkRuleConfiguredTargetUtil.java;drc=c8b7ed3fecbcee39bf1557fc3d608f42baaffdcd;l=493)
   which ends up calling `addSimpleProviders()` in the same class, which ends up
   calling `RunFilesProvider.same()` with the `runfiles` value , which will then
   populate both `data_runfiles` and `default_runfiles` in the resulting `RunFiles`
   instances.

Note that the equivalent of `DefaultInfo.files` is never used, so the `cc_library.bzl` else clause
is likely a bug that was not caught by an appropriate regression test :-/
