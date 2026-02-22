"""Production WSGI entry-point for ClawMetry.

Runs all one-time initialisation (config detection, metrics loading,
background threads) from dashboard.main() then exposes the Flask ``app``
object for gunicorn to serve.  Flask's built-in Werkzeug development server
is never started.
"""
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
