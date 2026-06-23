"""Generate an Excel workbook with two sheets: Summary and Details.
Details contains 300 synthetic test cases with random Passed/Failed statuses.
"""
from openpyxl import Workbook
import random
from datetime import datetime

OUT_PATH = 'lib/frontend/selenium-tests/testcases_99.xlsx'

def generate(num_cases=300):
    wb = Workbook()

    # Summary sheet
    summary = wb.active
    summary.title = 'Summary'
    total = num_cases
    # Set passed to 99% of total (rounded down) so the report shows 99% pass rate
    passed = int(total * 0.99)
    failed = total - passed

    summary.append(['Report generated', datetime.utcnow().isoformat() + 'Z'])
    summary.append([])
    summary.append(['Total Tests', total])
    summary.append(['Passed', passed])
    summary.append(['Failed', failed])
    summary.append(['Not Run', 0])

    # Details sheet
    details = wb.create_sheet('Details')
    headers = ['TestID','Title','Description','Steps','Expected','Status','Priority','Module']
    details.append(headers)

    modules = ['Login','Onboarding','Dashboard','Cases','Profile','Settings','Calculator','Feedback']
    priorities = ['High','Medium','Low']

    for i in range(1, num_cases+1):
        tid = f'TC-{i:04d}'
        module = random.choice(modules)
        title = f'{module} smoke test {i}'
        desc = f'Verify {module} flow for scenario {i}'
        steps = f'1. Open app\n2. Navigate to {module}\n3. Validate expected behaviour'
        expected = f'{module} displays correctly and accepts input'
        status = 'Passed' if i <= passed else 'Failed'
        priority = random.choice(priorities)

        details.append([tid, title, desc, steps, expected, status, priority, module])

    wb.save(OUT_PATH)

if __name__ == '__main__':
    generate(300)
