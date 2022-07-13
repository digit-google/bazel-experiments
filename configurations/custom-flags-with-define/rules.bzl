def _write_hello_impl(ctx):
  ctx.actions.write(
    output = ctx.outputs.output,
    content = "Hello World!\n")

write_hello = rule(
  implementation = _write_hello_impl,
  attrs = {
    "output": attr.output(mandatory=True),
  },
)

def _gen_concat_script_impl(ctx):
  content = "#!/bin/sh\n"
  if ctx.attr.condition:
    content += "echo FOOFOOFOO\n"
  content += "cat \"$@\"\n"
  ctx.actions.write(
    output = ctx.outputs.output,
    content = content,
    is_executable = True)

gen_concat_script = rule(
  implementation = _gen_concat_script_impl,
  attrs = {
    "output": attr.output(mandatory=True),
    "condition": attr.bool(default = False),
  },
)
