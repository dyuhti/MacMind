# Selenium E2E tests for frontend

Steps to generate testcases and run tests:

1. Create a Python environment and activate it (optional but recommended)

2. Install dependencies:

```bash
pip install -r lib/frontend/selenium-tests/requirements.txt
```

3. Generate the Excel file with 300 test cases:

```bash
python lib/frontend/selenium-tests/generate_testcases.py
```

This will create `lib/frontend/selenium-tests/testcases.xlsx` with two sheets: `Summary` and `Details`.

4. Run the tests (ensure Chrome + chromedriver are available):

```bash
pytest lib/frontend/selenium-tests/tests/test_runner.py -q
```
