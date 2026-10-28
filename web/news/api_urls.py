from django.urls import path

from news import api

urlpatterns = [
    path("feeds/", api.list_feeds, name="internal_list_feeds"),
]
