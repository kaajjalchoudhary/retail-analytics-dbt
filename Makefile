.PHONY: install seeds build test docs query clean

install:
	pip install -r requirements.txt

seeds:
	python scripts/generate_seeds.py

build: seeds
	dbt build --profiles-dir .

test:
	dbt test --profiles-dir .

docs:
	dbt docs generate --profiles-dir . && dbt docs serve --profiles-dir .

query:
	python scripts/query_marts.py

clean:
	dbt clean --profiles-dir . && rm -f warehouse.duckdb seeds/raw_*.csv
