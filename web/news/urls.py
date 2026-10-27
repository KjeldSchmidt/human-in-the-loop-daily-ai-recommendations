from django.urls import path

from news import views

urlpatterns = [
    path("", views.landing, name="landing"),
    path("oauth/popup-done/", views.oauth_popup_done, name="oauth_popup_done"),
    path("brief/", views.brief, name="brief"),
    path("feeds/", views.feeds, name="feeds"),
    path("feeds/<int:feed_id>/subscribe/", views.subscribe, name="subscribe"),
    path("feeds/<int:feed_id>/unsubscribe/", views.unsubscribe, name="unsubscribe"),
    path("articles/<int:article_id>/feedback/", views.feedback, name="feedback"),
    path("followups/", views.followups, name="followups"),
    path(
        "followups/<int:question_id>/answer/",
        views.answer_followup,
        name="answer_followup",
    ),
]
