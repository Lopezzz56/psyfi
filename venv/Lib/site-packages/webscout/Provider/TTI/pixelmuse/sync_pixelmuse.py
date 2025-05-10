import requests
import os
from typing import Union, List
from string import punctuation
from random import choice

from webscout.AIbase import ImageProvider
from webscout.litagent import LitAgent

class PixelMuseImager(ImageProvider):
    """
    PixelMuse Image Provider - Create stunning AI art with PixelMuse! 🎨
    """
    
    AVAILABLE_MODELS = [
        "flux-schnell",
        "imagen-3-fast",
        "imagen-3",
        "recraft-v3"
    ]

    def __init__(
        self,
        model: str = "flux-schnell",
        timeout: int = 60,
        proxies: dict = {},
    ):
        """Initialize your PixelMuse provider with custom settings! ⚙️

        Args:
            model (str): Which model to use (default: flux-schnell)
            timeout (int): Request timeout in seconds (default: 60)
            proxies (dict): Proxy settings for requests (default: {})
            logging (bool): Enable fire logging (default: True)
        """
        self.api_endpoint = "https://www.pixelmuse.studio/api/predictions"
        self.headers = {
            "accept": "*/*",
            "accept-language": "en-US,en;q=0.9",
            "content-type": "application/json",
            "origin": "https://www.pixelmuse.studio",
            "referer": "https://www.pixelmuse.studio/",
            "sec-ch-ua": '"Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"',
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"Windows"',
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "user-agent": LitAgent().random(),
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        self.session.proxies.update(proxies)
        self.timeout = timeout
        self.model = model
        self.prompt: str = "AI-generated image - webscout"
        self.image_extension: str = "webp"

    def generate(
        self, prompt: str, amount: int = 1,
        max_retries: int = 3, retry_delay: int = 5,
        style: str = "none", aspect_ratio: str = "1:1"
    ) -> List[bytes]:
        """Generate some amazing images from your prompt! 🎨

        Args:
            prompt (str): Your creative prompt
            amount (int): How many images to generate
            max_retries (int): Max retry attempts if generation fails
            retry_delay (int): Seconds to wait between retries
            style (str): Style to apply (default: "none")
            aspect_ratio (str): Aspect ratio (default: "1:1")

        Returns:
            List[bytes]: Your generated images as bytes
        """
        assert bool(prompt), "Prompt cannot be empty."
        assert isinstance(amount, int) and amount > 0, "Amount must be a positive integer."

        self.prompt = prompt
        response = []
        
        for _ in range(amount):
            for attempt in range(max_retries):
                try:
                    with self.session.post(
                        self.api_endpoint,
                        json=self._create_payload(prompt, self.model, style, aspect_ratio),
                        timeout=self.timeout
                    ) as resp:
                        resp.raise_for_status()
                        data = resp.json()

                        if 'output' in data and len(data['output']) > 0:
                            image_url = data['output'][0]
                            # Get the image data from the URL
                            img_resp = self.session.get(image_url, timeout=self.timeout)
                            img_resp.raise_for_status()
                            response.append(img_resp.content)
                            break
                        else:
                            print(f"Warning: No image data in response: {data}")
                            if attempt == max_retries - 1:
                                raise Exception("No image data received after all retries")

                except Exception as e:
                    print(f"Error generating image (attempt {attempt + 1}/{max_retries}): {str(e)}")
                    if attempt == max_retries - 1:
                        raise
                    import time
                    time.sleep(retry_delay)

        return response

    def _create_payload(self, prompt: str, model: str, style: str, aspect_ratio: str) -> dict:
        """Create the API request payload 📦

        Args:
            prompt (str): The image generation prompt
            model (str): Model to use
            style (str): Style to apply
            aspect_ratio (str): Aspect ratio

        Returns:
            dict: API request payload
        """
        return {
            "prompt": prompt,
            "model": model,
            "style": style,
            "aspect_ratio": aspect_ratio
        }

    def save(
        self,
        response: List[bytes],
        name: str = None,
        dir: str = os.getcwd(),
        filenames_prefix: str = "",
    ) -> List[str]:
        """Save your amazing images! 💾

        Args:
            response (List[bytes]): List of image data
            name (str, optional): Base name for saved files
            dir (str, optional): Where to save the images
            filenames_prefix (str, optional): Prefix for filenames

        Returns:
            List[str]: List of saved filenames
        """
        assert isinstance(response, list), f"Response should be of {list} not {type(response)}"
        name = self.prompt if name is None else name

        if not os.path.exists(dir):
            os.makedirs(dir)

        filenames = []
        count = 0
        for image in response:
            def complete_path():
                count_value = "" if count == 0 else f"_{count}"
                return os.path.join(dir, name + count_value + "." + self.image_extension)

            while os.path.isfile(complete_path()):
                count += 1

            absolute_path_to_file = complete_path()
            filenames.append(filenames_prefix + os.path.split(absolute_path_to_file)[1])

            with open(absolute_path_to_file, "wb") as fh:
                fh.write(image)
        return filenames


if __name__ == "__main__":
    bot = PixelMuseImager()
    try:
        resp = bot.generate("A magical forest with glowing mushrooms and fairy lights", 1)
        print(bot.save(resp))
    except Exception:
        pass 