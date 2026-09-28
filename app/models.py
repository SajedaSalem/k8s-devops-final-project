from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)

    title = db.Column(
        db.String(200),
        nullable=False
    )

    completed = db.Column(
        db.Boolean,
        default=False,
        nullable=False
    )

    priority = db.Column(
        db.String(10),
        default="medium",
        nullable=False
    )

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "completed": self.completed,
            "priority": self.priority,
        }
