"""
Common definitions.
"""

def _my_data_dep_impl(ctx):
  return [
    DefaultInfo(
      runfiles = ctx.runfiles(
        root_symlinks = { ctx.attr.dst: ctx.files.src[0] },
      ),
    )
  ]

my_data_dep = rule(
  implementation = _my_data_dep_impl,
  doc = "Define a target recording a runfile.",
  attrs = {
    "src": attr.label(mandatory = True, allow_single_file = True),
    "dst": attr.string(mandatory = True),
  },
)

def _print_runfiles_impl(ctx):
  target = ctx.attr.target
  runfiles = [
    symlink.target_file for symlink in target[DefaultInfo].default_runfiles.root_symlinks.to_list()
  ]
  print('Runfiles for %s: %s' % (target.label, runfiles))

print_runfiles = rule(
  implementation = _print_runfiles_impl,
  doc = "Print the runfiles of a given target.",
  attrs = {
    "target": attr.label(mandatory = True),
  },
)
