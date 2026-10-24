"""Generate the raw seed CSVs for a fictional online clothing store.

The data is deliberately messy, the way real source extracts are: inconsistent
casing and whitespace, duplicate order rows from status updates, failed payment
attempts and split payments. The dbt staging layer cleans all of it up.

    python scripts/generate_seeds.py            # writes seeds/raw_*.csv
"""

import argparse
import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

FIRST = (
    "Aarav Maya Liam Sofia Noah Zara Ethan Priya Lucas Amara "
    "Omar Hana Leo Ines Ravi Chloe Mateo Aisha Jonas Elena"
).split()
LAST = (
    "Shah Garcia Kim Okafor Novak Rossi Haddad Mehta Silva Berg "
    "Tanaka Dubois Ali Moreau Kowalski Reyes Fischer Nair Costa Lee"
).split()
COUNTRIES = ["us", "gb", "de", "in", "ae", "ca", "fr", "au"]
CATEGORIES = {
    "Tops": ["Linen Shirt", "Graphic Tee", "Oxford Shirt", "Knit Polo", "Silk Blouse"],
    "Bottoms": ["Slim Chinos", "Denim Jeans", "Pleated Trousers", "Cargo Pants", "Midi Skirt"],
    "Outerwear": ["Rain Jacket", "Wool Coat", "Puffer Vest", "Denim Jacket", "Trench Coat"],
    "Footwear": ["Leather Sneakers", "Chelsea Boots", "Canvas Shoes", "Running Shoes", "Loafers"],
    "Accessories": ["Leather Belt", "Wool Scarf", "Canvas Tote", "Sunglasses", "Beanie"],
}
PAYMENT_METHODS = ["credit_card", "debit_card", "paypal", "bank_transfer"]
START, END = date(2023, 1, 1), date(2024, 12, 31)


def messy(rng, text):
    return rng.choice([text, text.upper(), text.title() + " ", " " + text])


def generate(out_dir: Path, customers: int, seed: int) -> dict:
    rng = random.Random(seed)
    out_dir.mkdir(parents=True, exist_ok=True)

    products = []
    pid = 0
    for category, names in CATEGORIES.items():
        for name in names:
            pid += 1
            price = rng.randint(15, 250) + rng.choice([0, 0.5, 0.99])
            cost = round(price * rng.uniform(0.35, 0.6), 2)
            products.append([pid, name, category, f"{price:.2f}", f"{cost:.2f}"])

    customer_rows, order_rows, item_rows, payment_rows = [], [], [], []
    order_id = item_id = payment_id = 0

    for cid in range(1, customers + 1):
        first, last = rng.choice(FIRST), rng.choice(LAST)
        email = f"{first}.{last}{cid}@example.com"
        signup = START - timedelta(days=180) + timedelta(days=rng.randint(0, 850))
        if rng.random() < 0.15:
            email = rng.choice([email.upper(), f"  {email}", f"{email} "])
        country = rng.choice(COUNTRIES)
        customer_rows.append(
            [
                cid,
                first.upper() if rng.random() < 0.1 else first,
                last,
                email,
                signup.isoformat(),
                country.upper() if rng.random() < 0.3 else country,
            ]
        )

        first_possible = max(signup, START)
        n_orders = min(int(rng.expovariate(1 / 5)), 20)
        for _ in range(n_orders):
            order_id += 1
            span = (END - first_possible).days
            day = first_possible + timedelta(days=rng.randint(0, max(span, 0)))
            ordered_at = datetime.combine(day, datetime.min.time()) + timedelta(
                seconds=rng.randint(0, 86399)
            )
            if (END - day).days < 7:
                status = rng.choice(["placed", "shipped"])
            else:
                status = rng.choices(["completed", "returned", "cancelled"], weights=[85, 8, 7])[0]

            loaded = ordered_at + timedelta(days=rng.randint(1, 5))
            if rng.random() < 0.05:  # earlier extract of the same order, before its status changed
                order_rows.append(
                    [
                        order_id,
                        cid,
                        ordered_at.isoformat(sep=" "),
                        "placed",
                        (ordered_at + timedelta(hours=1)).isoformat(sep=" "),
                    ]
                )
            order_rows.append(
                [
                    order_id,
                    cid,
                    ordered_at.isoformat(sep=" "),
                    messy(rng, status),
                    loaded.isoformat(sep=" "),
                ]
            )

            total_cents = 0
            for product in rng.sample(products, k=rng.randint(1, 4)):
                item_id += 1
                qty = rng.choices([1, 2, 3], weights=[75, 20, 5])[0]
                item_rows.append([item_id, order_id, product[0], qty, product[3]])
                total_cents += qty * round(float(product[3]) * 100)

            method = rng.choice(PAYMENT_METHODS)
            if status in ("completed", "shipped", "returned"):
                if rng.random() < 0.1:
                    payment_id += 1
                    payment_rows.append([payment_id, order_id, method, total_cents, "failed"])
                if rng.random() < 0.15 and total_cents > 1:
                    gift = rng.randint(1, total_cents - 1)
                    payment_id += 1
                    payment_rows.append([payment_id, order_id, "gift_card", gift, "success"])
                    payment_id += 1
                    payment_rows.append(
                        [payment_id, order_id, method, total_cents - gift, "success"]
                    )
                else:
                    payment_id += 1
                    payment_rows.append([payment_id, order_id, method, total_cents, "success"])
            elif status == "cancelled" and rng.random() < 0.5:
                payment_id += 1
                payment_rows.append([payment_id, order_id, method, total_cents, "failed"])

    tables = {
        "raw_customers": (
            ["customer_id", "first_name", "last_name", "email", "signup_date", "country"],
            customer_rows,
        ),
        "raw_products": (
            ["product_id", "product_name", "category", "unit_price", "unit_cost"],
            products,
        ),
        "raw_orders": (
            ["order_id", "customer_id", "order_date", "status", "_loaded_at"],
            order_rows,
        ),
        "raw_order_items": (
            ["order_item_id", "order_id", "product_id", "quantity", "unit_price"],
            item_rows,
        ),
        "raw_payments": (
            ["payment_id", "order_id", "payment_method", "amount_cents", "status"],
            payment_rows,
        ),
    }
    for name, (header, rows) in tables.items():
        with open(out_dir / f"{name}.csv", "w", newline="") as fh:
            writer = csv.writer(fh)
            writer.writerow(header)
            writer.writerows(rows)
    return {name: len(rows) for name, (_, rows) in tables.items()}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate raw seed CSVs")
    parser.add_argument("--customers", type=int, default=300)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--out", default="seeds")
    args = parser.parse_args()
    for table, count in generate(Path(args.out), args.customers, args.seed).items():
        print(f"{table:<18} {count:>6} rows")
