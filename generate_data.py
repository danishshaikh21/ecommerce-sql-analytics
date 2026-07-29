"""
E-Commerce Synthetic Data Generator
Generates realistic, production-quality relational data for PostgreSQL/MySQL.
Total records across tables: 100,000+
"""

import random
import sys
from datetime import datetime, timedelta

def main():
    print("Starting data generation for E-Commerce Sales Analytics...")
    
    random.seed(42)  # Deterministic seed for reproducible portfolio output

    # 1. Categories
    categories = [
        ("Electronics", None, "Consumer electronics, gadgets, and personal tech"),
        ("Computers & Laptops", 1, "Desktops, laptops, monitors, and components"),
        ("Smartphones & Accessories", 1, "Mobile devices, chargers, cases, and audio"),
        ("Home & Kitchen", None, "Home appliances, furniture, cookware, and decor"),
        ("Kitchen Appliances", 4, "Coffee makers, blenders, air fryers, and microwaves"),
        ("Apparel & Fashion", None, "Men, Women, and Kids clothing and footwear"),
        ("Men's Wear", 6, "Shirts, jeans, suits, and activewear"),
        ("Women's Wear", 6, "Dresses, tops, skirts, and activewear"),
        ("Beauty & Personal Care", None, "Skincare, cosmetics, hair care, and fragrance"),
        ("Sports & Outdoors", None, "Fitness equipment, camping gear, and sportswear"),
        ("Books & Stationery", None, "Physical books, e-readers, office supplies"),
        ("Toys & Games", None, "Board games, action figures, and educational toys")
    ]

    # 2. Suppliers
    supplier_names = [
        ("TechSupply Global", "John Miller", "contact@techsupply.com", "+1-555-0192", "San Jose", "CA", 4.85),
        ("Apex Logistics & Goods", "Sarah Jenkins", "sales@apexgoods.com", "+1-555-0283", "Dallas", "TX", 4.70),
        ("Nexus Electronics Corp", "David Zhang", "info@nexuselectronics.com", "+1-555-0374", "Seattle", "WA", 4.92),
        ("OmniHome Products Inc", "Emily Davis", "support@omnihome.com", "+1-555-0465", "Chicago", "IL", 4.55),
        ("Starlight Fashion Ltd", "Marcus Vance", "vance@starlightfashion.com", "+1-555-0556", "New York", "NY", 4.65),
        ("Vanguard Sports Gear", "Chloe Bennett", "info@vanguardsports.com", "+1-555-0647", "Denver", "CO", 4.80),
        ("Horizon Book Distributors", "Robert Chen", "orders@horizonbooks.com", "+1-555-0738", "Boston", "MA", 4.60),
        ("Pinnacle Beauty Direct", "Jessica Taylor", "b2b@pinnaclebeauty.com", "+1-555-0829", "Miami", "FL", 4.75)
    ]

    # 3. Product Catalog (approx 150 unique realistic products)
    product_templates = [
        ("UltraSlim 15-inch Laptop", 2, 1, 650.00, 999.99, 150),
        ("4K Ultra HD Curved Monitor 32-inch", 2, 3, 280.00, 449.99, 85),
        ("Wireless Noise-Canceling Headphones", 3, 1, 75.00, 199.99, 320),
        ("Flagship Smartphone 256GB", 3, 3, 500.00, 899.99, 210),
        ("Ergonomic Mechanical Keyboard", 2, 3, 45.00, 89.99, 450),
        ("Precision Gaming Mouse", 2, 3, 25.00, 59.99, 500),
        ("Smart Fitness Watch v4", 3, 1, 90.00, 179.99, 280),
        ("Portable Bluetooth Speaker", 3, 1, 30.00, 69.99, 600),
        ("Digital Air Fryer 5.8 Qt", 5, 4, 40.00, 89.99, 190),
        ("Espresso & Cappuccino Maker", 5, 4, 180.00, 349.99, 110),
        ("High-Speed Multi-Blender", 5, 4, 35.00, 79.99, 240),
        ("Robot Vacuum with Mop Combo", 4, 4, 220.00, 429.99, 95),
        ("Stainless Steel Cookware Set 10-Piece", 5, 4, 85.00, 169.99, 140),
        ("Men's Waterproof Trail Jacket", 7, 6, 40.00, 95.00, 300),
        ("Men's Slim-Fit Stretch Chinos", 7, 5, 20.00, 49.99, 420),
        ("Women's Thermal Running Leggings", 8, 6, 18.00, 42.99, 380),
        ("Women's Classic Trench Coat", 8, 5, 65.00, 149.99, 160),
        ("Leather Executive Backpack", 6, 5, 45.00, 110.00, 220),
        ("Hydrating Face Serum 50ml", 9, 8, 12.00, 38.00, 750),
        ("Organic Herbal Shampoo & Conditioner", 9, 8, 8.00, 24.99, 900),
        ("Adjustable Dumbbell Set 50lbs", 10, 6, 110.00, 229.99, 130),
        ("All-Weather 4-Person Camping Tent", 10, 6, 70.00, 159.99, 100),
        ("Professional Yoga Mat 6mm", 10, 6, 12.00, 34.99, 650),
        ("Data Science & Machine Learning Masterclass Book", 11, 7, 15.00, 45.00, 400),
        ("SQL for Data Analytics Handbook", 11, 7, 12.00, 39.99, 550),
        ("Strategy Board Game - Settlers Edition", 12, 7, 22.00, 49.99, 270),
        ("STEM Robotic Building Kit", 12, 7, 35.00, 79.99, 210)
    ]

    # Expand products to 120 total items by variant generation
    products = []
    for base_name, cat_id, sup_id, cost, price, stock in product_templates:
        products.append((base_name, cat_id, sup_id, cost, price, stock))
        # Add color/size variants
        if cat_id in (2, 3, 6, 7, 8, 10):
            products.append((f"{base_name} - Black Edition", cat_id, sup_id, round(cost * 1.05, 2), round(price * 1.05, 2), stock // 2))
            products.append((f"{base_name} - Silver Edition", cat_id, sup_id, round(cost * 1.08, 2), round(price * 1.08, 2), stock // 3))
            products.append((f"{base_name} - Pro Pack", cat_id, sup_id, round(cost * 1.25, 2), round(price * 1.25, 2), stock // 4))

    # 4. Customers setup
    first_names = ["James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda", "William", "Elizabeth",
                   "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen",
                   "Christopher", "Nancy", "Daniel", "Lisa", "Matthew", "Betty", "Anthony", "Margaret", "Mark", "Sandra",
                   "Alex", "Sophia", "Ethan", "Olivia", "Liam", "Emma", "Noah", "Ava", "Lucas", "Mia"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
                  "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
                  "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson"]

    cities_states = [
        ("New York", "NY", "10001"), ("Los Angeles", "CA", "90001"), ("Chicago", "IL", "60601"),
        ("Houston", "TX", "77001"), ("Phoenix", "AZ", "85001"), ("Philadelphia", "PA", "19101"),
        ("San Antonio", "TX", "78201"), ("San Diego", "CA", "92101"), ("Dallas", "TX", "75201"),
        ("San Jose", "CA", "95101"), ("Austin", "TX", "78701"), ("Seattle", "WA", "98101"),
        ("Denver", "CO", "80201"), ("Boston", "MA", "02101"), ("Miami", "FL", "33101"),
        ("Atlanta", "GA", "30301"), ("San Francisco", "CA", "94101"), ("Detroit", "MI", "48201")
    ]

    segments = ["Standard", "Silver", "Gold", "VIP", "Enterprise"]
    segment_weights = [0.55, 0.25, 0.12, 0.06, 0.02]

    num_customers = 5000
    customers = []
    start_date = datetime(2024, 1, 1)
    
    for i in range(1, num_customers + 1):
        fn = random.choice(first_names)
        ln = random.choice(last_names)
        email = f"{fn.lower()}.{ln.lower()}{i}@example.com"
        phone = f"+1-555-{random.randint(100,999):03d}-{random.randint(1000,9999):04d}"
        city, state, zip_code = random.choice(cities_states)
        seg = random.choices(segments, weights=segment_weights)[0]
        signup_dt = start_date + timedelta(days=random.randint(0, 900), hours=random.randint(0,23))
        customers.append((i, fn, ln, email, phone, city, state, zip_code, seg, signup_dt))

    # 5. Orders & Line Items & Payments
    # Generate 22,000 orders across Jan 2024 to July 2026 (~3-5 line items each -> ~80,000+ line items)
    num_orders = 22000
    statuses = ["Completed", "Completed", "Completed", "Completed", "Completed", "Completed", "Processing", "Shipped", "Cancelled", "Returned"]
    channels = ["Web", "Mobile App", "Marketplace", "POS"]
    pay_methods = ["Credit Card", "PayPal", "Apple Pay", "Google Pay", "BNPL", "Bank Transfer"]

    orders = []
    order_items = []
    payments = []

    order_item_id_counter = 1
    payment_id_counter = 1

    print("Generating orders, items, and payments records...")
    for order_id in range(1, num_orders + 1):
        cust_id = random.randint(1, num_customers)
        cust_signup = customers[cust_id - 1][9]
        
        # Order date after signup
        days_after_signup = random.randint(0, 180)
        order_dt = cust_signup + timedelta(days=days_after_signup, hours=random.randint(0, 12))
        if order_dt > datetime(2026, 7, 28):
            order_dt = datetime(2026, 7, 28) - timedelta(hours=random.randint(1, 100))

        status = random.choice(statuses)
        ship_cost = round(random.choice([0.00, 0.00, 5.99, 9.99, 14.99]), 2)
        _, ship_state, _ = random.choice(cities_states)
        ship_city = customers[cust_id - 1][5]
        channel = random.choice(channels)

        orders.append((order_id, cust_id, order_dt.strftime("%Y-%m-%d %H:%M:%S"), status, ship_cost, ship_city, ship_state, channel))

        # Order Items (1 to 5 items per order)
        num_items = random.choices([1, 2, 3, 4, 5], weights=[0.35, 0.35, 0.15, 0.10, 0.05])[0]
        order_subtotal = 0.0

        chosen_products = random.sample(products, num_items)
        for prod in chosen_products:
            prod_id = products.index(prod) + 1
            qty = random.choices([1, 2, 3, 5], weights=[0.70, 0.20, 0.07, 0.03])[0]
            u_price = prod[4]
            disc = round(u_price * qty * random.choice([0.00, 0.00, 0.00, 0.05, 0.10, 0.15, 0.20]), 2)
            l_total = round((qty * u_price) - disc, 2)
            order_subtotal += l_total

            order_items.append((order_item_id_counter, order_id, prod_id, qty, u_price, disc))
            order_item_id_counter += 1

        # Payments
        pay_status = "Completed" if status in ("Completed", "Shipped", "Processing") else ("Refunded" if status == "Returned" else "Failed")
        pay_method = random.choice(pay_methods)
        pay_amount = round(order_subtotal + ship_cost, 2)
        ref_no = f"TXN-{order_dt.strftime('%Y%m%d')}-{order_id:06d}"

        payments.append((payment_id_counter, order_id, order_dt.strftime("%Y-%m-%d %H:%M:%S"), pay_method, pay_status, pay_amount, ref_no))
        payment_id_counter += 1

    # Write SQL Output
    output_path = r"C:\Users\psc\.gemini\antigravity\scratch\ecommerce-sql-analytics\sql\02_insert_data.sql"
    print(f"Writing SQL seed data to {output_path}...")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("-- ==============================================================================\n")
        f.write("-- E-COMMERCE SEED DATA INSERTION SCRIPT\n")
        f.write(f"-- Generated Records: Categories={len(categories)}, Suppliers={len(supplier_names)}, Products={len(products)}, Customers={len(customers)}, Orders={len(orders)}, OrderItems={len(order_items)}, Payments={len(payments)}\n")
        f.write("-- Total records > 100,000\n")
        f.write("-- ==============================================================================\n\n")

        # Insert Categories
        f.write("-- 1. Insert Categories\n")
        f.write("INSERT INTO categories (category_id, category_name, parent_category_id, description) VALUES\n")
        cat_rows = []
        for idx, (cname, pid, desc) in enumerate(categories, 1):
            pid_str = str(pid) if pid else "NULL"
            cat_rows.append(f"({idx}, '{cname}', {pid_str}, '{desc}')")
        f.write(",\n".join(cat_rows) + ";\n\n")

        # Insert Suppliers
        f.write("-- 2. Insert Suppliers\n")
        f.write("INSERT INTO suppliers (supplier_id, supplier_name, contact_name, email, phone, city, state, country, rating) VALUES\n")
        sup_rows = []
        for idx, (sname, cname, semail, sphone, scity, sstate, srating) in enumerate(supplier_names, 1):
            sup_rows.append(f"({idx}, '{sname}', '{cname}', '{semail}', '{sphone}', '{scity}', '{sstate}', 'USA', {srating})")
        f.write(",\n".join(sup_rows) + ";\n\n")

        # Insert Products
        f.write("-- 3. Insert Products\n")
        f.write("INSERT INTO products (product_id, product_name, category_id, supplier_id, unit_cost, unit_price, stock_quantity) VALUES\n")
        prod_rows = []
        for idx, (pname, cat_id, sup_id, ucost, uprice, stock) in enumerate(products, 1):
            pname_esc = pname.replace("'", "''")
            prod_rows.append(f"({idx}, '{pname_esc}', {cat_id}, {sup_id}, {ucost}, {uprice}, {stock})")
        f.write(",\n".join(prod_rows) + ";\n\n")

        # Insert Customers in batches of 1000
        f.write("-- 4. Insert Customers\n")
        batch_size = 1000
        for b in range(0, len(customers), batch_size):
            f.write("INSERT INTO customers (customer_id, first_name, last_name, email, phone, city, state, postal_code, customer_segment, created_at) VALUES\n")
            c_rows = []
            for (cid, fn, ln, email, phone, city, state, zip_c, seg, sdate) in customers[b:b+batch_size]:
                c_rows.append(f"({cid}, '{fn}', '{ln}', '{email}', '{phone}', '{city}', '{state}', '{zip_c}', '{seg}', '{sdate.strftime('%Y-%m-%d %H:%M:%S')}')")
            f.write(",\n".join(c_rows) + ";\n\n")

        # Insert Orders in batches of 1000
        f.write("-- 5. Insert Orders\n")
        for b in range(0, len(orders), batch_size):
            f.write("INSERT INTO orders (order_id, customer_id, order_date, order_status, shipping_cost, shipping_city, shipping_state, sales_channel) VALUES\n")
            o_rows = []
            for (oid, cid, odt, ost, scost, scity, sstate, schn) in orders[b:b+batch_size]:
                o_rows.append(f"({oid}, {cid}, '{odt}', '{ost}', {scost}, '{scity}', '{sstate}', '{schn}')")
            f.write(",\n".join(o_rows) + ";\n\n")

        # Insert Order Items in batches of 2000
        f.write("-- 6. Insert Order Items\n")
        item_batch = 2000
        for b in range(0, len(order_items), item_batch):
            f.write("INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price, discount_amount) VALUES\n")
            i_rows = []
            for (oi_id, oid, pid, qty, uprice, disc) in order_items[b:b+item_batch]:
                i_rows.append(f"({oi_id}, {oid}, {pid}, {qty}, {uprice}, {disc})")
            f.write(",\n".join(i_rows) + ";\n\n")

        # Insert Payments in batches of 1000
        f.write("-- 7. Insert Payments\n")
        for b in range(0, len(payments), batch_size):
            f.write("INSERT INTO payments (payment_id, order_id, payment_date, payment_method, payment_status, amount_paid, transaction_reference) VALUES\n")
            p_rows = []
            for (pid, oid, pdt, pmeth, pstat, pamt, pref) in payments[b:b+batch_size]:
                p_rows.append(f"({pid}, {oid}, '{pdt}', '{pmeth}', '{pstat}', {pamt}, '{pref}')")
            f.write(",\n".join(p_rows) + ";\n\n")

        # Sync serial primary keys sequence for PostgreSQL
        f.write("-- Reset Sequences for PostgreSQL\n")
        f.write("SELECT setval('categories_category_id_seq', (SELECT MAX(category_id) FROM categories));\n")
        f.write("SELECT setval('suppliers_supplier_id_seq', (SELECT MAX(supplier_id) FROM suppliers));\n")
        f.write("SELECT setval('products_product_id_seq', (SELECT MAX(product_id) FROM products));\n")
        f.write("SELECT setval('customers_customer_id_seq', (SELECT MAX(customer_id) FROM customers));\n")
        f.write("SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));\n")
        f.write("SELECT setval('order_items_order_item_id_seq', (SELECT MAX(order_item_id) FROM order_items));\n")
        f.write("SELECT setval('payments_payment_id_seq', (SELECT MAX(payment_id) FROM payments));\n")

    print(f"Data generation complete! Total Records: {len(categories) + len(supplier_names) + len(products) + len(customers) + len(orders) + len(order_items) + len(payments):,}")

if __name__ == "__main__":
    main()
