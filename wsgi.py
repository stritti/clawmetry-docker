"""Production WSGI entry-point for ClawMetry.

Runs all one-time initialisation (config detection, metrics loading,
background threads) from dashboard.main() then exposes the Flask ``app``
object for gunicorn to serve.  Flask's built-in Werkzeug development server
is never started.
"""
import logging
import os
import sys

# Ensure ClawMetry log records reach Docker's log stream alongside gunicorn's
# own output.  Install the StreamHandler on the root logger BEFORE calling
# main() so that every logger created during initialisation propagates to it.
# gunicorn configures only its own loggers; without an explicit handler the
# root logger is silent for INFO-level records.  We add a stderr
# StreamHandler only when none is already present so we don't duplicate output
# if ClawMetry has already attached one.
_root_logger = logging.getLogger()
if not any(
    isinstance(h, logging.StreamHandler)
    and getattr(h, "stream", None) in (sys.stdout, sys.stderr)
    for h in _root_logger.handlers
):
    _handler = logging.StreamHandler(sys.stderr)
    _handler.setFormatter(
        logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s")
    )
    _root_logger.addHandler(_handler)
    if _root_logger.level == logging.NOTSET:
        _root_logger.setLevel(logging.INFO)

# Temporarily replace app.run() with a no-op so that dashboard.main()
# performs all initialisation without launching the Werkzeug dev-server.
# Gunicorn calls the WSGI callable directly and owns the listening socket.
from flask import Flask as _Flask
_original_run = _Flask.run
_Flask.run = lambda *a, **kw: None  # type: ignore[method-assign]

# Use a minimal argv so that dashboard.main()'s argparse uses
# environment-variable defaults for all configuration
# (OPENCLAW_DATA_DIR, OPENCLAW_HOME, OPENCLAW_LOG_DIR, …).
sys.argv = ["clawmetry", "--no-debug"]

from dashboard import main, app  # noqa: E402  (must import after patches above)

main()  # detect_config, load metrics, start background threads; app.run() is a no-op

# Restore Flask.run to avoid interfering with other code that may inspect it.
_Flask.run = _original_run  # type: ignore[method-assign]

# Optional: run ClawMetry at a URL subpath (e.g. /stats) so that Flask
# generates correct asset and API URLs when reverse-proxied by Traefik.
# Set the SCRIPT_NAME environment variable to the desired prefix, for example:
#   SCRIPT_NAME=/stats
# Traefik must also strip that prefix before forwarding requests here
# (use the stripprefix middleware — see docker-compose.traefik.yml).
_script_name = os.environ.get("SCRIPT_NAME", "").rstrip("/")
if _script_name:
    _inner_app = app.wsgi_app

    def _with_script_name(environ, start_response):
        environ["SCRIPT_NAME"] = _script_name
        path_info = environ.get("PATH_INFO", "")
        if path_info == _script_name or path_info.startswith(_script_name + "/"):
            environ["PATH_INFO"] = path_info[len(_script_name):] or "/"
        return _inner_app(environ, start_response)

    app.wsgi_app = _with_script_name  # type: ignore[method-assign]
