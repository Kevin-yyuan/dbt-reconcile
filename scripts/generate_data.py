"""Generate the synthetic orders data used by the demo.

Deterministic (fixed seed), so everyone who runs it gets the same numbers.

The data has the two things real source data tends to have:
- many single-line orders and a long tail of multi-line ones, so a grain bug
  hits the big orders hardest;
- re-synced duplicates (the same order or line loaded again with a later
  updated_at), which is why the models need a dedup at all.
"""

import csv
import random
from datetime import datetime, timedelta
from pathlib import Path

SEED = 42
N_ORDERS = 2_000
RESYNC_RATE = 0.08  # share of orders / lines that arrive twice

SEEDS_DIR = Path(__file__).resolve().parent.parent / "seeds"

PRODUCTS = [
    ("SKU-100", "Desk lamp", 39.00),
    ("SKU-101", "Monitor arm", 89.00),
    ("SKU-102", "Keyboard", 129.00),
    ("SKU-103", "Mouse", 59.00),
    ("SKU-104", "USB-C dock", 219.00),
    ("SKU-105", "Webcam", 99.00),
    ("SKU-106", "Headset", 149.00),
    ("SKU-107", "Desk mat", 29.00),
    ("SKU-108", "Laptop stand", 69.00),
    ("SKU-109", "Cable kit", 19.00),
]

# Lines per order: mostly 1, a long tail up to 8.
LINE_COUNT_WEIGHTS = {1: 40, 2: 18, 3: 14, 4: 10, 5: 8, 6: 5, 7: 3, 8: 2}


def main() -> None:
    rng = random.Random(SEED)
    start = datetime(2026, 1, 1)

    orders, lines = [], []
    line_id = 0
    for order_id in range(1, N_ORDERS + 1):
        ordered_at = start + timedelta(minutes=rng.randint(0, 300 * 24 * 60))
        customer_id = rng.randint(1, 600)
        updated_at = ordered_at + timedelta(minutes=rng.randint(1, 120))
        orders.append([order_id, customer_id, ordered_at, "completed", updated_at])
        if rng.random() < RESYNC_RATE:
            orders.append([order_id, customer_id, ordered_at, "completed", updated_at + timedelta(hours=6)])

        n_lines = rng.choices(list(LINE_COUNT_WEIGHTS), weights=LINE_COUNT_WEIGHTS.values())[0]
        for line_number in range(1, n_lines + 1):
            line_id += 1
            sku, _, price = rng.choice(PRODUCTS)
            quantity = rng.choices([1, 2, 3, 4], weights=[70, 18, 8, 4])[0]
            amount = round(price * quantity, 2)
            line_updated = updated_at + timedelta(minutes=line_number)
            lines.append([line_id, order_id, line_number, sku, quantity, amount, line_updated])
            if rng.random() < RESYNC_RATE:
                lines.append([line_id, order_id, line_number, sku, quantity, amount, line_updated + timedelta(hours=6)])

    rng.shuffle(orders)
    rng.shuffle(lines)

    SEEDS_DIR.mkdir(exist_ok=True)
    write(SEEDS_DIR / "raw_orders.csv", ["order_id", "customer_id", "ordered_at", "status", "updated_at"], orders)
    write(
        SEEDS_DIR / "raw_order_lines.csv",
        ["order_line_id", "order_id", "line_number", "sku", "quantity", "amount", "updated_at"],
        lines,
    )
    print(f"raw_orders: {len(orders):,} rows · raw_order_lines: {len(lines):,} rows ({line_id:,} distinct lines)")


def write(path: Path, header: list[str], rows: list[list]) -> None:
    with path.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for row in rows:
            writer.writerow([v.isoformat(sep=" ") if isinstance(v, datetime) else v for v in row])


if __name__ == "__main__":
    main()
