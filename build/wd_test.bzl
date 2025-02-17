def wd_test(
        src,
        data = [],
        name = None,
        args = [],
        **kwargs):
    """Rule to define tests that run `workerd test` with a particular config.

    Args:
     src: A .capnp config file defining the test. (`name` will be derived from this if not
        specified.) The extension `.wd-test` is also permitted instead of `.capnp`, in order to
        avoid confusing other build systems that may assume a `.capnp` file should be complied.
     data: Files which the .capnp config file may embed. Typically JavaScript files.
     args: Additional arguments to pass to `workerd`. Typically used to pass `--experimental`.
    """

    # Add workerd binary to "data" dependencies.
    data = data + [src, "//src/workerd/server:workerd"]

    # Add initial arguments for `workerd test` command.
    args = [
        "$(location //src/workerd/server:workerd)",
        "test",
        "$(location {})".format(src),
    ] + args

    # Default name based on src.
    if name == None:
        name = src.removesuffix(".capnp").removesuffix(".wd-test")

    _wd_test(
        name = name,
        data = data,
        args = args,
        **kwargs
    )

def _wd_test_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._platforms_os_windows[platform_common.ConstraintValueInfo])

    # Bazel insists that the rule must actually create the executable that it intends to run; it
    # can't just specify some other executable with some args. OK, fine, we'll use a script that
    # just execs its args.
    if is_windows:
        # Batch script executables must end with ".bat"
        executable = ctx.actions.declare_file("%s_wd_test.bat" % ctx.label.name)
        ctx.actions.write(
            output = executable,
            # PowerShell correctly handles forward slashes in executable paths generated by Bazel (e.g. "bazel-bin/src/workerd/server/workerd.exe")
            content = "powershell -Command \"%*\" `-dTEST_TMPDIR=$ENV:TEST_TMPDIR\r\n",
            is_executable = True,
        )
    else:
        executable = ctx.outputs.executable
        ctx.actions.write(
            output = executable,
            content = "#! /bin/sh\nexec \"$@\" -dTEST_TMPDIR=$TEST_TMPDIR\n",
            is_executable = True,
        )

    return [
        DefaultInfo(
            executable = executable,
            runfiles = ctx.runfiles(files = ctx.files.data),
        ),
    ]

_wd_test = rule(
    implementation = _wd_test_impl,
    test = True,
    attrs = {
        "workerd": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            default = "//src/workerd/server:workerd",
        ),
        "flags": attr.string_list(),
        "data": attr.label_list(allow_files = True),
        "_platforms_os_windows": attr.label(default = "@platforms//os:windows"),
    },
)
