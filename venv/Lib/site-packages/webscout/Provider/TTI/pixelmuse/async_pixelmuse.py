import aiohttp
import asyncio
import os
import time
from typing import List, Optional, Union, AsyncGenerator
from string import punctuation
from random import choice
from aiohttp import ClientError
from pathlib import Path

from webscout.AIbase import AsyncImageProvider
from webscout.litagent import LitAgent

agent = LitAgent()

class AsyncPixelMuseImager(AsyncImageProvider):
    """Your go-to async provider for generating fire images with PixelMuse! ⚡

    Examples:
        >>> # Basic usage
        >>> provider = AsyncPixelMuseImager()
        >>> async def example():
        ...     images = await provider.generate("Cool art")
        ...     paths = await provider.save(images)
        >>>
        >>> # Advanced usage
        >>> provider = AsyncPixelMuseImager(timeout=120)
        >>> async def example():
        ...     images = await provider.generate(
        ...         prompt="Epic dragon",
        ...         amount=3,
        ...         model="flux-schnell",
        ...         style="none",
        ...         aspect_ratio="1:1"
        ...     )
        ...     paths = await provider.save(images, name="dragon", dir="my_art")
    """

    AVAILABLE_MODELS = [
        "flux-schnell",
        "imagen-3-fast",
        "imagen-3",
        "recraft-v3"
    ]

    def __init__(self, timeout: int = 60, proxies: dict = {}):
        """Initialize your async PixelMuse provider with custom settings! ⚙️

        Args:
            timeout (int): Request timeout in seconds (default: 60)
            proxies (dict): Proxy settings for requests (default: {})
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
            "user-agent": agent.random(),
        }
        self.timeout = timeout
        self.proxies = proxies
        self.prompt: str = "AI-generated image - webscout"
        self.image_extension: str = "webp"

    async def generate(
        self, 
        prompt: str, 
        amount: int = 1,
        max_retries: int = 3, 
        retry_delay: int = 5,
        model: str = "flux-schnell",
        style: str = "none", 
        aspect_ratio: str = "1:1"
    ) -> List[bytes]:
        """Generate some amazing images from your prompt asynchronously! ⚡

        Examples:
            >>> provider = AsyncPixelMuseImager()
            >>> async def example():
            ...     # Basic usage
            ...     images = await provider.generate("Cool art")
            ...     # Advanced usage
            ...     images = await provider.generate(
            ...         prompt="Epic dragon",
            ...         amount=3,
            ...         model="flux-schnell"
            ...     )

        Args:
            prompt (str): Your creative prompt
            amount (int): How many images to generate
            max_retries (int): Max retry attempts if generation fails
            retry_delay (int): Seconds to wait between retries
            model (str): Model to use - check AVAILABLE_MODELS (default: "flux-schnell")
            style (str): Style to apply (default: "none")
            aspect_ratio (str): Aspect ratio (default: "1:1")

        Returns:
            List[bytes]: Your generated images

        Raises:
            ValueError: If the inputs ain't valid
            ClientError: If the API calls fail after retries
        """
        assert bool(prompt), "Prompt cannot be null"
        assert isinstance(amount, int), f"Amount should be an integer only not {type(amount)}"
        assert amount > 0, "Amount should be greater than 0"
        assert model in self.AVAILABLE_MODELS, f"Model should be one of {self.AVAILABLE_MODELS}"

        self.prompt = prompt
        response = []
        
        async with aiohttp.ClientSession(headers=self.headers) as session:
            for _ in range(amount):
                for attempt in range(max_retries):
                    try:
                        # First request to get the prediction
                        async with session.post(
                            self.api_endpoint,
                            json=self._create_payload(prompt, model, style, aspect_ratio),
                            timeout=self.timeout,
                            proxy=self.proxies.get('http')
                        ) as resp:
                            resp.raise_for_status()
                            data = await resp.json()

                            if 'output' in data and len(data['output']) > 0:
                                image_url = data['output'][0]
                                # Get the image data from the URL
                                async with session.get(
                                    image_url, 
                                    timeout=self.timeout,
                                    proxy=self.proxies.get('http')
                                ) as img_resp:
                                    img_resp.raise_for_status()
                                    response.append(await img_resp.read())
                                    break
                            else:
                                print(f"Warning: No image data in response: {data}")
                                if attempt == max_retries - 1:
                                    raise Exception("No image data received after all retries")

                    except ClientError as e:
                        if attempt == max_retries - 1:
                            raise
                        else:
                            await asyncio.sleep(retry_delay)

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

    async def save(
        self,
        response: Union[AsyncGenerator[bytes, None], List[bytes]],
        name: Optional[str] = None,
        dir: Optional[Union[str, Path]] = None,
        filenames_prefix: str = "",
    ) -> List[str]:
        """Save your amazing images asynchronously! 💾

        Examples:
            >>> provider = AsyncPixelMuseImager()
            >>> async def example():
            ...     images = await provider.generate("Cool art")
            ...     # Save with default settings
            ...     paths = await provider.save(images)
            ...     # Save with custom name and directory
            ...     paths = await provider.save(
            ...         images,
            ...         name="my_art",
            ...         dir="my_images",
            ...         filenames_prefix="test_"
            ...     )

        Args:
            response (Union[AsyncGenerator[bytes, None], List[bytes]]): Your generated images
            name (Optional[str]): Custom name for your images
            dir (Optional[Union[str, Path]]): Where to save the images (default: current directory)
            filenames_prefix (str): Prefix for your image files

        Returns:
            List[str]: Paths to your saved images
        """
        save_dir = dir if dir else os.getcwd()
        if not os.path.exists(save_dir):
            os.makedirs(save_dir)

        name = self.prompt if name is None else name
        saved_paths = []
        timestamp = int(time.time())
        
        async def save_single_image(image_bytes: bytes, index: int) -> str:
            filename = f"{filenames_prefix}{name}_{index}.{self.image_extension}"
            filepath = os.path.join(save_dir, filename)
            
            # Write file using asyncio
            async with asyncio.Lock():
                with open(filepath, "wb") as f:
                    f.write(image_bytes)
            
            return filepath

        # Handle both List[bytes] and AsyncGenerator
        if isinstance(response, list):
            image_list = response
        else:
            image_list = [chunk async for chunk in response]

        tasks = [save_single_image(img, i) for i, img in enumerate(image_list)]
        saved_paths = await asyncio.gather(*tasks)
        return saved_paths

if __name__ == "__main__":
    async def main():
        bot = AsyncPixelMuseImager()
        try:
            resp = await bot.generate("A magical forest with glowing mushrooms and fairy lights", 1)
            paths = await bot.save(resp)
            print(paths)
        except Exception as e:
            print(f"An error occurred: {e}")

    asyncio.run(main()) 