set -e
./build.sh
python3 run_tests.py "$@"