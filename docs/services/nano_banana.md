# Nano Banana

Google's Nano Banana image model (`gemini-2.5-flash-image`), exposed as native tools. Generate images from text prompts or edit existing images (by URL or data URI).

## Configuration

| field | required | secret | default | what it does |
| --- | --- | --- | --- | --- |
| `api_key` | yes | yes | — | Google Gemini / AI Studio API key. Create one at [Google AI Studio](https://aistudio.google.com/apikey). |

## Tools

- `generate_image` — generate an image from a text prompt. Returns the image as a `data:` URI.
- `edit_image` — edit an existing image (passed as a data URI or an http(s) URL) using a text prompt. Returns the edited image as a `data:` URI.

Images are returned inline; nothing is stored or uploaded to third-party hosts.