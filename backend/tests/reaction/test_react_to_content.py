# import pytest
# from unittest.mock import patch, MagicMock
# from flask import url_for
# from app.models import User, UserContent, News, Reaction, ReactionType


# @pytest.fixture
# def client(app):
#     """Provide a test client."""
#     return app.test_client()


# @patch("flask_login.utils._get_user")
# @patch("app.models.Reaction.query")
# @patch("app.models.News.query")
# @patch("app.models.UserContent.query")
# @patch("app.models.db.session.commit")
# def test_react_to_news_content(
#     mock_db_commit,
#     mock_user_content_query,
#     mock_news_query,
#     mock_reaction_query,
#     mock_get_user,
#     client,
# ):
#     """Test reacting to a news content item."""

#     # ✅ Mock current user
#     mock_user = MagicMock(spec=User)
#     mock_user.id = 1
#     mock_get_user.return_value = mock_user

#     # ✅ Mock news content
#     mock_news = MagicMock(spec=News, unique_id="news123")
#     mock_news_query.filter_by.return_value.first.return_value = mock_news

#     # ✅ Mock reaction query (no existing reaction)
#     mock_reaction_query.filter_by.return_value.first.return_value = None

#     # 🔥 Send request
#     response = client.post(
#         url_for(
#             "reaction_v1.react_to_content", content_type="news", content_id="news123"
#         ),
#         json={"reaction_type": "like"},
#     )

#     # ✅ Validate response
#     assert response.status_code == 200, f"Unexpected response: {response.get_json()}"
#     data = response.get_json()
#     assert data["status"] == "success"
#     assert data["message"] == "Reaction added successfully"


# @patch("flask_login.utils._get_user")
# @patch("app.models.Reaction.query")
# @patch("app.models.UserContent.query")
# @patch("app.models.db.session.commit")
# def test_react_to_user_content(
#     mock_db_commit, mock_user_content_query, mock_reaction_query, mock_get_user, client
# ):
#     """Test reacting to user content."""

#     # ✅ Mock current user
#     mock_user = MagicMock(spec=User)
#     mock_user.id = 1
#     mock_get_user.return_value = mock_user

#     # ✅ Mock user content
#     mock_content = MagicMock(spec=UserContent, id=42)
#     mock_user_content_query.filter_by.return_value.first.return_value = mock_content

#     # ✅ Mock reaction query (no existing reaction)
#     mock_reaction_query.filter_by.return_value.first.return_value = None

#     # 🔥 Send request
#     response = client.post(
#         url_for(
#             "reaction_v1.react_to_content", content_type="user_content", content_id=42
#         ),
#         json={"reaction_type": "love"},
#     )

#     # ✅ Validate response
#     assert response.status_code == 200
#     data = response.get_json()
#     assert data["status"] == "success"
#     assert data["message"] == "Reaction added successfully"


# @patch("flask_login.utils._get_user")
# @patch("app.models.Reaction.query")
# @patch("app.models.UserContent.query")
# @patch("app.models.db.session.commit")
# def test_update_existing_reaction(
#     mock_db_commit, mock_user_content_query, mock_reaction_query, mock_get_user, client
# ):
#     """Test updating an existing reaction."""

#     # ✅ Mock current user
#     mock_user = MagicMock(spec=User)
#     mock_user.id = 1
#     mock_get_user.return_value = mock_user

#     # ✅ Mock user content
#     mock_content = MagicMock(spec=UserContent, id=42)
#     mock_user_content_query.filter_by.return_value.first.return_value = mock_content

#     # ✅ Mock existing reaction (user previously liked the content)
#     mock_reaction = MagicMock(spec=Reaction, reaction_type=ReactionType.LIKE)
#     mock_reaction_query.filter_by.return_value.first.return_value = mock_reaction

#     # 🔥 Send request to change reaction to "love"
#     response = client.post(
#         url_for(
#             "reaction_v1.react_to_content", content_type="user_content", content_id=42
#         ),
#         json={"reaction_type": "love"},
#     )

#     # ✅ Validate response
#     assert response.status_code == 200
#     data = response.get_json()
#     assert data["status"] == "success"
#     assert data["message"] == "Reaction updated successfully"


# @patch("flask_login.utils._get_user")
# @patch("app.models.Reaction.query")
# @patch("app.models.UserContent.query")
# @patch("app.models.db.session.commit")
# def test_remove_existing_reaction(
#     mock_db_commit, mock_user_content_query, mock_reaction_query, mock_get_user, client
# ):
#     """Test removing an existing reaction (unreact)."""

#     # ✅ Mock current user
#     mock_user = MagicMock(spec=User)
#     mock_user.id = 1
#     mock_get_user.return_value = mock_user

#     # ✅ Mock user content
#     mock_content = MagicMock(spec=UserContent, id=42)
#     mock_user_content_query.filter_by.return_value.first.return_value = mock_content

#     # ✅ Mock existing reaction
#     mock_reaction = MagicMock(spec=Reaction, reaction_type=ReactionType.LIKE)
#     mock_reaction_query.filter_by.return_value.first.return_value = mock_reaction

#     # 🔥 Send request to remove reaction
#     response = client.post(
#         url_for(
#             "reaction_v1.react_to_content", content_type="user_content", content_id=42
#         ),
#         json={"reaction_type": "like"},
#     )

#     # ✅ Validate response
#     assert response.status_code == 200
#     data = response.get_json()
#     assert data["status"] == "success"
#     assert data["message"] == "Reaction removed successfully"


# @patch("flask_login.utils._get_user")
# @patch("app.models.UserContent.query")
# def test_react_to_non_existent_content(mock_user_content_query, mock_get_user, client):
#     """Test reacting to a non-existent content item."""

#     # ✅ Mock current user
#     mock_user = MagicMock(spec=User)
#     mock_get_user.return_value = mock_user

#     # ❌ Simulate content not found
#     mock_user_content_query.filter_by.return_value.first.return_value = None

#     response = client.post(
#         url_for(
#             "reaction_v1.react_to_content", content_type="user_content", content_id=999
#         ),
#         json={"reaction_type": "like"},
#     )

#     # ✅ Validate response
#     assert response.status_code == 404
#     data = response.get_json()
#     assert data["status"] == "error"
#     assert data["message"] == "Content not found"


# @patch("flask_login.utils._get_user")
# @patch("app.models.UserContent.query")
# def test_invalid_reaction_type(mock_user_content_query, mock_get_user, client):
#     """Test sending an invalid reaction type."""

#     # ✅ Mock current user
#     mock_user = MagicMock(spec=User)
#     mock_get_user.return_value = mock_user

#     # ✅ Mock user content
#     mock_content = MagicMock(spec=UserContent, id=42)
#     mock_user_content_query.filter_by.return_value.first.return_value = mock_content

#     response = client.post(
#         url_for(
#             "reaction_v1.react_to_content", content_type="user_content", content_id=42
#         ),
#         json={"reaction_type": "invalid_reaction"},
#     )

#     # ✅ Validate response
#     assert response.status_code == 400


# @patch("flask_login.utils._get_user")
# @patch("app.models.db.session.commit")
# def test_database_commit_error(mock_db_commit, mock_get_user, client):
#     """Test handling of database commit error."""

#     mock_user = MagicMock(spec=User)
#     mock_get_user.return_value = mock_user

#     # ❌ Simulate DB error
#     mock_db_commit.side_effect = Exception("DB commit failed")

#     response = client.post(
#         url_for(
#             "reaction_v1.react_to_content", content_type="user_content", content_id=42
#         ),
#         json={"reaction_type": "like"},
#     )

#     # ✅ Validate response
#     assert response.status_code == 500
