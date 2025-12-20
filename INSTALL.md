# 🛠 Installation & Reproduction Guide

This document contains detailed instructions for installing, configuring, and running the **GreenStream Logistics** case study. You will go step by step through the process of generating performance issues, diagnosing them using AI, and fixing the system.

---

## 📋 1. Prerequisites

Before starting, make sure you have:

1.  **Oracle Database 23ai**
   * Version: Free Developer Release or Enterprise.
   * Access to PDB container (e.g., `freepdb1`).

2.  **Configured `vec_admin` user**
   * Privileges: `DB_DEVELOPER_ROLE`, `CREATE MINING MODEL`, quota on tablespace.

3.  **Loaded ONNX Model**
   * Model: `all-MiniLM-L12-v2`
   * Database name: `DOC_MODEL`
   * Status: Model must be imported into the database (e.g., via `DBMS_VECTOR.LOAD_ONNX_MODEL`).



> 🔗 **Important:** This project is based on the environment prepared in the **ora26ai-vector-rag-demo** workshop. If you don't have the `DOC_MODEL` model yet, first complete the instructions from that repository:

> [👉 github.com/krzysztof-i-cabaj/ora26ai-vector-rag-demo](https://github.com/krzysztof-i-cabaj/ora26ai-vector-rag-demo)

4.  **Tools**
   * SQLcl, SQL Developer (Web/Desktop), or VS Code with Oracle extension.
   * Git.

---

## ⚙️ 2. Environment Setup (Installation)

### Step 2.1: Clone the repository

Download the project files to your local disk:

```bash
git clone https://github.com/krzysztof-i-cabaj/greenstream-logistics-case-study.git
cd greenstream-logistics-case-study
```

### Step 2.2: Data Generation

Connect to the database as the `vec_admin` user and run the setup script.

* **Goal:** Create CUSTOMERS, ORDERS, LOGISTICS_EVENTS tables and generate ~10k-50k records without indexes.

* **Script:** `sql/01_setup/04_logistics_setup.sql`

**Run in SQLcl / SQLPlus:**
```sql
-- Connect as vec_admin
CONN vec_admin/your_password@localhost:1521/freepdb1

-- Run the script
@sql/01_setup/04_logistics_setup.sql
```

**✅ Expected result:** Message [SUCCESS] Data generation complete. and created tables.


---

## 💥 3. Simulate Performance Issues

In this step, we will run queries that deliberately stress the database ("Bad SQL"), simulating a system failure during peak order volume.

* **Goal:** Observe high costs (Cost), Full Table Scans, and disk sorting.
* **Script:** `sql/02_scenarios/05_bad_performance_scenarios.sql`

```sql
SET AUTOTRACE ON EXPLAIN
@sql/02_scenarios/05_bad_performance_scenarios.sql
```

Pay attention to query plans:
* **Scenario 1:** TABLE ACCESS FULL on CUSTOMERS table (Function Killer).
* **Scenario 2:** HASH JOIN with high cost (Join Performance).
* **Scenario 3:** SORT ORDER BY STOPKEY consuming TempSpc (Pagination Nightmare).

---

## 🧠 4. Initialize RAG Knowledge Base

Configure the RAG (Retrieval-Augmented Generation) engine, which will help the AI Agent search for solutions to similar problems.

* **Goal:** Create the `PERF_KNOWLEDGE_BASE` table, `register_performance_fix` procedure, and add sample vectors.
* **Script:** `sql/04_rag_engine/06_rag_management.sql`

---

## 🕵️ 5. AI Diagnosis & Analysis

Before deploying fixes, verify the current state and vector search functionality.

**5.1 Check costs (Baseline)**
Run the analytical script to record current query costs:
```sql
@sql/05_analysis_metrics/50_plan_costs.sql
```
**5.2 Test RAG Similarity**
Check if the database can find solutions for natural language queries (e.g., "slow email search"):
```sql
@sql/05_analysis_metrics/50_rag_similarity_samples.sql
```

---

## 🔧 6. Apply Fixes

Now we'll take on the role of the AI Agent, which applies fixes identified in the diagnosis phase.

* **Goal:** Create missing indexes (B-Tree, Function-Based) and optimize queries.
* **Script:** `sql/03_solutions/07_performance_fixes.sql`

```sql
@sql/03_solutions/07_performance_fixes.sql
```

This script will execute, among others:

1. `CREATE INDEX idx_cust_email_upper ...` (Solution for Scenario 1)
2. `CREATE INDEX idx_orders_cust_id ...` (Solution for Scenario 2)
3. Registration of these solutions in the RAG knowledge base.

---

## 📈 7. Verification

After applying fixes, recheck costs and query plans to confirm optimization effectiveness.

**7.1 Plan Comparison (Before/After)**

Run the comparison generation script:
```sql
@sql/05_analysis_metrics/51_plan_comparisons.sql
```

You should notice a dramatic drop in costs (e.g., from 4472 to 22) and a change in access methods to INDEX RANGE SCAN.

---

## 📊 8. View the HTML Report

The project generates an interactive report summarizing the entire Case Study.

The report is available at: [👉 View Case Study Report (GitHub Pages)](https://krzysztof-i-cabaj.github.io/greenstream-logistics-case-study/)

---

## ❓ Troubleshooting

**Problem:** `Error ORA-00942: table or view does not exist` when querying `V$SQL_MONITOR`. 

**Solution:** User `vec_admin` may need additional privileges to system views. Log in as SYS/SYSTEM and grant:

```sql
GRANT SELECT ON V_$SQL_MONITOR TO vec_admin;
GRANT SELECT ON V_$SQLSTATS TO vec_admin;
```

**Problem:** `ORA-00439: feature not enabled: Vector` 

**Solution:** Make sure you're using **Oracle Database 23ai** (version 23.4 or newer). Older versions (even 21c) do not support the VECTOR type.