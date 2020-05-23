/**
 * Load application dependencies.
 */
// Express and dependencies
const express = require("express");
const logger = require("morgan");
const createError = require("http-errors");
const app = express();

/**
 * Configure application
 */
app.set("host", process.env.ADDRESS || "0.0.0.0");
app.set("port", process.env.PORT || 3000);

/**
 * Configure env vars
 */
const NAME = process.env.NAME || "unnamed";

/**
 * Configure middleware
 */
process.env.MUTE_LOGGER === "true" ? null : app.use(logger("combined"));

/**
 * Configure returns
 */
app.get("/", (req, res) => {
  res.send({
    sourceRepo: "kube-ci-example",
    language: "javascript",
    appName: NAME
  });
});

app.get("/health", (req, res) => {
  res.send({
    status: "OK"
  });
});

/** 
 * Configure error handling
 */
// Return 404 if no path found
app.use((req, res, next) => {
  next(createError(404));
});

// Send the error back to the client
app.use((err, req, res, next) => {
  res.status(err.status || 500);
  res.send({
    message: err.status < 500 || app.get("env") == "development" ? err.message : "Internal server error"
  });
});

/**
 * Start application
 */
// Start the application and report the listening address:port
app.listen(app.get("port"), app.get("host"), () => {
  console.log(`Listening on ${app.get("host")}:${app.get("port")}`);
});

// Export the application
module.exports = app;