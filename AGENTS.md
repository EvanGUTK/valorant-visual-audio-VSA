# AGENTS.md

## Cursor Cloud specific instructions

This repo has two threads:

- Product A — "Valorant Visual Audio (VSA)": the intended real-time audio visualizer. Its
  pipeline scripts (`sender_windows.py`, `receiver_ai*.py`, `receiver_mac.py`, `recorder.py`,
  `diagnose.py`, `freq_finder.py`, `train.py`, `scripts/{split_dataset,extract_features,export_model}.py`)
  are **placeholder scaffolds** (functions `pass` or raise `NotImplementedError`). There is no
  running VSA service, no server, and no database. `sender_windows.py` is expected to exit
  non-zero with an "implement" message — that behavior is asserted by CI, so do not "fix" it.
- Product B — envelope encryption / KMS example (`scripts/envelope_*.py`, `scripts/terraform_*.tf`,
  `docs/0001-data-encryption.md`): the only executable, non-trivial logic. Runs fully locally.

Environment: system Python (3.12 locally; CI pins 3.11). `pip install` uses `--user` by default
here — no `--break-system-packages` needed. The only pinned deps are `boto3` and `cryptography`
(`requirements.txt`); the heavy audio/ML deps mentioned in `README.md` (torch, pygame, sounddevice,
etc.) are intentionally NOT installed and are not needed unless implementing Product A.

Common commands (run from repo root):

- Build / syntax check: `python -m compileall .` (this is also the closest thing to a "lint" —
  no ruff/flake8 is configured; README lists linting only as a future idea).
- Tests: there is no test suite. The only automated check is the CI smoke test in
  `.github/workflows/pipeline-smoke.yml`, which verifies scaffold files exist and that
  `python sender_windows.py` fails loudly. Replicate it by running that workflow's inline script.
- Run the app (Product B demo, the meaningful runnable flow):
  `python scripts/envelope_example.py` — prints an encrypted blob and recovers the plaintext.
- AWS KMS path (`AwsKmsClient` in `scripts/envelope_crypto_kms.py`) requires AWS credentials +
  a provisioned CMK; the local demo uses `LocalKmsMock` and needs no external services.
