import app
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from itsdangerous import URLSafeTimedSerializer
from flask import current_app
from app.extensions import db
import enum
from datetime import datetime, timezone
from enum import Enum
from sqlalchemy import Enum as SQLEnum
from sqlalchemy import Enum as SQLAlchemyEnum
from enum import Enum
from sqlalchemy import Enum as SQLEnum
from datetime import datetime, timezone

class Comment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(
        db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
    content_id = db.Column(db.Integer, nullable=False)
    content_type = db.Column(db.String(50), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    parent_id = db.Column(
        db.Integer, db.ForeignKey("comment.id"), nullable=True
    )  # Add this line

    # Relationships
    user = db.relationship("User", backref="comments")
    parent = db.relationship("Comment", remote_side=[id], backref="replies")

    def __repr__(self):
        return f"<Comment {self.id} Parent={self.parent_id}>"

    def to_dict(self):
        """Convert the comment to a dictionary."""
        return {
            "id": self.id,
            "content": self.content,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "content_id": self.content_id,
            "content_type": self.content_type,
            "user_id": self.user_id,
            "user": {
                "id": self.user.id,
                "username": self.user.username,
                "first_name": self.user.first_name,
                "last_name": self.user.last_name,
                "profile_picture_url": self.user.profile_picture_url or "",
            },
            "parent_id": self.parent_id,
            "replied_to": (
                {
                    "id": self.parent.user.id,
                    "username": self.parent.user.username,
                    "first_name": self.parent.user.first_name,
                    "last_name": self.parent.user.last_name,
                    "profile_picture_url": self.parent.user.profile_picture_url or "",
                }
                if self.parent_id
                else None
            ),  # If no parent_id, it's a reply to the main comment
        }

class News(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    unique_id = db.Column(db.BigInteger, unique=True, nullable=False)
    
    # Increased to handle long headlines (SEO headlines can get lengthy)
    headline = db.Column(db.String(1024), nullable=False)
    
    # Increased significantly to handle very long URLs
    link = db.Column(db.String(2048), unique=True, nullable=False)
    
    # Increased to support long image URLs (especially from cloud storage)
    image_url = db.Column(db.String(1024))
    
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    
    location = db.Column(db.String(255))
    
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"))
    user = db.relationship("User", backref="news")
    
    is_event = db.Column(db.Boolean, default=False)


class OTP(db.Model):
    __tablename__ = "otps"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(
        db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    otp = db.Column(db.String(4), nullable=False)  # Update length to 4
    expiration = db.Column(
        db.DateTime,
        nullable=False,
        default=lambda: datetime.utcnow() + timedelta(minutes=10),
    )
    last_sent = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    user = db.relationship(
        "User", backref=db.backref("otps", lazy=True, cascade="all, delete-orphan")
    )


class EmailVerification(db.Model):
    __tablename__ = "email_verifications"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(
        db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    token = db.Column(db.String(256), nullable=False, unique=True)
    expiration = db.Column(
        db.DateTime,
        nullable=False,
        default=lambda: datetime.utcnow()
        + timedelta(minutes=30),  # Link expires in 30 mins
    )

    user = db.relationship(
        "User",
        backref=db.backref(
            "email_verifications", lazy=True, cascade="all, delete-orphan"
        ),
    )


class User(db.Model, UserMixin):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(64), nullable=False)  # New field
    last_name = db.Column(db.String(64), nullable=False)  # New field
    username = db.Column(db.String(64), index=True, unique=True)
    email = db.Column(db.String(120), index=True, unique=True, nullable=True)  # Updated
    phone_number = db.Column(db.String(15), unique=True, nullable=True)  # Updated
    password_hash = db.Column(db.String(256))
    profile_picture_url = db.Column(db.String(255))
    bio = db.Column(db.Text)
    login_type = db.Column(
        db.String(20), default="normal", nullable=False
    )  # "normal" or "google"
    is_email_verified = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(
        db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
    accepted_terms_and_conditions = db.Column(db.Boolean, nullable=False, default=False)
    location = db.Column(db.String(255))
    show_home_location = db.Column(db.Boolean, default=True, nullable=False)

    @property
    def name(self) -> str:
        parts = [self.first_name or "", self.last_name or ""]
        return " ".join(part for part in parts if part).strip()

    @name.setter
    def name(self, value: str | None) -> None:
        cleaned = (value or "").strip()
        if cleaned:
            parts = cleaned.split(" ", 1)
            self.first_name = parts[0]
            self.last_name = parts[1] if len(parts) > 1 else ""
        else:
            self.first_name = ""
            self.last_name = ""

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def get_reset_token(self, expire_time=600):
        serializer = URLSafeTimedSerializer(current_app.config["SECRET_KEY"])
        token = serializer.dumps(
            {"user_id": self.id}, salt=current_app.config["PASSWORD_RESET_SALT"]
        )
        return token

    @staticmethod
    def verify_reset_token(token):
        serializer = URLSafeTimedSerializer(current_app.config["SECRET_KEY"])
        try:
            user_id = serializer.loads(
                token, salt=current_app.config["PASSWORD_RESET_SALT"], max_age=600
            )["user_id"]
        except Exception:
            return None
        return User.query.get(user_id)

    def follow(self, user):
        if not self.is_following(user):
            follow = Follow(follower_id=self.id, followed_id=user.id)
            db.session.add(follow)

    def unfollow(self, user):
        follow = self.followed.filter_by(followed_id=user.id).first()
        if follow:
            db.session.delete(follow)

    def is_following(self, user):
        return self.followed.filter_by(followed_id=user.id).count() > 0

    def followed_posts(self):
        followed = UserContent.query.join(
            Follow, (Follow.followed_id == UserContent.user_id)
        ).filter(Follow.follower_id == self.id)
        own = UserContent.query.filter_by(user_id=self.id)
        return followed.union(own).order_by(UserContent.created_at.desc())

    def block(self, user):
        if not self.is_blocking(user):
            block = Block(blocker_id=self.id, blocked_id=user.id)
            db.session.add(block)

    def unblock(self, user):
        block = self.blocked.filter_by(blocked_id=user.id).first()
        if block:
            db.session.delete(block)

    def is_blocking(self, user):
        return self.blocked.filter_by(blocked_id=user.id).count() > 0

    def bookmark(self, content_id, content_type):
        if not self.has_bookmarked(content_id, content_type):
            bookmark = Bookmark(
                user_id=self.id, content_id=content_id, content_type=content_type
            )
            db.session.add(bookmark)

    def unbookmark(self, content_id, content_type):
        bookmark = Bookmark.query.filter_by(
            user_id=self.id, content_id=content_id, content_type=content_type
        ).first()
        if bookmark:
            db.session.delete(bookmark)

    def has_bookmarked(self, content_id, content_type):
        return (
            Bookmark.query.filter_by(
                user_id=self.id, content_id=content_id, content_type=content_type
            ).count()
            > 0
        )


class ReactionType(enum.Enum):
    LIKE = "like"
    LOVE = "love"
    HAHA = "haha"
    WOW = "wow"
    SAD = "sad"
    ANGRY = "angry"


class Reaction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    content_id = db.Column(db.Integer, nullable=False)
    content_type = db.Column(db.String(64), nullable=False)
    reaction_type = db.Column(db.Enum(ReactionType), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    user = db.relationship("User", backref="reactions")

    def __repr__(self):
        return f"<Reaction {self.id} {self.reaction_type.value}>"


class UserContent(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=True)
    body = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(
        db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"))
    thumbnail = db.Column(db.String(255))
    unique_id = db.Column(db.BigInteger, unique=True)
    location = db.Column(db.String(255))  # Store the neighborhood name
    latitude = db.Column(db.Float, nullable=True)  # Store latitude
    longitude = db.Column(db.Float, nullable=True)  # Store longitude
    
    is_in_seattle = db.Column(db.Boolean, default=False)
    
    #  Fields for seeding
    news_link = db.Column(db.Text, nullable=True) 
    is_seeded = db.Column(db.Boolean, default=False)
    seed_type = db.Column(db.String, nullable=True)  # e.g. 'news', 'seed'
    seeded_likes_count = db.Column(db.Integer, default=0)
    seeded_comments_count = db.Column(db.Integer, default=0)

    user = db.relationship("User", backref="user_content")

    def __repr__(self):
        return f"<UserContent {self.id} {self.title} at {self.location}>"

    def to_dict(self):
        raw_location = (self.location or "").strip()
        if raw_location:
            location_label = " ".join(raw_location.split())
        elif self.is_in_seattle:
            location_label = "Seattle"
        else:
            location_label = "Outside Seattle - Unknown Location"

        return {
            "id": self.id,
            "title": self.title,
            "body": self.body,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "user_id": self.user_id,
            "thumbnail": self.thumbnail,
            "unique_id": self.unique_id,
            "location": self.location,
            "location_label": location_label,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "is_in_seattle": self.is_in_seattle,
            "news_link": self.news_link,
            "user": {
                "id": self.user.id,
                "first_name":self.user.first_name,
                "last_name":self.user.last_name,
                "username": self.user.username,
                "email": self.user.email,

            },
        }


class Follow(db.Model):
    __tablename__ = "follow"
    follower_id = db.Column(db.Integer, db.ForeignKey("users.id"), primary_key=True)
    followed_id = db.Column(db.Integer, db.ForeignKey("users.id"), primary_key=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<Follow follower={self.follower_id} followed={self.followed_id}>"


class Block(db.Model):
    __tablename__ = "block"
    blocker_id = db.Column(db.Integer, db.ForeignKey("users.id"), primary_key=True)
    blocked_id = db.Column(db.Integer, db.ForeignKey("users.id"), primary_key=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<Block blocker={self.blocker_id} blocked={self.blocked_id}>"


class Bookmark(db.Model):
    __tablename__ = "bookmarks"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    content_id = db.Column(db.Integer, nullable=False)
    content_type = db.Column(db.String(50), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship("User", backref="bookmarks")

    def __repr__(self):
        return f"<Bookmark user_id={self.user_id} content_id={self.content_id} content_type={self.content_type}>"


User.followed = db.relationship(
    "Follow",
    foreign_keys=[Follow.follower_id],
    backref=db.backref("follower", lazy="joined"),
    lazy="dynamic",
    cascade="all, delete-orphan",
)

User.followers = db.relationship(
    "Follow",
    foreign_keys=[Follow.followed_id],
    backref=db.backref("followed", lazy="joined"),
    lazy="dynamic",
    cascade="all, delete-orphan",
)

User.blocked = db.relationship(
    "Block",
    foreign_keys=[Block.blocker_id],
    backref=db.backref("blocker", lazy="joined"),
    lazy="dynamic",
    cascade="all, delete-orphan",
)

User.blockers = db.relationship(
    "Block",
    foreign_keys=[Block.blocked_id],
    backref=db.backref("blocked", lazy="joined"),
    lazy="dynamic",
    cascade="all, delete-orphan",
)


class CommentReaction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    content_id = db.Column(db.Integer, nullable=False)
    content_type = db.Column(db.String(64), nullable=False)
    reaction_type = db.Column(db.Enum(ReactionType), nullable=False)

    user = db.relationship("User", backref="commentreaction")

    def __repr__(self):
        return f"<CommentReaction {self.id} {self.reaction_type.value}>"


class Share(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(
        db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    content_id = db.Column(
        db.Integer, db.ForeignKey("user_content.id", ondelete="CASCADE"), nullable=False
    )

    platform = db.Column(
        db.String(50), nullable=True
    )  # E.g., 'facebook', 'twitter', 'email'
    shared_at = db.Column(
        db.DateTime, default=datetime.utcnow, nullable=False
    )  # Timestamp
    click_count = db.Column(
        db.Integer, default=0, nullable=False
    )  # Track clicks on the shared link

    user = db.relationship("User", backref="shares")  # Relationship to User
    content = db.relationship(
        "UserContent", backref="shares"
    )  # Relationship to UserContent

    def __repr__(self):
        return f"<Share user_id={self.user_id} content_id={self.content_id} platform={self.platform}>"


# Add a new column to track reposted content
reposted_by = db.relationship(
    "User",
    secondary="reposts",
    backref=db.backref("reposted_content", lazy="dynamic"),
    lazy="dynamic",
)


class Repost(db.Model):
    __tablename__ = "reposts"
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), primary_key=True)
    content_id = db.Column(
        db.Integer, db.ForeignKey("user_content.id"), primary_key=True
    )
    reposted_at = db.Column(db.DateTime, default=datetime.utcnow)
    thoughts = db.Column(db.Text, nullable=True)  # New column for user's thoughts

    def __repr__(self):
        return f"<Repost user_id={self.user_id} content_id={self.content_id}>"


class UserDeletionLog(db.Model):
    __tablename__ = "user_deletion_logs"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(
        db.Integer, db.ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reason = db.Column(db.String(255), nullable=False)
    comments = db.Column(db.Text, nullable=True)
    deleted_at = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship(
        "User",
        backref=db.backref(
            "deletion_logs", cascade="all, delete-orphan", passive_deletes=True
        ),
    )

    def __repr__(self):
        return f"<UserDeletionLog user_id={self.user_id} reason={self.reason}>"


class SearchHistory(db.Model):
    __tablename__ = "search_history"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    query = db.Column(db.String(255), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationship with User model
    user = db.relationship("User", backref="search_history")

    def __repr__(self):
        return f"<SearchHistory user_id={self.user_id} query='{self.query}'>"


class Notification(db.Model):
    __tablename__ = "notification"  # Explicitly define the table name

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)
    sender_id = db.Column(db.Integer, nullable=False)
    type = db.Column(
        db.Enum(
            "follow",
            "comment",
            "mention",
            "content_reaction",
            "comment_reaction",
            "comment_reply",
            name="notification_type",
        ),
        nullable=False,
    )
    post_id = db.Column(db.Integer, nullable=True)  # This can be null for reactions
    content = db.Column(db.Text, nullable=False)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "sender_id": self.sender_id,
            "type": self.type,
            "post_id": self.post_id,
            "content": self.content,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat(),
        }


class ReportReason(enum.Enum):
    AWS_FLAGGED = "Flagged by AWS"
    SPAM = "Spam"
    HARASSMENT = "Harassment"
    VIOLENCE = "Violence"
    INAPPROPRIATE_LANGUAGE = "Inappropriate Language"
    HATE_SPEECH = "Hate Speech"
    SEXUAL_CONTENT = "Sexual Content"
    FALSE_INFORMATION = "False Information"
    OTHER = "Other"


class ContentReport(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content_id = db.Column(db.Integer, db.ForeignKey("user_content.id"), nullable=False)
    reporter_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)  # Nullable for system/AWS-generated reports
    reason = db.Column(SQLAlchemyEnum(ReportReason), nullable=False)
    custom_reason = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    content = db.relationship("UserContent", backref="reports")
    reporter = db.relationship("User", backref="reports_made")
    
    
    # ─── AWS Moderation fields ───────────────────────────────────────────────
    aws_flagged   = db.Column(db.Boolean, default=False, nullable=False)
    aws_labels    = db.Column(db.JSON,    nullable=True)
    aws_job_id    = db.Column(db.String,  nullable=True)
    # ──────────────────────────────────────────────────────────────────────────

    def to_dict(self):
        return {
            "id": self.id,
            "content_id": self.content_id,
            "reporter_id": self.reporter_id,
            "reason": self.reason.value,
            "custom_reason": self.custom_reason,
            "created_at": self.created_at.isoformat(),
            "aws_flagged": self.aws_flagged,
            "aws_labels": self.aws_labels,
            "aws_job_id": self.aws_job_id,
        }


class HiddenContent(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    content_id = db.Column(db.Integer, db.ForeignKey("user_content.id"), nullable=False)
    hidden_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("user_id", "content_id", name="unique_user_hidden_content"),
    )

class Location(db.Model):
    __tablename__ = 'locations'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), unique=True, nullable=False)
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
    )

    def __repr__(self):
        return f"<Location {self.name}>"

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "latitude": self.latitude,
            "longitude": self.longitude,
        }


class DirectChat(db.Model):
    """
    Represents a direct (one-on-one) chat between two users.
    Ensures only one chat exists between a pair of users.
    """

    __tablename__ = "direct_chats"

    id = db.Column(db.Integer, primary_key=True)  # Unique ID for the direct chat
    user1_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False
    )  # First user in the chat
    user2_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False
    )  # Second user in the chat
    created_at = db.Column(
        db.DateTime, default=datetime.utcnow
    )  # Timestamp when the chat was created

    # Relationships
    user1 = db.relationship(
        "User", foreign_keys=[user1_id]
    )  # Links user1 to the User table
    user2 = db.relationship(
        "User", foreign_keys=[user2_id]
    )  # Links user2 to the User table

    # Relationship with messages (One-to-Many)
    messages = db.relationship(
        "DirectMessage", back_populates="chat", cascade="all, delete"
    )  # When a chat is deleted, its messages are also deleted

    # ✅ New field for soft delete (only for sender)
    deleted_for_sender = db.Column(db.Boolean, default=False)

    def to_dict(self):
        return {
            "id": self.id,
            "user1_id": self.user1_id,
            "user2_id": self.user2_id,
            "created_at": self.created_at.isoformat(),
            "messages": [message.to_dict() for message in self.messages],
        }


class DirectMessage(db.Model):
    """
    Stores messages exchanged in a direct chat between two users.
    Each message belongs to a specific DirectChat.
    """

    __tablename__ = "direct_messages"

    id = db.Column(db.Integer, primary_key=True)  # Unique ID for the message
    chat_id = db.Column(
        db.Integer, db.ForeignKey("direct_chats.id"), nullable=False
    )  # Links the message to a direct chat
    sender_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False
    )  # The user who sent the message
    content = db.Column(db.Text, nullable=False)  # Message content (text)
    created_at = db.Column(
        db.DateTime, default=datetime.utcnow
    )  # Timestamp when the message was sent

    # Relationships
    chat = db.relationship(
        "DirectChat", back_populates="messages"
    )  # Links message to its chat
    sender = db.relationship("User")  # Links sender to the User table

    def to_dict(self):
        return {
            "id": self.id,
            "chat_id": self.chat_id,
            "sender_id": self.sender_id,
            "content": self.content,
            "created_at": self.created_at.isoformat(),
            "sender": {
                "id": self.sender.id,
                "first_name": self.sender.first_name,
                "last_name": self.sender.last_name,
                "username": self.sender.username,
                "email": self.sender.email,
                "profile_picture_url": self.sender.profile_picture_url or "",
            },
        }


class GroupChat(db.Model):
    """
    Represents a group chat where multiple users can communicate.
    Groups have a name and are created by a specific user.
    """

    __tablename__ = "group_chats"

    id = db.Column(db.Integer, primary_key=True)  # Unique ID for the group chat
    name = db.Column(db.String(255), nullable=False)  # Name of the group chat
    created_by = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False
    )  # User who created the group
    created_at = db.Column(
        db.DateTime, default=datetime.utcnow
    )  # Timestamp when the group was created

    # Relationships
    messages = db.relationship(
        "GroupMessage", back_populates="group_chat", cascade="all, delete"
    )  # When a group is deleted, all its messages are deleted

    members = db.relationship(
        "GroupChatMember", back_populates="group_chat", cascade="all, delete"
    )  # When a group is deleted, all its members are removed

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "created_by": self.created_by,
            "created_at": self.created_at.isoformat(),
            "messages": [message.to_dict() for message in self.messages],
            "members": [member.to_dict() for member in self.members],
        }


class RoleEnum(Enum):
    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"


class GroupChatMember(db.Model):
    """
    Represents a user's membership in a group chat, including their role (Owner, Admin, Member).
    """

    __tablename__ = "group_chat_members"

    id = db.Column(db.Integer, primary_key=True)  # Unique membership record ID
    group_chat_id = db.Column(
        db.Integer, db.ForeignKey("group_chats.id"), nullable=False
    )  # Group chat ID
    user_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False
    )  # User ID in the group
    role = db.Column(
        SQLEnum(RoleEnum), default=RoleEnum.MEMBER, nullable=False
    )  # User's role in the group (Enum)
    joined_at = db.Column(
        db.DateTime, default=datetime.utcnow
    )  # Timestamp of when the user joined the group

    # Relationships
    group_chat = db.relationship(
        "GroupChat", back_populates="members"
    )  # Link to the group chat
    user = db.relationship("User")  # Link to the user

    def to_dict(self):
        return {
            "id": self.id,
            "group_chat_id": self.group_chat_id,
            "user_id": self.user_id,
            "role": self.role.value,  # Store Enum value as a string
            "joined_at": self.joined_at.isoformat(),
        }


