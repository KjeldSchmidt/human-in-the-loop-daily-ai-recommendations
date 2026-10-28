from django.test import TestCase, override_settings

from news.models import Feed


@override_settings(INTERNAL_API_TOKEN="test-internal-token")
class InternalFeedsApiTests(TestCase):
    def setUp(self) -> None:
        self.feed = Feed.objects.create(
            title="BBC World",
            url="https://feeds.bbci.co.uk/news/world/rss.xml",
            site_url="https://www.bbc.com/news/world",
            category="World",
            kind=Feed.SourceKind.CURATED,
        )

    def test_list_feeds_requires_token(self) -> None:
        response = self.client.get("/api/internal/feeds/")
        self.assertEqual(response.status_code, 401)

    def test_list_feeds_rejects_bad_token(self) -> None:
        response = self.client.get(
            "/api/internal/feeds/",
            headers={"Authorization": "Bearer wrong"},
        )
        self.assertEqual(response.status_code, 401)

    def test_list_feeds_with_bearer_token(self) -> None:
        response = self.client.get(
            "/api/internal/feeds/",
            headers={"Authorization": "Bearer test-internal-token"},
        )
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(len(payload["feeds"]), 1)
        self.assertEqual(payload["feeds"][0]["id"], self.feed.id)
        self.assertEqual(payload["feeds"][0]["url"], self.feed.url)
        self.assertTrue(payload["feeds"][0]["is_active"])

    def test_list_feeds_with_x_internal_token_header(self) -> None:
        response = self.client.get(
            "/api/internal/feeds/",
            headers={"X-Internal-Token": "test-internal-token"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()["feeds"]), 1)

    @override_settings(INTERNAL_API_TOKEN="")
    def test_list_feeds_unconfigured(self) -> None:
        response = self.client.get(
            "/api/internal/feeds/",
            headers={"Authorization": "Bearer anything"},
        )
        self.assertEqual(response.status_code, 503)
