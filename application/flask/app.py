# -*- coding: utf-8 -*-
"""
This is a simple Flask application which exposes an index page with
bare information and a health endpoint that says OK.
"""

# Load application dependencies
import os
import json
from flask import Flask
app = Flask(__name__)

# Configure application
HOST = os.environ.get('ADDRESS') or '0.0.0.0'
PORT = os.environ.get('PORT') or 3000

# Configure env vars
APP_NAME = os.environ.get('APP_NAME') or 'unnamed'

# Routes
@app.route('/')
def index():
    """
    Returns a small JSON payload with some information.
    """
    data = json.dumps({
        'sourceRepo': 'kube-ci-example',
        'language': 'python',
        'appName': APP_NAME
    })
    return data

@app.route('/health')
def health():
    """
    Returns OK.
    """
    return 'OK'

# Main
if __name__ == '__main__':
    app.run(
        debug=True,
        host=HOST,
        port=PORT
    )
