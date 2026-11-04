"""Проверка среды для дополнительного задания BPD 2024 к практическим работам № 5 и № 6.

Запуск из корня репозитория: make check
Без make (например, Windows PowerShell): uv run python scripts/check_env.py
Результат печатается и сохраняется в check-result-pz1.txt / check-result-pz2.txt -
этот файл загружается в форму сдачи вместе с отчётом.
"""
import datetime
import getpass
import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PZ = 'pz2' if (ROOT / 'detect').is_dir() else 'pz1'
FOUNDRY_PINNED = '1.8.5'
ENV = dict(os.environ, NO_COLOR='1')

results = []  # (статус, проверка, подробности)


def private(text):
    """Убирает из вывода домашний каталог и имя пользователя."""
    text = text.replace(str(Path.home()), '~')
    try:
        user = getpass.getuser()
        if len(user) > 2:
            text = re.sub(re.escape(user), '<user>', text, flags=re.I)
    except Exception:
        pass
    return text


def run(cmd, timeout=900):
    """Выполняет команду в корне репозитория; возвращает (код, вывод)."""
    try:
        p = subprocess.run(cmd, cwd=ROOT, env=ENV, capture_output=True, text=True, timeout=timeout,
                           encoding='utf-8', errors='replace')
        return p.returncode, (p.stdout + p.stderr).strip()
    except FileNotFoundError:
        return 127, f'команда не найдена: {cmd[0]}'
    except subprocess.TimeoutExpired:
        return 124, f'превышено время ожидания ({timeout} с)'


def add(status, name, detail=''):
    results.append((status, name, private(detail)))
    print(f'[{status}] {name}' + (f' - {private(detail).splitlines()[0]}' if detail else ''), flush=True)


def tail(text, n=8):
    return '\n'.join(text.splitlines()[-n:])


def check_python():
    v = sys.version_info[:2]
    in_venv = sys.prefix != sys.base_prefix
    detail = f'Python {platform.python_version()}' + (', окружение .venv' if in_venv else ', без .venv')
    if (3, 10) <= v <= (3, 14) and in_venv:
        add('PASS', 'Python 3.10-3.14 в окружении uv', detail)
    elif (3, 10) <= v <= (3, 14):
        add('WARN', 'Python 3.10-3.14 в окружении uv', detail + '; запускайте через make check или uv run')
    else:
        add('FAIL', 'Python 3.10-3.14 в окружении uv', detail + '; выполните uv sync')


def check_tool(name, required=True):
    if not shutil.which(name):
        add('FAIL' if required else 'WARN', f'{name} установлен', 'не найден в PATH')
        return False
    code, out = run([name, '--version'], timeout=60)
    first = out.splitlines()[0] if out else ''
    if name in ('forge', 'anvil') and FOUNDRY_PINNED not in first:
        add('WARN', f'{name} установлен', f'{first}; рекомендуется {FOUNDRY_PINNED}: foundryup -i v{FOUNDRY_PINNED}')
    else:
        add('PASS' if code == 0 else 'FAIL', f'{name} установлен', first)
    return code == 0


def check_import(module):
    code, out = run([sys.executable, '-c', f'import {module}; print({module}.__version__)'], timeout=120)
    if code == 0:
        add('PASS', f'Python-пакет {module}', out.splitlines()[-1])
        return True
    add('FAIL', f'Python-пакет {module}', 'не установлен: выполните uv sync')
    return False


def check_build():
    code, out = run(['forge', 'build'])
    if code == 0:
        add('PASS', 'forge build (компилятор solc 0.8.28 загружен)')
        return True
    add('FAIL', 'forge build', tail(out))
    return False


def check_pz1():
    has_forge = check_tool('forge')
    has_slither = check_tool('slither')
    if not (has_forge and check_build()):
        return
    code, out = run(['forge', 'test', '--match-contract', 'TokenVaultTest'])
    passed = re.search(r'(\d+) tests? passed', out)
    if code == 0 and passed:
        add('PASS', 'forge test (unit-тесты шаблона)', f'{passed.group(1)} tests passed')
    else:
        add('FAIL', 'forge test (unit-тесты шаблона)', tail(out))
    if has_slither:
        code, out = run(['slither', '.', '--config-file', 'slither.config.json'])
        found = re.search(r'analyzed \(\d+ contracts.*?(\d+) result', out)
        if found:
            add('PASS', 'slither (анализ шаблона)', f'{found.group(1)} предупреждений - разбираются в задании')
        else:
            add('FAIL', 'slither (анализ шаблона)', tail(out))


def check_pz2():
    has_forge = check_tool('forge')
    has_anvil = check_tool('anvil')
    has_web3 = check_import('web3')
    if not (has_forge and has_anvil and has_web3 and check_build()):
        return
    code, out = run([sys.executable, '-m', 'detect', 'run', '--quiet'], timeout=600)
    m = re.search(r'Транзакций: (\d+)', out)
    if code == 0 and m:
        add('PASS', 'сценарий мониторинга (anvil + монитор + метрики)', f'{m.group(1)} транзакций обработано')
    else:
        add('FAIL', 'сценарий мониторинга (anvil + монитор + метрики)', tail(out, 12))


def main():
    os.chdir(ROOT)
    print(f'Проверка среды BPD 2024, {PZ.upper()}\n')
    check_python()
    check_tool('uv')
    check_tool('git', required=False)
    check_pz1() if PZ == 'pz1' else check_pz2()

    failed = [r for r in results if r[0] == 'FAIL']
    verdict = 'ГОТОВО' if not failed else f'НЕ ГОТОВО ({len(failed)} ошибок, см. строки FAIL)'
    lines = [
        f'BPD 2024, проверка среды {PZ.upper()}',
        f'Дата: {datetime.datetime.now():%d.%m.%Y %H:%M}',
        f'ОС: {platform.system()} {platform.release()} ({platform.machine()})'
        + (', WSL' if 'microsoft' in platform.release().lower() else '')
        + (', Codespaces' if os.environ.get('CODESPACES') else ''),
        '',
    ]
    for status, name, detail in results:
        lines.append(f'[{status}] {name}')
        lines.extend('    ' + x for x in detail.splitlines())
    lines += ['', f'ИТОГ: {verdict}']
    out = ROOT / f'check-result-{PZ}.txt'
    out.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'\nИТОГ: {verdict}\nРезультат сохранён в {out.name} - загрузите этот файл в форму сдачи вместе с отчётом.')
    return 0 if not failed else 1


if __name__ == '__main__':
    sys.exit(main())
