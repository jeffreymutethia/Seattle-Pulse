import sys
import os
from sqlalchemy import text, inspect

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import create_app, db

app, _ = create_app()  # Unpack the tuple to get the Flask app instance

with app.app_context():
    # Drop all tables
    db.reflect()
    db.drop_all()
    db.session.commit()
    print("All tables dropped and database reset.")

    # Clear Alembic version tracking
    with db.engine.connect() as connection:
        inspector = inspect(connection)
        if "alembic_version" in inspector.get_table_names():
            connection.execute(text("DELETE FROM alembic_version"))
            db.session.commit()
            print("Alembic version tracking cleared.")
        else:
            print("Alembic version table does not exist.")
