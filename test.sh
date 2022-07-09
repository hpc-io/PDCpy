set -e
./build.sh
python3.8 run_tests.py "$@"