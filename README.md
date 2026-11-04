# BPD 2024 - дополнительное задание к практическим работам № 5 и № 6, часть А: тестирование на основе свойств и security gate

Выдаётся 05.11.2026, выполняется индивидуально. Инструменты: Foundry v1.8.5 (forge), Slither 0.11.6, GitHub Actions.

## Подготовка среды

### Вариант А. Свой ноутбук (рекомендуется): macOS, Linux или Windows через WSL2

1. **Windows:** установите WSL2 (PowerShell от имени администратора: `wsl --install`, перезагрузка, Ubuntu). Все дальнейшие команды выполняйте в терминале Ubuntu. Репозиторий храните в домашнем каталоге WSL (`~`), а не в `/mnt/c/...`. Обычный PowerShell не подходит.
2. **git, make, curl:**
   - macOS: `xcode-select --install`
   - Ubuntu / WSL: `sudo apt update && sudo apt install -y git make curl`
3. **uv** (менеджер Python и библиотек; Python 3.12 он скачает сам, ставить Python отдельно не нужно):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```
   На macOS можно `brew install uv`.
4. **Foundry v1.8.5:**
   ```bash
   curl -fsSL https://foundry.paradigm.xyz | bash
   ```
   Откройте **новый** терминал, затем:
   ```bash
   foundryup -i v1.8.5
   ```
5. **Репозиторий:** на странице шаблона на GitHub нажмите **Use this template - Create a new repository**, видимость **Public**, затем:
   ```bash
   git clone https://github.com/<ваш-логин>/<имя-репозитория>.git
   cd <имя-репозитория>
   ```
6. **Установка библиотек и проверка среды:**
   ```bash
   make setup
   make check
   ```
   `make check` проверяет uv, Python, git, Foundry, Slither, компиляцию, unit-тесты и Slither на шаблоне и создаёт файл `check-result-pz1.txt`. В конце должно быть `ИТОГ: ГОТОВО`.
7. **Сохраните `check-result-pz1.txt`: он загружается в форму сдачи вместе с отчётом.** Файл не содержит имени пользователя и путей к домашнему каталогу.

### Вариант Б. GitHub Codespaces (если ноутбук не подходит)

1. В своём репозитории (шаг 5 выше): **Code - Codespaces - Create codespace on main**.
2. Установка Foundry, uv и библиотек запускается автоматически (3-5 минут, `.devcontainer/setup.sh`). Дождитесь строки `Среда готова. Выполните: make check`.
3. В терминале Codespaces: `make check`. Файл `check-result-pz1.txt` скачайте через проводник слева (правый клик - Download) и сохраните для сдачи.

Бесплатной квоты Codespaces хватает на задание. Остановите codespace после работы.

### Если что-то не работает

| Сообщение | Что сделать |
|---|---|
| `uv не установлен` или `uv: command not found` | Откройте новый терминал (установщик дописывает PATH). Не помогло - повторите шаг 3. |
| `forge: command not found` | Новый терминал; затем `foundryup -i v1.8.5`. |
| `[WARN] forge установлен ... рекомендуется 1.8.5` | `foundryup -i v1.8.5` |
| `[FAIL] forge build` с ошибкой загрузки solc | Нужен доступ к `binaries.soliditylang.org`. Выполните `make check` из другой сети (дом, мобильный интернет): компилятор сохраняется локально, повторно сеть не нужна. |
| `uv sync` не может скачать пакеты | Нужен доступ к `pypi.org`, `files.pythonhosted.org`, `github.com`. |
| Любой другой `[FAIL]` | Напишите докторанту и приложите `check-result-pz1.txt`. |

## Задание

`src/TokenVault.sol` - хранилище токенов: участник вносит токены и получает доли, может передать доли другому участнику и вывести токены. **Контракт содержит намеренные ошибки.** Unit-тесты в `test/TokenVault.t.sol` при этом проходят - это часть урока.

### Требования к контракту

- **R1.** Сумма долей всех участников равна `totalSupply`.
- **R2.** Платёжеспособность: токенов на балансе хранилища не меньше, чем сумма долей всех участников.
- **R3.** Участник, который внёс `x` и сразу вывел `x`, получает ровно `x` токенов, его доля становится 0.
- **R4.** Приостановить работу (`setPaused`) может только владелец; на паузе `deposit`, `withdraw` и `transfer` отклоняются.
- **R5.** Операции с токеном безопасны и для токенов, которые при ошибке возвращают `false` или не возвращают значение.

### Порядок выполнения

1. **А1.** Подготовьте среду (раздел выше), сохраните `check-result-pz1.txt`.
2. **А2.** `make slither`: шесть предупреждений. Для каждого определите: истинное, ложное или принятое срабатывание; какое требование R1-R5 нарушено; решение.
3. **А3.** В `test/invariant/VaultInvariants.t.sol` раскомментируйте и допишите инварианты R1 и R2. Handler `test/invariant/VaultHandler.sol` уже готов. Запуск: `make invariants`.
4. **А4.** В `test/TokenVault.t.sol` добавьте fuzz-тест `testFuzz_DepositWithdrawRoundTrip(uint256 amount)` по требованию R3; ограничьте `amount` функцией `bound`. Запуск: `make test`.
5. **А5.** Прочитайте контрпример (раздел ниже), найдите ошибку в `src/TokenVault.sol`, исправьте, повторите `make invariants`. Зафиксируйте исправление коммитом.
6. **А6.** В `.github/workflows/security.yml` замените `fail-on: none` на `fail-on: high` и `FOUNDRY_PROFILE: default` на `FOUNDRY_PROFILE: ci`. `make ci` - локальный аналог конвейера. Если Slither блокирует, исправьте по R5 (`SafeERC20` из `@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol`). `git push`; во вкладке **Actions** оба задания workflow `security` должны завершиться успешно.
7. **А7.** Сформулируйте три инварианта безопасности контракта своего варианта практической работы № 5 и способ их автоматической проверки.

Для желающих, без баллов: инвариант для R4 или проверка того же свойства фаззером Echidna или Medusa.

### Как читать контрпример

`make invariants` запускает `forge test --match-path "test/invariant/*" -vvvv`. При нарушении свойства Foundry выводит:

```
[FAIL: R2: vault is insolvent: A < B] invariant_Solvency
	[Sequence] (original: 24, shrunk: 2)
		sender=0x... addr=[test/invariant/VaultHandler.sol:VaultHandler]0x... calldata=deposit(uint256,uint256) args=[..., ...]
		sender=0x... addr=[test/invariant/VaultHandler.sol:VaultHandler]0x... calldata=<функция>(...) args=[...]
