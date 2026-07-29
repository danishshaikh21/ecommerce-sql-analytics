# ==============================================================================
# E-Commerce Data Generator (PowerShell Edition)
# Generates >100,000 realistic records for PostgreSQL / MySQL benchmark SQL
# ==============================================================================

$outputPath = "C:\Users\psc\.gemini\antigravity\scratch\ecommerce-sql-analytics\sql\02_insert_data.sql"
Write-Host "Generating E-Commerce Seed Data (>100,000 records)..."

$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("-- ==============================================================================")
[void]$sb.AppendLine("-- E-COMMERCE SEED DATA INSERTION SCRIPT")
[void]$sb.AppendLine("-- Dataset Size: >100,000 total records")
[void]$sb.AppendLine("-- Target DB: PostgreSQL / MySQL / Standard ANSI SQL")
[void]$sb.AppendLine("-- ==============================================================================`n")

# 1. Categories
[void]$sb.AppendLine("-- 1. Insert Categories")
[void]$sb.AppendLine("INSERT INTO categories (category_id, category_name, parent_category_id, description) VALUES")
$categories = @(
    "(1, 'Electronics', NULL, 'Consumer electronics, gadgets, and personal tech')",
    "(2, 'Computers & Laptops', 1, 'Desktops, laptops, monitors, and components')",
    "(3, 'Smartphones & Accessories', 1, 'Mobile devices, chargers, cases, and audio')",
    "(4, 'Home & Kitchen', NULL, 'Home appliances, furniture, cookware, and decor')",
    "(5, 'Kitchen Appliances', 4, 'Coffee makers, blenders, air fryers, and microwaves')",
    "(6, 'Apparel & Fashion', NULL, 'Men, Women, and Kids clothing and footwear')",
    "(7, 'Men''s Wear', 6, 'Shirts, jeans, suits, and activewear')",
    "(8, 'Women''s Wear', 6, 'Dresses, tops, skirts, and activewear')",
    "(9, 'Beauty & Personal Care', NULL, 'Skincare, cosmetics, hair care, and fragrance')",
    "(10, 'Sports & Outdoors', NULL, 'Fitness equipment, camping gear, and sportswear')",
    "(11, 'Books & Stationery', NULL, 'Physical books, e-readers, office supplies')",
    "(12, 'Toys & Games', NULL, 'Board games, action figures, and educational toys')"
)
[void]$sb.AppendLine(($categories -join ",`n") + ";`n")

# 2. Suppliers
[void]$sb.AppendLine("-- 2. Insert Suppliers")
[void]$sb.AppendLine("INSERT INTO suppliers (supplier_id, supplier_name, contact_name, email, phone, city, state, country, rating) VALUES")
$suppliers = @(
    "(1, 'TechSupply Global', 'John Miller', 'contact@techsupply.com', '+1-555-0192', 'San Jose', 'CA', 'USA', 4.85)",
    "(2, 'Apex Logistics & Goods', 'Sarah Jenkins', 'sales@apexgoods.com', '+1-555-0283', 'Dallas', 'TX', 'USA', 4.70)",
    "(3, 'Nexus Electronics Corp', 'David Zhang', 'info@nexuselectronics.com', '+1-555-0374', 'Seattle', 'WA', 'USA', 4.92)",
    "(4, 'OmniHome Products Inc', 'Emily Davis', 'support@omnihome.com', '+1-555-0465', 'Chicago', 'IL', 'USA', 4.55)",
    "(5, 'Starlight Fashion Ltd', 'Marcus Vance', 'vance@starlightfashion.com', '+1-555-0556', 'New York', 'NY', 'USA', 4.65)",
    "(6, 'Vanguard Sports Gear', 'Chloe Bennett', 'info@vanguardsports.com', '+1-555-0647', 'Denver', 'CO', 'USA', 4.80)",
    "(7, 'Horizon Book Distributors', 'Robert Chen', 'orders@horizonbooks.com', '+1-555-0738', 'Boston', 'MA', 'USA', 4.60)",
    "(8, 'Pinnacle Beauty Direct', 'Jessica Taylor', 'b2b@pinnaclebeauty.com', '+1-555-0829', 'Miami', 'FL', 'USA', 4.75)"
)
[void]$sb.AppendLine(($suppliers -join ",`n") + ";`n")

