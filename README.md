# Valorant Visual Audio (VSA)

A real-time external sound visualizer for Valorant — a standalone system that streams game audio from a Windows gaming laptop to a secondary device, classifies sounds with a trained CNN, and displays a directional HUD showing where sounds are coming from.

This repository lays out the code, data collection, model training, and deployment pipeline for VSA (formerly "Sound Radar"). The goal is a reliable, low-latency external visual audio indicator that runs on a separate physical device (to avoid anti-cheat overlay detection).

---

What it does

- Captures system audio (Stereo Mix / WASAPI) from a gaming laptop running Valorant.
- Streams audio over UDP to a secondary device (Mac/PC/tablet) on the same WiFi network.
- Classifies short clips using a small CNN trained on mel spectrograms (classes: footstep, gunshot, spectre, jump, silence).
- Estimates direction using stereo channel energy and HRTF cues (front/back estimation).
- Displays real-time HUD visualizations (radar / orbital HUD) on the secondary device.

High-level architecture

Gaming Laptop (Windows)          -->  WiFi  -->  Secondary Device (Mac/PC/Tablet)
────────────────────────         ──────►        ──────────────────────
Valorant produces audio           UDP streaming     Receiver app ingests audio
WASAPI / Stereo Mix capture                       CNN classifies clip
UDP sender (sender_windows.py)                     Direction detection (stereo + HRTF)
                                                  Real-time HUD (receiver_ai_v2.py)

