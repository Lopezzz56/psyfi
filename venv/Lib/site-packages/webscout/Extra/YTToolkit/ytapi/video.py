import re
import json
from typing import Dict, Any
from .https import video_data


class Video:

    _HEAD = 'https://www.youtube.com/watch?v='

    def __init__(self, video_id: str):
        """
        Represents a YouTube video

        Parameters
        ----------
        video_id : str
            The id or url of the video
        """
        pattern = re.compile('.be/(.*?)$|=(.*?)$|^(\w{11})$')  # noqa
        match = pattern.search(video_id)

        if not match:
            raise ValueError('Invalid YouTube video ID or URL')

        self._matched_id = (
                match.group(1)
                or match.group(2)
                or match.group(3)
        )

        if self._matched_id:
            self._url = self._HEAD + self._matched_id
            self._video_data = video_data(self._matched_id)
            # Extract basic info for fallback
            title_match = re.search('<title>(.*?) - YouTube</title>', self._video_data)
            self.title = title_match.group(1) if title_match else None
            self.id = self._matched_id
        else:
            raise ValueError('Invalid YouTube video ID or URL')

    def __repr__(self):
        return f'<Video {self._url}>'

    @property
    def metadata(self) -> Dict[str, Any]:
        """
        Fetches video metadata in a dict format

        Returns
        -------
        Dict
            Video metadata in a dict format containing keys: title, id, views, duration, author_id,
            upload_date, url, thumbnails, tags, description, likes, genre, etc.
        """
        # Multiple patterns to try for video details extraction for robustness
        details_patterns = [
            re.compile('videoDetails\":(.*?)\"isLiveContent\":.*?}'),
            re.compile('videoDetails\":(.*?),\"playerConfig'),
            re.compile('videoDetails\":(.*?),\"playabilityStatus')
        ]

        # Other metadata patterns
        upload_date_pattern = re.compile("<meta itemprop=\"uploadDate\" content=\"(.*?)\">")
        genre_pattern = re.compile("<meta itemprop=\"genre\" content=\"(.*?)\">")
        like_count_patterns = [
            re.compile("iconType\":\"LIKE\"},\"defaultText\":(.*?)}"),
            re.compile('\"likeCount\":\"(\\d+)\"')
        ]
        channel_name_pattern = re.compile('"ownerChannelName":"(.*?)"')

        # Try each pattern for video details
        raw_details_match = None
        for pattern in details_patterns:
            match = pattern.search(self._video_data)
            if match:
                raw_details_match = match
                break

        if not raw_details_match:
            # Fallback metadata for search results or incomplete video data
            return {
                'title': getattr(self, 'title', None),
                'id': getattr(self, 'id', None),
                'views': getattr(self, 'views', None),
                'streamed': False,
                'duration': None,
                'author_id': None,
                'author_name': None,
                'upload_date': None,
                'url': f"https://www.youtube.com/watch?v={getattr(self, 'id', '')}" if hasattr(self, 'id') else None,
                'thumbnails': None,
                'tags': None,
                'description': None,
                'likes': None,
                'genre': None,
                'is_age_restricted': 'age-restricted' in self._video_data.lower(),
                'is_unlisted': 'unlisted' in self._video_data.lower()
            }

        raw_details = raw_details_match.group(0)

        # Extract upload date
        upload_date_match = upload_date_pattern.search(self._video_data)
        upload_date = upload_date_match.group(1) if upload_date_match else None

        # Extract channel name
        channel_name_match = channel_name_pattern.search(self._video_data)
        channel_name = channel_name_match.group(1) if channel_name_match else None

        # Parse video details
        try:
            # Clean up the JSON string for parsing
            clean_json = raw_details.replace('videoDetails\":', '')
            # Handle potential JSON parsing issues
            if clean_json.endswith(','):
                clean_json = clean_json[:-1]
            metadata = json.loads(clean_json)

            data = {
                'title': metadata.get('title'),
                'id': metadata.get('videoId', self._matched_id),
                'views': metadata.get('viewCount'),
                'streamed': metadata.get('isLiveContent', False),
                'duration': metadata.get('lengthSeconds'),
                'author_id': metadata.get('channelId'),
                'author_name': channel_name or metadata.get('author'),
                'upload_date': upload_date,
                'url': f"https://www.youtube.com/watch?v={metadata.get('videoId', self._matched_id)}",
                'thumbnails': metadata.get('thumbnail', {}).get('thumbnails'),
                'tags': metadata.get('keywords'),
                'description': metadata.get('shortDescription'),
                'is_age_restricted': metadata.get('isAgeRestricted', False) or 'age-restricted' in self._video_data.lower(),
                'is_unlisted': 'unlisted' in self._video_data.lower(),
                'is_family_safe': metadata.get('isFamilySafe', True),
                'is_private': metadata.get('isPrivate', False),
                'is_live_content': metadata.get('isLiveContent', False),
                'is_crawlable': metadata.get('isCrawlable', True),
                'allow_ratings': metadata.get('allowRatings', True)
            }
        except (json.JSONDecodeError, KeyError, TypeError) as e:
            # Fallback to basic metadata if JSON parsing fails
            return {
                'title': getattr(self, 'title', None),
                'id': self._matched_id,
                'url': self._url,
                'error': f"Failed to parse video details: {str(e)}"
            }

        # Try to extract likes count
        likes = None
        for pattern in like_count_patterns:
            try:
                likes_match = pattern.search(self._video_data)
                if likes_match:
                    likes_text = likes_match.group(1)
                    # Handle different formats of like count
                    if '{' in likes_text:
                        likes = json.loads(likes_text + '}}}')['accessibility']['accessibilityData']['label'].split(' ')[0].replace(',', '')
                    else:
                        likes = likes_text
                    break
            except (AttributeError, KeyError, json.decoder.JSONDecodeError):
                continue

        data['likes'] = likes

        # Try to extract genre
        try:
            genre_match = genre_pattern.search(self._video_data)
            data['genre'] = genre_match.group(1) if genre_match else None
        except AttributeError:
            data['genre'] = None

        return data



    @property
    def embed_html(self) -> str:
        """
        Get the embed HTML code for this video

        Returns:
            HTML iframe code for embedding the video
        """
        return f'<iframe width="560" height="315" src="https://www.youtube.com/embed/{self._matched_id}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>'

    @property
    def embed_url(self) -> str:
        """
        Get the embed URL for this video

        Returns:
            URL for embedding the video
        """
        return f'https://www.youtube.com/embed/{self._matched_id}'

    @property
    def thumbnail_url(self) -> str:
        """
        Get the thumbnail URL for this video

        Returns:
            URL of the video thumbnail (high quality)
        """
        return f'https://i.ytimg.com/vi/{self._matched_id}/hqdefault.jpg'

    @property
    def thumbnail_urls(self) -> Dict[str, str]:
        """
        Get all thumbnail URLs for this video in different qualities

        Returns:
            Dictionary of thumbnail URLs with quality labels
        """
        return {
            'default': f'https://i.ytimg.com/vi/{self._matched_id}/default.jpg',
            'medium': f'https://i.ytimg.com/vi/{self._matched_id}/mqdefault.jpg',
            'high': f'https://i.ytimg.com/vi/{self._matched_id}/hqdefault.jpg',
            'standard': f'https://i.ytimg.com/vi/{self._matched_id}/sddefault.jpg',
            'maxres': f'https://i.ytimg.com/vi/{self._matched_id}/maxresdefault.jpg'
        }

if __name__ == '__main__':
    video = Video('https://www.youtube.com/watch?v=9bZkp7q19f0')
    print(video.metadata)

    # Example of getting comments
    print("\nFirst 3 comments:")
    for i, comment in enumerate(video.stream_comments(3), 1):
        print(f"{i}. {comment['author']}: {comment['text'][:50]}...")