# 3. Products (120 catalog items)
[void]$sb.AppendLine("-- 3. Insert Products")
[void]$sb.AppendLine("INSERT INTO products (product_id, product_name, category_id, supplier_id, unit_cost, unit_price, stock_quantity) VALUES")
$prodTemplates = @(
    @("UltraSlim 15-inch Laptop", 2, 1, 650.00, 999.99, 150),
    @("4K Ultra HD Curved Monitor 32-inch", 2, 3, 280.00, 449.99, 85),
    @("Wireless Noise-Canceling Headphones", 3, 1, 75.00, 199.99, 320),
    @("Flagship Smartphone 256GB", 3, 3, 500.00, 899.99, 210),
    @("Ergonomic Mechanical Keyboard", 2, 3, 45.00, 89.99, 450),
    @("Precision Gaming Mouse", 2, 3, 25.00, 59.99, 500),
    @("Smart Fitness Watch v4", 3, 1, 90.00, 179.99, 280),
    @("Portable Bluetooth Speaker", 3, 1, 30.00, 69.99, 600),
    @("Digital Air Fryer 5.8 Qt", 5, 4, 40.00, 89.99, 190),
    @("Espresso & Cappuccino Maker", 5, 4, 180.00, 349.99, 110),
    @("High-Speed Multi-Blender", 5, 4, 35.00, 79.99, 240),
    @("Robot Vacuum with Mop Combo", 4, 4, 220.00, 429.99, 95),
    @("Stainless Steel Cookware Set 10-Piece", 5, 4, 85.00, 169.99, 140),
    @("Men''s Waterproof Trail Jacket", 7, 6, 40.00, 95.00, 300),
    @("Men''s Slim-Fit Stretch Chinos", 7, 5, 20.00, 49.99, 420),
    @("Women''s Thermal Running Leggings", 8, 6, 18.00, 42.99, 380),
    @("Women''s Classic Trench Coat", 8, 5, 65.00, 149.99, 160),
    @("Leather Executive Backpack", 6, 5, 45.00, 110.00, 220),
    @("Hydrating Face Serum 50ml", 9, 8, 12.00, 38.00, 750),
    @("Organic Herbal Shampoo & Conditioner", 9, 8, 8.00, 24.99, 900),
    @("Adjustable Dumbbell Set 50lbs", 10, 6, 110.00, 229.99, 130),
    @("All-Weather 4-Person Camping Tent", 10, 6, 70.00, 159.99, 100),
    @("Professional Yoga Mat 6mm", 10, 6, 12.00, 34.99, 650),
    @("Data Science & Machine Learning Masterclass", 11, 7, 15.00, 45.00, 400),
    @("SQL for Data Analytics Handbook", 11, 7, 12.00, 39.99, 550),
    @("Strategy Board Game - Settlers Edition", 12, 7, 22.00, 49.99, 270),
    @("STEM Robotic Building Kit", 12, 7, 35.00, 79.99, 210)
)

$productRows = @()
$prodCount = 1
foreach ($pt in $prodTemplates) {
    $pname = $pt[0]
    $cat = $pt[1]
    $sup = $pt[2]
    $cost = $pt[3]
    $price = $pt[4]
    $stk = $pt[5]

    $productRows += "($prodCount, '$pname', $cat, $sup, $cost, $price, $stk)"
    $prodCount++

    # Add variants to reach ~100 distinct SKUs
    $productRows += "($prodCount, '$pname - Midnight Black', $cat, $sup, $([math]::Round($cost * 1.05, 2)), $([math]::Round($price * 1.05, 2)), $([math]::Max(20, [int]($stk / 2))))"
    $prodCount++
    $productRows += "($prodCount, '$pname - Platinum Silver', $cat, $sup, $([math]::Round($cost * 1.08, 2)), $([math]::Round($price * 1.08, 2)), $([math]::Max(15, [int]($stk / 3))))"
    $prodCount++
    $productRows += "($prodCount, '$pname - Special Edition', $cat, $sup, $([math]::Round($cost * 1.20, 2)), $([math]::Round($price * 1.20, 2)), $([math]::Max(10, [int]($stk / 4))))"
    $prodCount++
}
[void]$sb.AppendLine(($productRows -join ",`n") + ";`n")