Files (what's in this repo)

- sender_windows.py — Captures WASAPI/Stereo Mix audio on Windows and streams over UDP.
- receiver_mac.py — Top-down radar view (legacy frequency-threshold detector).
- receiver_ai.py — Radar view powered by the trained CNN.
- receiver_ai_v2.py — Minimal orbital HUD powered by the CNN (recommended for low distraction).
- recorder.py — Interactive data collection tool for creating labeled clips during gameplay.
- diagnose.py — Validates recorded clips for corruption or silence.
- freq_finder.py — Live frequency inspection tool for calibration and debugging.
- train.py — Training script: builds mel spectrograms, trains the CNN, saves checkpoint (modelv2.pth).
- diagnose.py — Clip integrity checks and quick diagnostics.
- data/ — (not checked in) expected dataset layout: data/<class>/*.wav

Requirements

Gaming laptop (Windows):
- Python 3.x
- pip install sounddevice numpy
- Stereo Mix enabled (see Setup)

Secondary laptop (receiver, any OS):
- Python 3.x
- pip3 install numpy pygame torch torchaudio soundfile scipy

Optional: a machine with a CUDA-capable GPU for faster training.

Setup

1) Enable Stereo Mix on Windows (gaming laptop)
   - Right-click speaker icon -> Sounds -> Recording tab
   - Right-click empty area -> Show Disabled Devices
   - Right-click "Stereo Mix" -> Enable -> Set as Default Device

2) Valorant & Windows audio settings
   - In Valorant: Settings -> Audio -> HRTF -> ON (required for front/back cues)
   - In Windows: Spatial Sound -> OFF (prevents double HRTF processing)

3) Find secondary device IP on the same WiFi network
   - macOS: ipconfig getifaddr en0
   - Windows: ipconfig  (use IPv4 from WiFi adapter)

4) Edit sender_windows.py
   - Set MAC_IP (or RECEIVER_IP) to the secondary device's IPv4 address.

Running (basic)

1. Start the receiver on the secondary device first:
   python3 receiver_ai_v2.py

2. Start the sender on the gaming laptop:
   python sender_windows.py

3. Expected output on sender: "Streaming via: Stereo Mix" (or similar)
4. Launch Valorant and play — detections should appear on the receiver HUD.

Data collection (build your own dataset)

- Use recorder.py on the receiver to capture labeled 0.5s clips live while you play.
  Controls:
  3 = footstep      4 = gunshot       5 = silence
  6 = jump          7 = spectre       Q = quit
- Clips are saved to data/<class>/. Numbering continues across sessions.
- Run diagnose.py periodically to confirm clips contain audio and are not corrupted.

Training

- organize clips under data/<class>/*.wav
- Run training locally on the receiver (or a separate machine):
  python3 train.py
- train.py converts clips to normalized mel spectrograms, trains a small CNN with class-weighted loss (to handle imbalance), and saves the best checkpoint to modelv2.pth.
- Typical validation accuracy from earlier experiments: ~97% on the collected dataset.

Direction detection details

- Left / Right: computed from stereo channel energy differences (reliable).
- Front / Back: estimated from HRTF spectral cues (requires Valorant HRTF = ON).
  - Front sounds tend to boost ~4–8 kHz; back sounds can cut 8–16 kHz.
  - This is an estimated cue — less accurate than L/R and sensitive to system settings.
- Center dead-zone: detections near the front/back axis within ~12° suppressed to avoid flagging own footsteps.

Why not an overlay

- Vanguard (Valorant anti-cheat) flags transparent always-on-top windows drawn over the game. This project runs on a separate physical device to avoid anti-cheat issues.
- The system is equivalent to placing a microphone near the gaming laptop — it does not touch the Valorant process, read memory, or inject code.

Pipeline (data → model → deployment)

This project separates responsibilities clearly so the data and model lifecycle is reproducible.

1) Data collection
   - recorder.py generates labeled 0.5s wav clips into data/<class>/
   - Periodic diagnose.py checks clip integrity and removes corrupted clips.

2) Dataset curation
   - Split data into train/val/test
   - Optionally augment (time-shift, mild noise, volume scaling) to improve robustness

3) Feature extraction
   - Convert clips to mel spectrograms with consistent parameters (sample rate, n_mels, clip length)
   - Persist precomputed features for faster training iterations

4) Training
   - train.py trains a small CNN on mel spectrograms, using class weights and early stopping
   - Save best checkpoint(s) and export a minimal inference artifact (state_dict + metadata)

5) Evaluation & Monitoring
   - Compute confusion matrix, per-class precision/recall, and sample-level qualitative checks
   - Tag low-confidence or ambiguous clips for manual review (active learning loop)

6) Deployment
   - Copy model checkpoint to receiver device
   - receiver_ai_v2.py loads the model and runs inference on streamed audio
   - Keep inference fast (<50ms per clip) for real-time UX

7) Continuous improvement (future)
   - Auto-flag low-confidence predictions during play for quick review
   - Retrain periodically with new curated data

Suggested CI / automation (ideas)

- GitHub Actions workflow ideas (not included here):
  - Lint Python files (flake8/ruff)
  - Run unit tests for any utility modules
  - Optionally run a lightweight smoke test that verifies train.py or a small inference script runs on a tiny sample
  - Do NOT commit large datasets or model checkpoints to the repo; use release artifacts or a separate storage bucket.

Directory layout (recommended)

- sender_windows.py
- receiver_ai_v2.py
- receiver_ai.py
- receiver_mac.py
- recorder.py
- train.py
- diagnose.py
- freq_finder.py
- data/               # not committed; local dataset
  - footstep/
  - gunshot/
  - spectre/
  - jump/
  - silence/
- models/             # trained checkpoints (git-ignored)
- docs/               # optional: design notes, dataset schema, label guide

Roadmap

- Active learning loop: auto-flag low-confidence predictions for review and quick relabeling
- More training data across maps/agents to increase robustness
- Single-laptop borderless-window mode (research Vanguard-safe options carefully)
- ESP32 physical HUD device port (low-power external display)
- Improve front/back accuracy with additional calibration and synthetic HRTF data

Contributing

Contributions welcome: more training data, support for different OSes, bug fixes, or visualization improvements. If you collect and retrain the model, consider sharing your data clips or trained checkpoint to help others.

Please open an issue or submit a pull request.

License

This project is MIT licensed. See LICENSE for details.

---
