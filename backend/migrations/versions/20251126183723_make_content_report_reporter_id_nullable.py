"""make content_report reporter_id nullable

Revision ID: 20251126183723
Revises: dcc5a05d2b56
Create Date: 2025-11-26 18:37:23.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '20251126183723'
down_revision = 'dcc5a05d2b56'
branch_labels = None
depends_on = None


def upgrade():
    # Make reporter_id nullable to allow system/AWS-generated reports
    op.alter_column('content_report', 'reporter_id',
                    existing_type=sa.Integer(),
                    nullable=True)


def downgrade():
    # Revert to non-nullable (but this will fail if there are NULL values)
    op.alter_column('content_report', 'reporter_id',
                    existing_type=sa.Integer(),
                    nullable=False)

