"""Production WSGI entry-point for ClawMetry.

Runs all one-time initialisation (config detection, metrics loading,
background threads) from dashboard.main() then exposes the Flask ``app``
object for gunicorn to serve.  Flask's built-in Werkzeug development server
is never started.
"""
import logging
import sys

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

# Ensure ClawMetry log records reach Docker's log stream alongside gunicorn's
# own output.  gunicorn configures only its own loggers; without an explicit
# handler the root logger is silent for INFO-level records.  We add a stderr
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
