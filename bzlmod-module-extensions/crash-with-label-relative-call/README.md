Demonstrates a Bazel crash when trying to use Label.relative() inside
the implementation function of a Bazel module extension. To reproduce:

Tested with Bazel 5.3.0rc1 on Linux

```sh
$ cd workspace/
# bazel build //:*

FATAL: bazel crashed due to an internal error. Printing stack trace:
java.lang.RuntimeException: Unrecoverable error while evaluating node 'SINGLE_EXTENSION_EVAL:ModuleExtensionId{bzlFileLabel=@module.override//:extensions.bzl, extensionName=ext}' (requested by nodes 'com.google.devtools.build.lib.bazel.bzlmod.ModuleExtensionResolutionValue$$Lambda$480/0x0000000800559840@12728816')
        at com.google.devtools.build.skyframe.AbstractParallelEvaluator$Evaluate.run(AbstractParallelEvaluator.java:674)
        at com.google.devtools.build.lib.concurrent.AbstractQueueVisitor$WrappedRunnable.run(AbstractQueueVisitor.java:382)
        at java.base/java.util.concurrent.ForkJoinTask$RunnableExecuteAction.exec(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinTask.doExec(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinPool$WorkQueue.topLevelExec(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinPool.scan(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinPool.runWorker(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinWorkerThread.run(Unknown Source)
Caused by: net.starlark.java.eval.Starlark$UncheckedEvalException: NullPointerException thrown during Starlark evaluation
        at <starlark>.relative(<builtin>:0)
        at <starlark>._impl(/usr/local/google/home/digit/.cache/bazel/_bazel_digit/d122d6a22759c5148e0c5e54eb6a40ae/external/module.override/extensions.bzl:4)
Caused by: java.lang.NullPointerException
        at com.google.devtools.build.lib.cmdline.Label.getRelative(Label.java:551)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
        at java.base/java.lang.reflect.Method.invoke(Unknown Source)
        at net.starlark.java.eval.MethodDescriptor.call(MethodDescriptor.java:162)
        at net.starlark.java.eval.BuiltinFunction.fastcall(BuiltinFunction.java:77)
        at net.starlark.java.eval.Starlark.fastcall(Starlark.java:619)
        at net.starlark.java.eval.Eval.evalCall(Eval.java:672)
        at net.starlark.java.eval.Eval.eval(Eval.java:489)
        at net.starlark.java.eval.Eval.execAssignment(Eval.java:109)
        at net.starlark.java.eval.Eval.exec(Eval.java:268)
        at net.starlark.java.eval.Eval.execStatements(Eval.java:82)
        at net.starlark.java.eval.Eval.execFor(Eval.java:126)
        at net.starlark.java.eval.Eval.exec(Eval.java:276)
        at net.starlark.java.eval.Eval.execStatements(Eval.java:82)
        at net.starlark.java.eval.Eval.execFor(Eval.java:126)
        at net.starlark.java.eval.Eval.exec(Eval.java:276)
        at net.starlark.java.eval.Eval.execStatements(Eval.java:82)
        at net.starlark.java.eval.Eval.execFunctionBody(Eval.java:66)
        at net.starlark.java.eval.StarlarkFunction.fastcall(StarlarkFunction.java:191)
        at net.starlark.java.eval.Starlark.fastcall(Starlark.java:619)
        at com.google.devtools.build.lib.bazel.bzlmod.SingleExtensionEvalFunction.compute(SingleExtensionEvalFunction.java:172)
        at com.google.devtools.build.skyframe.AbstractParallelEvaluator$Evaluate.run(AbstractParallelEvaluator.java:590)
        at com.google.devtools.build.lib.concurrent.AbstractQueueVisitor$WrappedRunnable.run(AbstractQueueVisitor.java:382)
        at java.base/java.util.concurrent.ForkJoinTask$RunnableExecuteAction.exec(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinTask.doExec(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinPool$WorkQueue.topLevelExec(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinPool.scan(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinPool.runWorker(Unknown Source)
        at java.base/java.util.concurrent.ForkJoinWorkerThread.run(Unknown Source)
```
