set -e
python3 setup.py build_ext --inplace
cd docs
make clean
make html
cd ..