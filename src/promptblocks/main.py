"""PromptBlocks application entry point."""

import sys

from promptblocks.app import PromptBlocksApp


def main() -> int:
    app = PromptBlocksApp(sys.argv)
    return app.run()


if __name__ == "__main__":
    sys.exit(main())
