"""Placeholder scaffold for the Windows sender pipeline.

The README describes a real-time audio streaming workflow for Valorant audio.
This repository currently contains the documentation and supporting scaffolding
for that workflow rather than a finished implementation.
"""


def main() -> None:
    """Entry point for the Windows sender workflow.

    This scaffold intentionally exits with a clear message until the workflow is
    implemented.
    """
    raise NotImplementedError(
        "sender_windows.py is a scaffold and does not yet implement the Windows "
        "sender workflow."
    )


if __name__ == "__main__":
    try:
        main()
    except NotImplementedError as exc:
        raise SystemExit(str(exc)) from exc
