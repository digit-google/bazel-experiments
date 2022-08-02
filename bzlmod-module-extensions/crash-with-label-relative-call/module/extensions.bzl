# This extension function crashes when Label.relative() is called.
# NOTE: This seems independent of the arguments provided.
def _impl(module_ctx):
    for module in module_ctx.modules:
        for wanted in module.tags.wanted:
            rel = wanted.label.relative("//")  # CRASh HERE!

wanted_class = tag_class(
    attrs = {
        "label": attr.label(mandatory = True),
    },
)

ext = module_extension(
    implementation = _impl,
    tag_classes = {
        "wanted": wanted_class,
    },
)
