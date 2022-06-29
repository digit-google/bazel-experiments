"""TODO(digit): Write module docstring."""
def _write_hello_impl(ctx):
  ctx.actions.write(
    content = "Hello world!\n",
    output = ctx.outputs.output)

write_hello = rule(
  implementation = _write_hello_impl,
  attrs = {
    "output": attr.output(mandatory = True),
  }
)
