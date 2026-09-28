from app import create_app
from models import db, Task


app = create_app()


sample_tasks = [
    ("Set up Kubernetes cluster", "high"),
    ("College Assignments", "high"),
    ("Write Ansible playbooks", "high"),
    ("Finish final project", "high"),
    ("CKA prep", "medium"),
    ("Chores", "medium"),
    ("Tutoring", "medium"),
    ("Fix sleep schedule", "medium"),
    ("Build CI/CD pipeline", "high"),
    ("Update README documentation", "low"),
]


with app.app_context():
    Task.query.delete()

    for title, priority in sample_tasks:
        task = Task(
            title=title,
            priority=priority,
        )
        db.session.add(task)

    db.session.commit()

    print("10 sample tasks added successfully.")
