Demonstrates a Bazel error when trying to access the
[`repository_ctx.workspace_root`](https://bazel.build/rules/lib/repository_ctx?hl=en#execute)
field, from a repository rule implementation function:

Tested with Bazel 5.3.0rc1 on Linux

```sh
$ bazel build //:*

INFO: Repository generated instantiated at:
  /work2/github-digit/bazel-experiments/repository-rules/error-using-workspace_root/WORKSPACE.bazel:3:10: in <toplevel>
Repository rule repo_rule defined at:
  /work2/github-digit/bazel-experiments/repository-rules/error-using-workspace_root/repository_rules.bzl:9:28: in <toplevel>
ERROR: An error occurred during the fetch of repository 'generated':
   Traceback (most recent call last):
        File "/work2/github-digit/bazel-experiments/repository-rules/error-using-workspace_root/repository_rules.bzl", line 2, column 33, in _repo_impl
                workspace_dir = str(repo_ctx.workspace_root)  # ERROR HERE!
Error: 'repository_ctx' value has no field or method 'workspace_root'
ERROR: /work2/github-digit/bazel-experiments/repository-rules/error-using-workspace_root/WORKSPACE.bazel:3:10: fetching repo_rule rule //external:generated: Traceback (most recent call last):
        File "/work2/github-digit/bazel-experiments/repository-rules/error-using-workspace_root/repository_rules.bzl", line 2, column 33, in _repo_impl
                workspace_dir = str(repo_ctx.workspace_root)  # ERROR HERE!
Error: 'repository_ctx' value has no field or method 'workspace_root'
ERROR: /work2/github-digit/bazel-experiments/repository-rules/error-using-workspace_root/BUILD.bazel:1:10: //:all depends on @generated//:all in repository @generated which failed to fetch. no such package '@generated//': 'repository_ctx' value has no field or method 'workspace_root'
ERROR: Analysis of target '//:all' failed; build aborted: Analysis failed
INFO: Elapsed time: 2.584s
INFO: 0 processes.
FAILED: Build did NOT complete successfully (4 packages loaded, 6 targets configured)
```