class GroupMessage(db.Model):
    """
    Stores messages exchanged within a group chat.
    Each message belongs to a specific GroupChat.
    """

    __tablename__ = "group_messages"

    id = db.Column(db.Integer, primary_key=True)  # Unique ID for the message
    group_chat_id = db.Column(
        db.Integer, db.ForeignKey("group_chats.id"), nullable=False
    )  # Links message to a group chat
    sender_id = db.Column(
        db.Integer, db.ForeignKey("users.id"), nullable=False
    )  # User who sent the message
    content = db.Column(db.Text, nullable=False)  # The actual message content
    created_at = db.Column(
        db.DateTime, default=datetime.utcnow
    )  # Timestamp when the message was sent

    # Relationships
    group_chat = db.relationship(
        "GroupChat", back_populates="messages"
    )  # Links message to its group chat
    sender = db.relationship("User")  # Links sender to the User table

    # ✅ New field for soft delete (only for sender)
    deleted_for_sender = db.Column(db.Boolean, default=False)

    def to_dict(self):
        return {
            "id": self.id,
            "group_chat_id": self.group_chat_id,
            "sender_id": self.sender_id,
            "content": self.content,
            "created_at": self.created_at.isoformat(),
            "sender": {
                "id": self.sender.id,
                "first_name": self.sender.first_name,
                "last_name": self.sender.last_name,
                "username": self.sender.username,
                "profile_picture_url": self.sender.profile_picture_url
            }
        }


class WaitlistSignup(db.Model):
    __tablename__ = 'waitlist_signups'

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String, unique=True, nullable=False)
    phone = db.Column(db.String, nullable=True)
    neighborhood = db.Column(db.String, nullable=True)
    utm_source = db.Column(db.String, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.now, nullable=False)