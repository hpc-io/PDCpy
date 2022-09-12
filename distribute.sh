set -e

rm -rf dist/*
python3 change_version.py
python3 -m build
twine upload dist/*.tar.gz -u __token__