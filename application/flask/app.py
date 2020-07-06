# Load application dependencies
import os, json
from flask import Flask
app = Flask(__name__)

# Configure application
HOST = os.environ.get("ADDRESS") or "0.0.0.0"
PORT = os.environ.get("PORT") or 3000

# Configure env vars
APP_NAME = os.environ.get("APP_NAME") or "unnamed"

# Routes
@app.route("/")
def index():
    return json.dumps({
      "sourceRepo": "kube-ci-example",
      "language": "python",
      "appName": APP_NAME
    })

@app.route("/health")
def health():
    return "OK"

# Main
if __name__ == "__main__":
    app.run(debug=True,host=HOST,port=PORT)
