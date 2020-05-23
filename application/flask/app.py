# Load application dependencies
from flask import Flask
from os import environ
from json import dumps
app = Flask(__name__)

# Configure application
HOST = environ.get("ADDRESS") or "0.0.0.0"
PORT = environ.get("PORT") or 3000

# Configure env vars
NAME = environ.get("NAME") or "unnamed"

# Routes
@app.route("/")
def index():
    return dumps({
      "sourceRepo": "kube-ci-example",
      "language": "python",
      "appName": NAME
    })

@app.route("/health")
def health():
    return "OK"

# Main
if __name__ == "__main__":
    app.run(debug=True,host=HOST,port=PORT)