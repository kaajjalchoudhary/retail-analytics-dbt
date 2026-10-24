"""Print a few headline numbers from the marts after `dbt build`.

python scripts/query_marts.py
"""

import duckdb

QUERIES = {
    "Revenue by year": """
        select year(order_date) as year, sum(orders) as orders, sum(revenue) as revenue,
               round(sum(gross_margin) / sum(revenue) * 100, 1) as margin_pct
        from marts.fct_daily_revenue group by 1 order by 1
    """,
    "Customer segments": """
        select customer_segment, count(*) as customers, round(avg(lifetime_value), 2) as avg_ltv
        from marts.dim_customers group by 1 order by customers desc
    """,
    "Top 5 products": """
        select revenue_rank, product_name, category, units_sold, revenue
        from marts.dim_products order by revenue_rank limit 5
    """,
}


def main() -> None:
    con = duckdb.connect("warehouse.duckdb", read_only=True)
    for title, sql in QUERIES.items():
        print(f"\n== {title} ==")
        print(con.sql(sql))


if __name__ == "__main__":
    main()
