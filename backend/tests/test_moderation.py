import pytest
from utils.aws_moderation import moderate_text

@pytest.mark.parametrize("text,should_flag", [
    ("You are an idiot and I hate you", True),
    ("Let’s meet for coffee tomorrow morning", False),
    ("Go kill yourself", True),         # self-harm / violent
    ("Happy birthday to you!", False),
])
def test_moderate_text(text, should_flag):
    labels = moderate_text(text, threshold=0.7)
    assert (len(labels) > 0) == should_flag
