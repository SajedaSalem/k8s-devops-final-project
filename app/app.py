import os

from flask import Flask, jsonify, render_template, request

from models import db, Task


def create_app(test_config=None):
    app = Flask(__name__)

    database_url = os.getenv("DATABASE_URL", "sqlite:///tasks.db")

    app.config["SQLALCHEMY_DATABASE_URI"] = database_url
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    if test_config:
        app.config.update(test_config)

    db.init_app(app)

    with app.app_context():
        db.create_all()

    @app.route("/")
    def index():
        tasks = Task.query.order_by(Task.id.desc()).all()
        return render_template("index.html", tasks=tasks)

    @app.route("/api/tasks", methods=["GET"])
    def get_tasks():
        tasks = Task.query.order_by(Task.id.asc()).all()
        return jsonify([task.to_dict() for task in tasks])

    @app.route("/api/tasks", methods=["POST"])
    def create_task():
        data = request.get_json() or {}

        title = data.get("title")
        priority = data.get("priority", "medium")

        if not title:
            return jsonify({"error": "title is required"}), 400

        if priority not in ["low", "medium", "high"]:
            return jsonify(
                {"error": "priority must be low, medium, or high"}
            ), 400

        task = Task(
            title=title,
            priority=priority,
        )

        db.session.add(task)
        db.session.commit()

        return jsonify(task.to_dict()), 201

    @app.route("/health")
    def health():
        return jsonify({"status": "healthy"}), 200

    @app.route("/ready")
    def ready():
        try:
            db.session.execute(db.text("SELECT 1"))
            return jsonify({"status": "ready"}), 200
        except Exception:
            return jsonify({"status": "not ready"}), 503

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
