# Appium E2E tests (scaffold)

This folder contains a generator for Appium UI testcases and a pytest runner scaffold.

Usage:

1. Create a Python virtualenv and install dependencies:

```bash
pip install -r lib/frontend/appium-tests/requirements.txt
```

2. Generate testcases Excel (300 cases):

```bash
python lib/frontend/appium-tests/generate_appium_testcases.py
```

3. Run tests (provide Appium server URL and capabilities):

```bash
export APPIUM_SERVER_URL=http://127.0.0.1:4723/wd/hub
export APPIUM_APP=/path/to/app.apk
pytest lib/frontend/appium-tests/tests/test_appium_runner.py -q
```

Notes:
- The tests are a scaffold; provide real device/emulator capabilities via environment variables.
- By default the pytest runner limits to 50 tests to keep runs reasonable; adjust in the test file.
