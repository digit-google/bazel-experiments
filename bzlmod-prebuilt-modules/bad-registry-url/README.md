This example tries to use a custom registry defined in a local directory.
Note that the registry itself still references modules by URL (and thus will
download them on demand).

The `registry/` directory contains the registry's content, it is a tiny copy
of the Bazel Central Registry that only contains module metadata for `platforms`
and `bazel_skylib`.

The test-1/.bazelrc`  file contains `common --registry ../registry` setting which
is a relative file path, instead of a URL. This crashes `bazel build` hard with:

```sh
$ cd test-1
$ bazel clean --expunge && bazel build --nobuild //src:hello
Starting local Bazel server and connecting to it...
INFO: Starting clean (this may take a while). Consider using --async if the clean takes more than several minutes.
Starting local Bazel server and connecting to it...
Loading: 0 packages loaded
FATAL: bazel crashed due to an internal error. Printing stack trace:
java.lang.RuntimeException: Unrecoverable error while evaluating node 'Key{moduleKey=platforms@0.0.4, override=null}' (requested by nodes 'com.google.devtools.build.lib.bazel.bzlmod.BazelModuleResolutionValue$$Lambda$375/0x00000008004cdc40@5ad1df6e')
        at com.google.devtools.build.skyframe.AbstractParallelEvaluator$Evaluate.run(AbstractParallelEvaluator.java:674)
        at com.google.devtools.build.lib.concurrent.AbstractQueueVisitor$WrappedRunnable.run(AbstractQueueVisitor.java:382)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source)
        at java.base/java.lang.Thread.run(Unknown Source)
Caused by: java.lang.NullPointerException
        at com.google.devtools.build.lib.bazel.bzlmod.RegistryFactoryImpl.getRegistryWithUrl(RegistryFactoryImpl.java:38)
        at com.google.devtools.build.lib.bazel.bzlmod.ModuleFileFunction.getModuleFile(ModuleFileFunction.java:254)
        at com.google.devtools.build.lib.bazel.bzlmod.ModuleFileFunction.compute(ModuleFileFunction.java:92)
        at com.google.devtools.build.skyframe.AbstractParallelEvaluator$Evaluate.run(AbstractParallelEvaluator.java:590)
        ... 4 more
```

It looks like the bzlmod code really wants a URL here, but Bazel should probably provide a better
error message in this case :-/
