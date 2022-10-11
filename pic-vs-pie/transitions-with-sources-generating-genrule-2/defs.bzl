"""
Macros to support mixed -fPIC / -fPIE builds on ELF systems.
"""

# The transitions implemented here modify copt and linkopt directly.
# A cleaner solution would be to define custom C++ toolchain configurations
# with feature flags that could be turned on/off by the transition instead,
# but this represents several hundreds line of fragile Starlark code, which
# are not necessary in the context of this experiment.

def _remove_option(input, opt):
    """Remove all instances of |opt| from |input| list.

    Args:
      input: A list of items (e.g. string list).
      opt: A item to probe the list content (e.g. a string).
    Returns:
      A new list that does not contain any instance of |opt|.
    """
    return [o for o in input if o != opt]

def _remove_options(input, opts):
    """Remove all instances of any items in |opts| from |input| list."""
    for opt in opts:
        input = _remove_option(input, opt)
    return input

def _add_option(input, opt):
    """Add |opt| to |input| if the latter does not already contains it."""
    for o in input:
        if o == opt:
            # Input already contains the option, so just return it as is.
            return input

    # Append option to input.
    return input + [opt]

_transition_inputs = [
    "//command_line_option:copt",
    "//command_line_option:linkopt",
]

_transition_outputs = _transition_inputs

def _modify_copt_and_linkopt_settings(
        settings,
        remove_copts,
        add_copt,
        remove_linkopts,
        add_linkopt):
    """Modify copy and linkopt values from |settings|.

    Args:
      settings: A dictionary mapping build settings names to their current value.
          This is the value received as the first argument to a transition
          implementation function.
      remove_copts: A list of strings for compiler options to remove from
          settings['//command_line_options:copt']
      add_copt: Optional. If not None, a compiler option string to add to the
          result if it is not already in the input.
      remove_linkopts: A list of strings for linker options to remove from
          settings['//command_line_option:linkopt']
      add_linkopt: Optional. If not None, a linker option string to add to the
          result if it is not already in the input.

    Returns:
      A copy of |settings| with the values for 'copt' and 'linkopt' updated
      according to the arguments provided.
    """
    current_copt = settings["//command_line_option:copt"]
    new_copt = _remove_options(current_copt, remove_copts)
    if add_copt != None:
        new_copt = _add_option(new_copt, add_copt)

    current_linkopt = settings["//command_line_option:linkopt"]
    new_linkopt = _remove_options(current_linkopt, remove_linkopts)
    if add_linkopt != None:
        new_linkopt = _add_option(new_linkopt, add_linkopt)

    if False:  # DEBUGGING
        print("COPT %s --> %s" % (current_copt, new_copt))
        print("LINKOPT %s --> %s" % (current_linkopt, new_linkopt))

    return {
        "//command_line_option:copt": new_copt,
        "//command_line_option:linkopt": new_linkopt,
    }

# A transition to enforce -fPIC and used to build ELF shared libraries and
# their dependencies.
def _to_elf_shared_library_transition_impl(settings, attr):
    return _modify_copt_and_linkopt_settings(
        settings,
        ["-fPIE", "-fpie", "-fpic"],
        "-fPIC",
        ["-fpie", "-pie"],
        "-shared",
    )

to_elf_shared_library_transition = transition(
    implementation = _to_elf_shared_library_transition_impl,
    inputs = _transition_inputs,
    outputs = _transition_outputs,
)

# A transition to enforce -fPIE and used to build ELF executables and their
# dependencies.
def _to_elf_executable_transition_impl(settings, attr):
    return _modify_copt_and_linkopt_settings(
        settings,
        ["-fPIC", "-fpic", "-fpie"],
        "-fPIE",
        ["-shared", "-fpic", "-fpie"],
        "-pie",
    )

to_elf_executable_transition = transition(
    implementation = _to_elf_executable_transition_impl,
    inputs = _transition_inputs,
    outputs = _transition_outputs,
)

# A rule to wrap executable targets in a transition. Required since it is
# impossible to attach a transition function to a native cc_binary()
# target using 'cfg'. Also for platforms like Fuchsia, might be a way to
# inject implicit dependencies required by the platform (e.g. libfdio.so
# and others).
def _wrap_cc_executable_impl(ctx):
    target = ctx.attr.binary_target[0]

    # A symlink to the real binary is needed for two different reasons here:
    #
    # 1) Bazel complains that: """'executable' provided by an executable rule
    #    _wrap_cc_executable' should be created by the same rule""", if the
    #    DefaultInfo provider from target is returned directly.
    #
    # 2) 'bazel build //src:program' actually doesn't build anything (Bazel
    #    just analyzes the target and decides it is up to date). This is not
    #    surprising if the target does not add any node to the action graph.
    #
    # TODO(digit): Copy or hard-link instead of symlinking to ensure that
    # 'bazel run //src:program` works?
    #
    # TODO(digit): Understand what to do for other dependencies of the
    # executable itself (e.g. data dependencies, runfiles, etc...)
    #
    output = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.symlink(
        output = output,
        target_file = ctx.files.binary_target[0],
    )
    return [
        DefaultInfo(files = depset([output])),
    ]