...
Traces:
  [...] VaultHandler::deposit(...)
    ├─ ... TokenVault::deposit(...)
  [...] VaultHandler::<функция>(...)
    ├─ [0] VM::prank(<кто вызывает>)
    ├─ ... TokenVault::<функция>(<аргументы>)
  [...] VaultInvariants::invariant_Solvency()
    ├─ ... VM::assertGe(<токены хранилища>, <сумма долей>, "R2: vault is insolvent")
```

- `[FAIL: ...]` - какое свойство нарушено. Числа в этой строке относятся к исходной длинной последовательности.
- `[Sequence] (original: 24, shrunk: 2)` - Foundry сократил последовательность вызовов до минимальной, которая всё ещё нарушает свойство.
- `args=[...]` в `[Sequence]` - "сырые" случайные числа, которые получил handler. Handler переводит их в участника и сумму через `bound`, поэтому смотрите в `Traces`.
- `Traces` - сокращённая последовательность с реальными вызовами контракта: кто вызывает (`VM::prank`), какую функцию `TokenVault` и с какими аргументами. Задайте вопрос: что особенного в этих аргументах?
- Найденная последовательность сохраняется в `cache/invariant/failures/` и при следующем запуске проверяется первой. После исправления она должна пройти.

## Команды

| Команда | Что делает |
|---|---|
| `make setup` | Python 3.12 и Slither в `.venv` по `uv.lock` |
| `make check` | проверка среды, результат в `check-result-pz1.txt` |
| `make build` | `forge build` |
| `make test` | все тесты (unit, fuzz, invariant) |
| `make invariants` | только инвариантные тесты с трассой контрпримера |
| `make slither` | статический анализ без блокировки |
| `make ci` | Slither с блокировкой на High и тесты с профилем `ci` |

Без make: `uv run python scripts/check_env.py`, `uv run slither . --config-file slither.config.json`, `forge test`.

## Сдача

Отчёт части А, 1-2 страницы, PDF, имя `Фамилия_Группа_А.pdf`: таблица triage предупреждений Slither; инварианты с указанием проверяемых требований; разбор контрпримера; описание исправлений; ссылка на успешный запуск workflow (отчёт Slither в формате SARIF сохраняется в artifact `slither-sarif`, в публичном репозитории находки видны во вкладке **Security - Code scanning**); пункт А7.

В форму сдачи загружаются отчёт, `check-result-pz1.txt`, ссылка на этот репозиторий и ссылка на успешный запуск workflow `security`: вкладка **Actions**, запуск с зелёной отметкой, адрес открывшейся страницы вида `https://github.com/<логин>/bpd-pz1-invariants/actions/runs/<номер>`. Срок сдачи частей А и Б, ссылка на форму сдачи и критерии оценивания - в инструкции для студентов "Дополнительное задание к практическим работам № 5 и № 6". LMS Moodle для сдачи не используется.

## Состав репозитория

- `src/TokenVault.sol` - учебный контракт с ошибками.
- `test/TokenVault.t.sol` - unit-тесты на примерах.
- `test/invariant/VaultHandler.sol` - готовый handler: участники alice, bob, carol; ограничение входов; теневые переменные.
- `test/invariant/VaultInvariants.t.sol` - заготовка инвариантов.
- `lib/` - forge-std v1.17.0 и OpenZeppelin Contracts v5.7.0 (включены в репозиторий, `forge install` не нужен).
- `foundry.toml` - профили `default` и `ci`; `slither.config.json` - настройки Slither.
- `pyproject.toml`, `uv.lock`, `.python-version` - Python 3.12, slither-analyzer 0.11.6, crytic-compile 0.4.2.
- `.devcontainer/` - среда для GitHub Codespaces; `.github/workflows/security.yml` - заготовка конвейера.
