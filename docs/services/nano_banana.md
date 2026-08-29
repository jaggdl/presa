# Nano Banana

Google's Nano Banana family of image models, exposed as native tools. Generate images from text prompts or edit existing images (by URL or data URI). The default model is the latest flash-tier model (`gemini-3.1-flash-image`), but agents can request a different one per call.

## Configuration

| field | required | secret | default | what it does |
| --- | --- | --- | --- | --- |
| `api_key` | yes | yes | — | Google Gemini / AI Studio API key. Create one at [Google AI Studio](https://aistudio.google.com/apikey). |

## Tools

- `generate_image` — generate an image from a text prompt. Optional `model` picks a Nano Banana model id. Returns the image as a `data:` URI.
- `edit_image` — edit an existing image. Pass the image as a data URI or URL (`image_uri`), or as raw base64 image data (`image`). Optional `model` picks a Nano Banana model id. Returns the edited image as a `data:` URI.
- `list_models` — list the Nano Banana image model ids available to this service, queried live from the Gemini API, so agents can discover valid `model` ids.

Images are returned inline; binary uploads are stored briefly (a few minutes) at a temporary URL so the service can fetch them, then deleted in the background. Nothing persists.