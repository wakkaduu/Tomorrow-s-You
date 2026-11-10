#!/usr/bin/env python3
"""Run release gates with isolated saves and record the tested production fingerprint."""
import concurrent.futures
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SUITES = [
    'tests/solver/test_wait_optimization.gd', 'tests/regression/test_turn_and_wait.gd',
    'tests/run_all_tests.gd', 'tests/core/test_puzzle_simulation.gd',
    'tests/core/test_level_validation.gd', 'tests/levels/test_campaign_solutions.gd',
    'tests/test_runner.tscn', 'tests/mobile/test_mobile_system.tscn',
    'tests/ui/test_design_system.gd', 'tests/narrative/test_narrative_system.gd',
    'tests/narrative/test_save_scenarios_and_triggers.gd',
    'tests/narrative/test_opening_transmission_flow.tscn', 'tests/hints/test_hint_system.gd',
    'tests/core/test_level_completion.tscn', 'tests/core/test_ui_and_screens.gd',
    'tests/core/test_responsiveness.gd', 'tests/visual/test_temporal_background.tscn',
    'tests/release/test_android_alpha_release.py',
]


def main():
    spec = importlib.util.spec_from_file_location('alpha_release', ROOT / 'scripts/tools/android_alpha_release.py')
    alpha = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(alpha)
    fingerprint = alpha.source_fingerprint()
    logs = Path(tempfile.mkdtemp(prefix='tomorrow-alpha-tests-'))

    def run(suite):
        data = tempfile.mkdtemp(dir=logs)
        env = dict(os.environ, XDG_DATA_HOME=data, XDG_CONFIG_HOME=data)
        if suite.endswith('.py'):
            cmd = [sys.executable, '-m', 'unittest', 'discover', '-s', 'tests/release', '-v']
        else:
            cmd = ['godot', '--headless', '--path', str(ROOT)] + (['-s', suite] if suite.endswith('.gd') else [suite])
        try:
            result = subprocess.run(cmd, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True, timeout=120)
            output = result.stdout
            code = result.returncode
        except subprocess.TimeoutExpired as error:
            output = str(error.stdout or '')
            code = 'TIMEOUT'
        (logs / (suite.replace('/', '_') + '.log')).write_text(output)
        return {'suite': suite, 'exit_code': code, 'script_errors': 'SCRIPT ERROR' in output,
                'summary': [line for line in output.splitlines() if any(word in line for word in
                            ['SUMMARY', 'OPTIMIZATION:', 'REGRESSION:', 'UI INTEGRATION:', 'Results:', 'solutions:', 'Ran ', 'OK'])]}

    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results = []
        for result in pool.map(run, SUITES):
            results.append(result)
            print(json.dumps(result), flush=True)
    passed = fingerprint == alpha.source_fingerprint() and all(r['exit_code'] == 0 and not r['script_errors'] for r in results)
    alpha.OUT.mkdir(parents=True, exist_ok=True)
    report = {'source_base_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'source_content_sha256': fingerprint, 'logs': str(logs), 'passed': passed, 'suites': results}
    (alpha.OUT / 'test-results.json').write_text(json.dumps(report, indent=2) + '\n')
    print('Release test record:', alpha.OUT / 'test-results.json')
    return 0 if passed else 1

if __name__ == '__main__':
    raise SystemExit(main())
