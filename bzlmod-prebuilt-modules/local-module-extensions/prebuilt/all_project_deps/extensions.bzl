_PREBUILT_DIR = "../"

def _all_deps_impl(module_ctx):
  platforms = native.local_repository(
    name = "platforms",
    path = _PREBUILT_DIR + "platforms-0.0.4")
    
  bazel_skylib = native.local_repository(
    name = "bazel_skylib",
    path = _PREBUILT_DIR + "bazel-skylib-1.0.3")

  return [platforms, bazel_skylib]
    
all_deps = module_extension(implementation = _all_deps_impl)
