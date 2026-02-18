from celery import Celery
from datetime import timedelta

def make_celery(app):
    celery = Celery(
        app.import_name,
        broker=app.config["broker_url"],
        backend=app.config["result_backend"],
    )
    celery.conf.update(app.config)

    # Configure Celery beat schedule for periodic tasks
    celery.conf.beat_schedule = {
        "fetch-news-every-3mins": {
            "task": "app.fetchers.news_fetcher.fetch_data",
            "schedule": timedelta(minutes=3),
            "args": (app.config.get("NEWS_SOURCE"),),
        },
    }

    return celery