_wrap_cc_executable = rule(
    implementation = _wrap_cc_executable_impl,
    attrs = {
        "binary_target": attr.label(
            mandatory = True,
            doc = "Label of cc_binary() target to wrap",
            allow_files = False,
            # NOTE: Setting executable to True or False doesn't seem to
            # change anything, in both cases trying to run the program
            # with `bazel run //src:program` results in the same error:
            #
            # ERROR: Cannot run target //src:program: Not executable
            #
            executable = True,
            cfg = to_elf_executable_transition,
            providers = [DefaultInfo],
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def cc_executable(name, **kwargs):
    """Generate an executable in a build configuration that ensures -fPIE.

    This wraps cc_binary() and takes the same arguments, except for
    'linkshared' which is not allowed (and will be set to False in the
    final cc_binary() target).
    """
    if "linkshared" in kwargs:
        fail("linkshared is not allowed in cc_executable() invocation")
    native.cc_binary(
        name = name + ".binary",
        linkshared = False,
        **kwargs
    )
    _wrap_cc_executable(
        name = name,
        binary_target = name + ".binary",
    )

def _wrap_cc_import_shared_library_impl(ctx):
    target = ctx.attr.import_target[0]

    # A cc_import() target does not build anything, it just exports providers
    # to its dependents,
    return [
        target[DefaultInfo],
        target[CcInfo],
    ]

_wrap_cc_import_shared_library = rule(
    implementation = _wrap_cc_import_shared_library_impl,
    attrs = {
        "import_target": attr.label(
            mandatory = True,
            doc = "Label of cc_import() target to wrap",
            executable = False,
            allow_files = False,
            cfg = to_elf_shared_library_transition,
            providers = [DefaultInfo, CcInfo],
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def cc_shared_library(name, **kwargs):
    if "linkshared" in kwargs:
        fail("linkshared is not allowed in cc_shared_library() invocation")

    # A cc_import() target is required to link against a cc_binary() generating
    # a shared library.
    native.cc_binary(
        name = name + ".shared_library",
        linkshared = True,
        **kwargs
    )
    native.cc_import(
        name = name + ".import",
        shared_library = name + ".shared_library",
    )
    _wrap_cc_import_shared_library(
        name = name,
        import_target = name + ".import",
    )

def _file_extension_predicate(file, extensions):
    path = file.path
    for ext in extensions:
        if path.endswith(ext):
            print("FOUND %s" % path)
            return True
    return False

def _filter_outputs_impl(ctx):
    return DefaultInfo(files = depset([
        f
        for f in ctx.files.srcs
        if _file_extension_predicate(f, ctx.attr.extensions)
    ]))

filter_outputs = rule(
    implementation = _filter_outputs_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
            doc = "List of source targets whose outputs will be filtered",
        ),
        "extensions": attr.string_list(
            mandatory = True,
            doc = "List of filename extensions used to retain outputs",
        ),
    },
)

# to_unique_build_config() tries to transition to a "common" build
# configuration that matches the default one, i.e. this removes any extra
# copt and linkopt flags that may have been added by other transitions in
# this file.
def _to_unique_build_config_impl(settings, attr):
    return _modify_copt_and_linkopt_settings(
        settings,
        ["-fPIE", "-fpie", "-fpic", "-fPIC"],
        None,
        ["-fpie", "-pie", "-shared", "-fpic"],
        None,
    )

to_unique_build_config = transition(
    implementation = _to_unique_build_config_impl,
    inputs = _transition_inputs,
    outputs = _transition_outputs,
)

def _wrap_unique_genrule_impl(ctx):
    target = ctx.attr.genrule_target[0]
    return [target[DefaultInfo]]

_wrap_unique_genrule = rule(
    implementation = _wrap_unique_genrule_impl,
    attrs = {
        "genrule_target": attr.label(
            mandatory = True,
            doc = "Label of genrule() target to wrap",
            allow_files = False,
            cfg = to_unique_build_config,
            providers = [DefaultInfo],
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def unique_genrule(name, **kwargs):
    native.genrule(
        name = name + ".genrule",
        **kwargs
    )
    _wrap_unique_genrule(
        name = name,
        genrule_target = name + ".genrule",
    )
