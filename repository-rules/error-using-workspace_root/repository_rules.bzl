def _repo_impl(repo_ctx):
    workspace_dir = str(repo_ctx.workspace_root)  # ERROR HERE!
    repo_ctx.file("WORKSPACE", content = "")
    repo_ctx.file("defs.bzl", content = """
workspace_dir = {workspace_dir}
""".format(workspace_dir = workspace_dir))
    repo_ctx.file("BUILD.bazel", content = "")

repo_rule = repository_rule(implementation = _repo_impl)
