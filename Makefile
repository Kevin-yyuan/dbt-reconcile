.PHONY: data demo fixed buggy report clean

data:
	python scripts/generate_data.py

fixed:
	dbt build --exclude tag:broken_on_purpose

buggy:
	-dbt build --select fct_order_lines_buggy

report:
	dbt show --select reconcile_report

demo: fixed buggy report

clean:
	rm -rf target logs dbt_packages *.duckdb
