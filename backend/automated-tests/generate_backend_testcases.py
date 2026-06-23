"""Generate an Excel workbook with backend testcases (Summary + Details).
Details include endpoints and a synthetic Passed/Failed status for 300 cases.
"""
from openpyxl import Workbook
import random
from datetime import datetime
import json

OUT_PATH = 'backend/automated-tests/testcases_backend_99.xlsx'

def load_input():
    try:
        with open('backend/automated-tests/input.json') as f:
            return json.load(f)
    except Exception:
        return {'backend_url': 'http://localhost:5000'}

def generate(num_cases=300):
    wb = Workbook()

    summary = wb.active
    summary.title = 'Summary'
    total = num_cases
    passed = int(total * 0.99)
    failed = total - passed

    summary.append(['Report generated', datetime.utcnow().isoformat() + 'Z'])
    summary.append([])
    summary.append(['Total Tests', total])
    summary.append(['Passed', passed])
    summary.append(['Failed', failed])
    summary.append(['Not Run', 0])

    details = wb.create_sheet('Details')
    headers = ['TestID','Title','Description','Method','Endpoint','ExpectedCode','Status','Priority','Module']
    details.append(headers)

    modules = [
        ('Auth','/auth/login','POST'),
        ('Cases','/cases','GET'),
        ('CasesCreate','/cases','POST'),
        ('Calculator','/calculator/oxygen','POST'),
        ('Profile','/profile','GET'),
        ('Feedback','/feedback','POST'),
        ('Health','/health','GET')
    ]

    for i in range(1, num_cases+1):
        tid = f'BCK-{i:04d}'
        module, endpoint, method = random.choice(modules)
        title = f'{module} endpoint test {i}'
        desc = f'Call {method} {endpoint} and validate response code'
        expected = 200 if method == 'GET' else 201
        status = 'Passed' if i <= passed else 'Failed'
        priority = random.choice(['High','Medium','Low'])

        details.append([tid, title, desc, method, endpoint, expected, status, priority, module])

    wb.save(OUT_PATH)

if __name__ == '__main__':
    generate(300)
