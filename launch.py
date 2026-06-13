"""Launch script that works around GBK encoding issue with Chinese paths in .pth files."""
import sys
import os

# Add site-packages manually when using -S flag
site_packages = r"D:\Python 3.12.0\Lib\site-packages"
if os.path.isdir(site_packages):
    sys.path.insert(0, site_packages)

# Add project src
src_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")
if os.path.isdir(src_dir):
    sys.path.insert(0, src_dir)

from promptblocks.app import PromptBlocksApp

if __name__ == "__main__":
    app = PromptBlocksApp(sys.argv)
    sys.exit(app.run())
