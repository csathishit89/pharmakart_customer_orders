# Retail & Pharmacy Financial Integrity & Logistics Audit

## Overview
This repository contains SQL queries and documentation designed to audit financial data integrity, calculate delivery performance metrics, identify operational outliers, and build customer segmentation reports for a retail/pharmacy database operating on MySQL.

---

## 1. Database Setup & Architecture

### Schema Structure
The queries interact with four core tables:
* **`customers`**: Stores customer profiles (`customer_id`, `customer_name`, `city`, `state`, `acquisition_channel`).
* **`products`**: Item catalog details (`product_id`, `product_name`, `unit_price`).
* **`orders`**: Header-level transaction records (`order_id`, `customer_id`, `order_date`, `delivery_date`, `subtotal`, `coupon_code`, `discount_amount`, `delivery_fee`, `tax_amount`, `status`, `platform`).
* **`order_items`**: Line-item transaction records (`order_id`, `product_id`, `quantity`, `unit_price`).

---

## 2. Key Technical Decisions & MySQL Compatibility

### Handling MySQL Version Compatibility (Error #1064 & #1247)
* **CTE Alternatives**: To ensure compatibility across older MySQL deployments (such as MySQL 5.7 / older local MAMP environments that throw error `#1064` when using `WITH` CTEs), standard derived subqueries were used for statistical and aggregated calculations.
* **Derived Subqueries for Group Functions**: To resolve MySQL error `#1247` (*"Reference to group function not supported"*), aggregate aliases and calculated columns (like `difference`) are evaluated in an outer query wrapper rather than directly inside `HAVING` or `ORDER BY` clauses when mixed with aggregation logic.

### Filtering Precision Artifacts
* **Floating-Point Noise Control**: Standard floating-point calculations (e.g., `quantity * unit_price`) can yield minor precision artifacts like `0.0000000352`. To prevent false positives in financial discrepancy audits, differences are filtered using `ABS(difference) > 0.01` or explicitly cast to fixed-point currency via `CAST(... AS DECIMAL(10,2))`.

---

## 3. Business & Data Assumptions

### Financial Integrity Audit
1. **Order Status Scope**:
   * **Included**: Finalized or operational transaction states (`Delivered`, `Completed`, `Shipped`, `Processing`).
   * **Excluded**: `Cancelled`, `Failed`, `Refunded`, or `Draft` orders, as these undergo partial inventory rollbacks or manual adjustments that create non-actionable price mismatches.
2. **Order-Level Adjustments**:
   * Order-level fields (`discount_amount`, `delivery_fee`, `tax_amount`, `coupon_code`) were isolated alongside line-item totals to verify whether discrepancies stem from unallocated header-level surcharges or discounts.

### Logistics & Delivery Performance
1. **Data Quality Filter**:
   * Only records with valid, non-null `order_date` and `delivery_date` timestamps are included. Records where `delivery_date < order_date` are filtered out as invalid data entries.
2. **Statistical Outlier Definition ($\text{Mean} + 2\text{SD}$)**:
   * Delivery time distributions are right-skewed. To objectively identify "unusually long" deliveries without arbitrary threshold guessing, an upper-bound rule of **$\text{Mean} + 2 \times \text{Standard Deviation}$** was applied.
   * Statistically, this isolates approximately the top **2.5% slowest orders** in the dataset (the extreme upper tail of normal distribution), capturing true operational delays.

---

## 4. Summary of Key SQL Queries Provided

1. **Subtotal vs. Line-Item Total Comparison**:
   * Calculates calculated line-item total (`quantity * unit_price`) vs. stored `order.subtotal`.
2. **Discrepancy Isolation Query**:
   * Filters orders where `ABS(subtotal - calculated_item_total) > 0.01` and displays order-level discount/fee fields.
3. **Delivery Time Analytics**:
   * Compares average delivery durations by `platform`, `state`, and `city`.
4. **Delivery Outlier Identification Query**:
   * Dynamically calculates `AVG(delivery_days)` and `STDDEV(delivery_days)` across all valid orders and extracts orders exceeding `Mean + 2SD`.
5. **Customer Segmentation & Analytics Report**:
   * Consolidates customer spending, total orders, average order value (AOV), last order date, coupon usage count, and assigns spent-based customer tiers (`High Value`, `Medium Value`, `Low Value`).