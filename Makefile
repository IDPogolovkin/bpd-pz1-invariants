.PHONY: setup check build test invariants slither ci clean need-uv

setup: need-uv       ## Python 3.12 и Slither в .venv по uv.lock
	uv sync --locked

check: need-uv       ## проверка среды; результат - check-result-pz1.txt
	uv run --locked python scripts/check_env.py

build:
	forge build

test:                ## все тесты (unit, fuzz, invariant)
	forge test

invariants:          ## только инвариантные тесты с трассой контрпримера
	forge test --match-path "test/invariant/*" -vvvv

slither: need-uv     ## статический анализ (без блокировки)
	uv run --locked slither . --config-file slither.config.json

ci: need-uv          ## локальный аналог конвейера: security gate Slither (high) + тесты с профилем ci
	uv run --locked slither . --config-file slither.config.json --fail-high
	FOUNDRY_PROFILE=ci forge test

clean:
	forge clean

need-uv:
	@command -v uv >/dev/null 2>&1 || { echo "uv не установлен - см. README, раздел 'Подготовка среды'"; exit 1; }
