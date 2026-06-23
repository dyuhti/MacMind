# Backend automated tests

This folder contains a generator for testcases and a pytest-based runner.

Steps:

1. Create and activate a Python virtualenv (optional).

2. Install dependencies:

```bash
pip install -r backend/automated-tests/requirements.txt
```

3. Generate the Excel with 300 backend testcases:

```bash
python backend/automated-tests/generate_backend_testcases.py
```

This creates `backend/automated-tests/testcases_backend.xlsx` with `Summary` and `Details` sheets.

4. Run tests (ensure backend server is running at `BACKEND_URL` environment variable or in `input.json`):

```bash
export BACKEND_URL=http://localhost:5000
pytest backend/automated-tests/tests/test_backend_runner.py -q
```
