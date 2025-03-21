#!/usr/bin/env python

import datetime
import logging
import os
from shutil import which
import sys

from drivers.basic import JsonTestDriver
from drivers.gnatcov import GNATcov
from drivers.pylsp import PyLSP
from drivers.shell import ShellTestDriver
from drivers.python_driver import PythonTestDriver
from e3.testsuite import Testsuite

VALGRIND_OPTIONS = [
    "--quiet",  # only print errors
    "--tool=memcheck",  # the standard tool
    "--leak-check=full",  # report memory leaks
    # "--num-callers=100",       # more frames in call stacks
    # "--gen-suppressions=all",  # use this to generate suppression entries
    "--suppressions={base}/testsuite/leaks.supp",  # the suppressions file
]


class ALSTestsuite(Testsuite):

    def add_options(self, parser):
        parser.add_argument(
            "--gnatcov",
            help="If provided, compute the source code coverage of testcases"
            " on ALS. This requires GNATcoverage working with"
            " instrumentation. The argument passed must be a directory"
            " that contains all SID files.",
        )
        parser.add_argument(
            "--gnatcov-source-root",
            help="If provided, this will be used as the --source-root gnatcov"
            " CLI argument for producing a Cobertura report with"
            " relative source paths.",
        )
        parser.add_argument(
            "--valgrind_memcheck",
            action="store_true",
            help="Runs the Ada Language Server under valgrind, in memory"
            " check mode. This requires valgrind on the PATH.",
        )
        parser.add_argument(
            "--format",
            help="""[diff | recent | verbose | min_diff]
diff: on the fly computed diff using a pseudo json format (default)
recent: recent output from server
verbose: full output from server
min_diff: on the fly computed diff of the different values
""",
        )
        parser.add_argument(
            "--debug",
            action="store_true",
            help="Start a test in debug mode where it waits until <Enter> is typed on"
            " the console before proceeding. This leaves time to attach a debugger to"
            " the ada_language_server process. The test runner prints the PID of the"
            " process on stdout but this is masked by the testsuite. So the PID must be"
            " obtained in a different way. In VS Code, a list of processes is offered"
            " and you can select the ada_language_server process that is under the"
            " .obj/ directory.",
        )

    def lookup_program(self, *args):
        """
        If os.path.join(self.repo_base, '.obj' ,*args) is the location of a
        valid file, return it.  Otherwise, return the result of
        `find_executable` for its base name.
        """
        # If the given location points to an existing file, return it
        path = os.path.join(self.env.repo_base, ".obj", *args)
        if os.path.isfile(path):
            return path
        elif os.path.isfile(path + ".exe"):
            return path + ".exe"

        # Otherwise, look for the requested program name in the PATH.
        result = which(os.path.basename(path))
        if result is None:
            raise RuntimeError(
                "Could not find executable for {}".format(os.path.basename(path))
            )
        # TODO (S710-005): for some reason, on Windows we need to strip the
        # ".exe" suffix for the tester-run program to be able to spawn ALS.
        return result[: -len(".exe")] if result.lower().endswith(".exe") else result

    def set_up(self):
        # Root directory for the "ada_language_server" repository
        self.env.repo_base = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..")
        )

        self.env.wait_factor = int(os.environ.get("ALS_WAIT_FACTOR", "1"))

        # Absolute paths to programs that test drivers can use
        if self.env.options.valgrind_memcheck:
            self.env.als = os.path.join(
                self.env.repo_base, "testsuite", "valgrind_wrapper.sh"
            )
            self.env.wait_factor = 40  # valgrind is slow
        else:
            self.env.als = self.lookup_program("server", "ada_language_server")

        self.env.als_home = os.path.join(self.env.repo_base, "testsuite")
        self.env.tester_run = self.lookup_program("tester", "tester-run")

        # If code coverage is requested, initialize our helper and build
        # instrumented programs.
        self.env.gnatcov = GNATcov(self) if self.env.options.gnatcov else None

        # Set an environment variable indicating that we are in the ALS testsuite. This
        # is used to make the ALS more verbose about errors when in the test
        # environment.
        os.environ["ALS_TESTING"] = "1"

        self.start_time = datetime.datetime.now()

    def tear_down(self):
        self.stop_time = datetime.datetime.now()
        elapsed = self.stop_time - self.start_time
        logging.info("Elapsed time: {}".format(elapsed))

        if self.env.gnatcov:
            self.env.gnatcov.report()

        super(ALSTestsuite, self).tear_down()

    @property
    def test_driver_map(self):
        return {
            "ada_lsp": JsonTestDriver,
            "shell": ShellTestDriver,
            "python": PythonTestDriver,
            "pylsp": PyLSP,
        }

    @property
    def default_driver(self):
        return "ada_lsp"


if __name__ == "__main__":
    sys.exit(ALSTestsuite().testsuite_main())
