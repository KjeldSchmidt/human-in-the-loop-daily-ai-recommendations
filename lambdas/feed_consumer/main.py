import feedparser
from dataclasses import dataclass
from datetime import datetime

@dataclass
class FeedItem:
    id: str
    link: str
    thumbnail: str
    date: datetime
    title: str
    description: str

d = feedparser.parse("https://feeds.bbci.co.uk/news/world/rss.xml")

items = []
for entry in d.entries:
    item = FeedItem(
        id=entry.id,
        link=entry.link,
        thumbnail=entry.media_thumbnail[0]['url'],
        date=datetime(*entry.published_parsed[:6]),
        title=entry.title,
        description=f"{entry.title} - {entry.summary_detail.value}",
    )
    items.append(item)

breakpoint()