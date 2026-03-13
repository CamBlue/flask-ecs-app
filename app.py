import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

# Read environment variables set at build time or runtime
APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
COMMIT_SHA = os.environ.get("COMMIT_SHA", "unknown")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "production")


@app.route("/")
def index():
    """Main page - shows app info and the hostname of the container."""

    hostname = socket.gethostname()
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Flask ECS App</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                max-width: 600px;
                margin: 60px auto;
                padding: 20px;
                background: #f5f5f5;
            }}
            .card {{
                background: white;
                border-radius: 8px;
                padding: 30px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }}
            .badge {{
                display: inline-block;
                background: #232f3e;
                color: white;
                padding: 4px 10px;
                border-radius: 4px;
                font-size: 12px;
                margin: 4px;
            }}
            h1 {{ color: #232f3e; }}
        </style>
    </head>
    <body>
        <div class="card">
            <h1>Flask ECS App</h1>
            <p>Deployed via GitHub Actions ? ECR ? ECS Fargate</p>
            <hr>
            <p><strong>Container Hostname:</strong> {hostname}</p>
            <p><strong>Environment:</strong> <span class="badge">{ENVIRONMENT}</span></p>
            <p><strong>Version:</strong> <span class="badge">{APP_VERSION}</span></p>
            <p><strong>Commit:</strong> <span class="badge">{COMMIT_SHA}</span></p>
            <hr>
            <p><a href="/health">Health Check</a> | <a href="/version">Version JSON</a></p>
        </div>
    </body>
    </html>
    """, 200


@app.route("/health")
def health():
    """
    Health check endpoint for the ALB target group.
    The ALB calls this every 30 seconds. If it returns anything
    other than 2xx, the task is marked unhealthy and replaced.
    Always return 200 as long as the app is running.
    """
    return jsonify({
        "status": "healthy",
        "hostname": socket.gethostname()
    }), 200


@app.route("/version")
def version():
    """Returns version metadata as JSON."""
    return jsonify({
        "version": APP_VERSION,
        "commit": COMMIT_SHA,
        "environment": ENVIRONMENT
    }), 200


if __name__ == "__main__":
    # When running directly (development), use port 5000
    # In production (Docker), Gunicorn serves the app
    app.run(host="0.0.0.0", port=5000, debug=False)
