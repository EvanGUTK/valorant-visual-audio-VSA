# Label Guide

The dataset is expected to contain short audio clips labeled by the event class.

## Supported classes

- `footstep`
- `gunshot`
- `spectre`
- `jump`
- `silence`

## Recording expectations

- Capture clips that are short, clear, and representative of the target event.
- Avoid clips with heavy overlap from other sounds unless the label is intentionally mixed.
- Prefer consistent gain and microphone placement during recording sessions.

## Validation checklist

- The clip contains audible content for non-silence classes.
- The clip is not corrupted or truncated.
- The label matches the dominant sound in the clip.