# 4. Customers (5,000 customers)
Write-Host "Generating 5,000 Customers..."
$firstNames = @("James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda", "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa", "Matthew", "Betty", "Anthony", "Margaret", "Mark", "Sandra")
$lastNames = @("Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin")
$locations = @(
    @("New York", "NY", "10001"), @("Los Angeles", "CA", "90001"), @("Chicago", "IL", "60601"),
    @("Houston", "TX", "77001"), @("Phoenix", "AZ", "85001"), @("Philadelphia", "PA", "19101"),
    @("San Antonio", "TX", "78201"), @("San Diego", "CA", "92101"), @("Dallas", "TX", "75201"),
    @("San Jose", "CA", "95101"), @("Austin", "TX", "78701"), @("Seattle", "WA", "98101"),
    @("Denver", "CO", "80201"), @("Boston", "MA", "02101"), @("Miami", "FL", "33101"),
    @("Atlanta", "GA", "30301"), @("San Francisco", "CA", "94101"), @("Detroit", "MI", "48201")
)
$segments = @("Standard", "Standard", "Standard", "Silver", "Silver", "Gold", "VIP", "Enterprise")

[void]$sb.AppendLine("-- 4. Insert Customers")
$custRows = @()
$baseDate = Get-Date "2024-01-01 00:00:00"

for ($i = 1; $i -le 5000; $i++) {
    $fn = $firstNames[($i % $firstNames.Length)]
    $ln = $lastNames[(($i * 3) % $lastNames.Length)]
    $email = "$($fn.ToLower()).$($ln.ToLower())$i@example.com"
    $phone = "+1-555-" + ("{0:D3}" -f ($i % 900 + 100)) + "-" + ("{0:D4}" -f (($i * 7) % 9000 + 1000))
    $loc = $locations[($i % $locations.Length)]
    $city = $loc[0]
    $state = $loc[1]
    $zip = $loc[2]
    $seg = $segments[($i % $segments.Length)]
    $cDate = $baseDate.AddDays(($i % 900)).AddHours(($i % 24)).ToString("yyyy-MM-dd HH:mm:ss")

    $custRows += "($i, '$fn', '$ln', '$email', '$phone', '$city', '$state', '$zip', '$seg', '$cDate')"

    if ($custRows.Count -eq 1000) {
        [void]$sb.AppendLine("INSERT INTO customers (customer_id, first_name, last_name, email, phone, city, state, postal_code, customer_segment, created_at) VALUES")
        [void]$sb.AppendLine(($custRows -join ",`n") + ";`n")
        $custRows = @()
    }
}
if ($custRows.Count -gt 0) {
    [void]$sb.AppendLine("INSERT INTO customers (customer_id, first_name, last_name, email, phone, city, state, postal_code, customer_segment, created_at) VALUES")
    [void]$sb.AppendLine(($custRows -join ",`n") + ";`n")
}

# 5. Orders, Line Items & Payments
# Target: 22,000 Orders, ~75,000 Line Items, 22,000 Payments
Write-Host "Generating 22,000 Orders, 75,000 Line Items & 22,000 Payments..."
$statuses = @("Completed", "Completed", "Completed", "Completed", "Completed", "Completed", "Processing", "Shipped", "Cancelled", "Returned")
$channels = @("Web", "Mobile App", "Marketplace", "POS")
$payMethods = @("Credit Card", "PayPal", "Apple Pay", "Google Pay", "BNPL", "Bank Transfer")
$shipCosts = @(0.00, 0.00, 5.99, 9.99, 14.99)

$orderItemCounter = 1
$paymentCounter = 1

$ordRows = @()
$itemRows = @()
$payRows = @()

