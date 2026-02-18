# app/utils/aws_moderation.py

import boto3
from flask import current_app

def get_comprehend_client():
    return boto3.client(
        'comprehend',
        region_name=current_app.config['AWS_REGION']
    )

def moderate_text(text: str, threshold: float = 0.7):
    """
    Call AWS Comprehend Toxicity Detection.
    Returns list of labels above `threshold`.
    """
    client = get_comprehend_client()
    resp = client.detect_toxic_content(
        TextSegments=[{ "Text": text }],   # <-- corrected
        LanguageCode='en'
    )
    # pull out the labels for this single segment
    labels = resp['ResultList'][0]['Labels']
    # only keep ones above your cutoff
    return [lbl for lbl in labels if lbl['Score'] >= threshold]
