from flask import Flask, jsonify, request
from .models import News, Event, UserContent
from . import app
import config as config
import requests


@app.route("/load-more-news")
def load_more_news():
    page = request.args.get("page", 1, type=int)
    news = News.query.order_by(News.timestamp.asc()).paginate(page=page, per_page=10)
    # Convert news items to JSON-serializable format
    news_items = [
        {"title": item.title, "description": item.description} for item in news.items
    ]
    return jsonify(news_items)


@app.route("/load-more-user-content")
def load_more_user_content():
    page = request.args.get("page", 1, type=int)
    user_contents = UserContent.query.order_by(UserContent.created_at.asc()).paginate(
        page=page, per_page=10
    )
    # Convert user content items to JSON-serializable format
    user_content_items = [
        {"title": item.title, "story": item.story} for item in user_contents.items
    ]
    return jsonify(user_content_items)