for ($oid = 1; $oid -le 22000; $oid++) {
    $cid = (($oid * 13) % 5000) + 1
    $oDays = ($oid % 920)
    $oDate = $baseDate.AddDays($oDays).AddHours(($oid % 24)).AddMinutes(($oid % 60)).ToString("yyyy-MM-dd HH:mm:ss")
    $status = $statuses[($oid % $statuses.Length)]
    $scost = $shipCosts[($oid % $shipCosts.Length)]
    $loc = $locations[($oid % $locations.Length)]
    $scity = $loc[0]
    $sstate = $loc[1]
    $channel = $channels[($oid % $channels.Length)]

    $ordRows += "($oid, $cid, '$oDate', '$status', $scost, '$scity', '$sstate', '$channel')"

    # Line Items (1 to 4 items)
    $numItems = (($oid % 4) + 1)
    $subtotal = 0.0

    for ($k = 0; $k -lt $numItems; $k++) {
        $prodId = ((($oid * 7) + ($k * 19)) % $productRows.Length) + 1
        $qty = (($k % 3) + 1)
        # Approximate unit prices by product ID pattern
        $uprice = [math]::Round(25.0 + (($prodId * 17) % 350), 2)
        $disc = 0.0
        if (($oid + $k) % 5 -eq 0) { $disc = [math]::Round($uprice * $qty * 0.10, 2) }
        $lineTotal = [math]::Round(($qty * $uprice) - $disc, 2)
        $subtotal += $lineTotal

        $itemRows += "($orderItemCounter, $oid, $prodId, $qty, $uprice, $disc)"
        $orderItemCounter++
    }

    # Payments
    $pstatus = if ($status -in @("Completed", "Shipped", "Processing")) { "Completed" } elseif ($status -eq "Returned") { "Refunded" } else { "Failed" }
    $pmeth = $payMethods[($oid % $payMethods.Length)]
    $pamt = [math]::Round($subtotal + $scost, 2)
    $pref = "TXN-2025-" + ("{0:D6}" -f $oid)

    $payRows += "($paymentCounter, $oid, '$oDate', '$pmeth', '$pstatus', $pamt, '$pref')"
    $paymentCounter++

    # Batch append to stringbuilder to manage memory efficiently
    if ($ordRows.Count -eq 1000) {
        [void]$sb.AppendLine("INSERT INTO orders (order_id, customer_id, order_date, order_status, shipping_cost, shipping_city, shipping_state, sales_channel) VALUES")
        [void]$sb.AppendLine(($ordRows -join ",`n") + ";`n")
        $ordRows = @()
    }
    if ($itemRows.Count -ge 2000) {
        [void]$sb.AppendLine("INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price, discount_amount) VALUES")
        [void]$sb.AppendLine(($itemRows -join ",`n") + ";`n")
        $itemRows = @()
    }
    if ($payRows.Count -eq 1000) {
        [void]$sb.AppendLine("INSERT INTO payments (payment_id, order_id, payment_date, payment_method, payment_status, amount_paid, transaction_reference) VALUES")
        [void]$sb.AppendLine(($payRows -join ",`n") + ";`n")
        $payRows = @()
    }
}

# Flush remaining
if ($ordRows.Count -gt 0) {
    [void]$sb.AppendLine("INSERT INTO orders (order_id, customer_id, order_date, order_status, shipping_cost, shipping_city, shipping_state, sales_channel) VALUES")
    [void]$sb.AppendLine(($ordRows -join ",`n") + ";`n")
}
if ($itemRows.Count -gt 0) {
    [void]$sb.AppendLine("INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price, discount_amount) VALUES")
    [void]$sb.AppendLine(($itemRows -join ",`n") + ";`n")
}
if ($payRows.Count -gt 0) {
    [void]$sb.AppendLine("INSERT INTO payments (payment_id, order_id, payment_date, payment_method, payment_status, amount_paid, transaction_reference) VALUES")
    [void]$sb.AppendLine(($payRows -join ",`n") + ";`n")
}

[void]$sb.AppendLine("-- Reset PostgreSQL Sequences")
[void]$sb.AppendLine("SELECT setval('categories_category_id_seq', (SELECT MAX(category_id) FROM categories));")
[void]$sb.AppendLine("SELECT setval('suppliers_supplier_id_seq', (SELECT MAX(supplier_id) FROM suppliers));")
[void]$sb.AppendLine("SELECT setval('products_product_id_seq', (SELECT MAX(product_id) FROM products));")
[void]$sb.AppendLine("SELECT setval('customers_customer_id_seq', (SELECT MAX(customer_id) FROM customers));")
[void]$sb.AppendLine("SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));")
[void]$sb.AppendLine("SELECT setval('order_items_order_item_id_seq', (SELECT MAX(order_item_id) FROM order_items));")
[void]$sb.AppendLine("SELECT setval('payments_payment_id_seq', (SELECT MAX(payment_id) FROM payments));")

Write-Host "Writing seed file to disk..."
[System.IO.File]::WriteAllText($outputPath, $sb.ToString())
Write-Host "Done! Seed file created successfully. File size: $([math]::Round((Get-Item $outputPath).Length / 1MB, 2)) MB"
