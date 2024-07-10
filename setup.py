# Guix's python-build-system uses setup.py by default.

# setup.py was made optional in April 2019 with Setuptools v40.0.9
# (https://setuptools.pypa.io/en/latest/history.html#v40-9-0) for projects that
# have a PEP 517 `build-backend` key in pyproject.toml. A newer version of
# Setuptools is available in current Debian Stable (Bookworm) and Old Stable (Bullseye).
#
# setup.py otherwise is only needed for `--editable` support a.k.a ("development
# mode") when using Pip < 21.1
# (https://setuptools.pypa.io/en/latest/userguide/quickstart.html#development-mode). Debian
# Stable (Bookworm) currently has a newer version than this, but not Old Stable
# (Bullseye).

import setuptools

setuptools.setup()
