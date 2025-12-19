# 🤖 AI Agent Workflow: GreenStream Logistics Performance Tuning

**Role:** Senior Oracle DBA & Performance Tuning Expert
**Environment:** Oracle Database 23ai (AI Vector Search enabled)
**Tools:** VSCode, GitHub Copilot/Cursor, Model Context Protocol (MCP) via `sql -mcp`

---

## 🎯 Objective
Your goal is to analyze performance bottlenecks in the **GreenStream Logistics** database, implement optimizations (indexing, query rewriting), and document the solutions into the **RAG Knowledge Base** (`perf_knowledge_base`) using Vector Embeddings.

---

## 🛠️ Step 1: Diagnosis & Analysis
**Input File:** `05_bad_performance_scenarios.sql`

The system is experiencing slowdowns during high-load events (e.g., Black Friday).
1.  Execute the scenarios in `05_bad_performance_scenarios.sql` using the MCP tool.
2.  Analyze the **Execution Plans** (`EXPLAIN PLAN`).
3.  Identify the root causes (e.g., `TABLE ACCESS FULL`, missing predicates, high `COST`, `SORT ORDER BY` on large datasets).

**👉 Prompt for AI Agent:**
> "Connect to the database using MCP. Read and execute the SQL queries found in `05_bad_performance_scenarios.sql`. For each query, analyze the Explain Plan. List the specific performance bottlenecks (e.g., Full Table Scans, Cartesian products, unindexed Foreign Keys). Do not fix them yet; just provide a diagnostic report."

---

## 🚀 Step 2: Implementation (The Fix)
**Output File:** `07_performance_fixes.sql`

Based on your diagnosis, create a remediation script.
* **Scenario 1 (Email Search):** The query uses `UPPER(email)`. Standard indexes won't work. Suggest a **Function-Based Index**.
* **Scenario 2 (Joins):** Tables are joined via IDs without indexes. Suggest standard **B-Tree Indexes** on Foreign Key columns to enable `NESTED LOOPS` instead of `HASH JOIN`.
* **Scenario 3 (Pagination):** The query sorts *all* rows before fetching the top 10. Suggest an index to support `ORDER BY` elimination (Top-N Optimization).

**👉 Prompt for AI Agent:**
> "Based on the diagnosis, generate a new SQL file named `07_performance_fixes.sql`. Write the DDL statements to create the necessary indexes to fix Scenarios 1, 2, and 3. Add comments explaining *why* each index was chosen (e.g., 'Function-based index to support case-insensitive search'). Execute these fixes."

---

## 🧠 Step 3: RAG Knowledge Base Population
**Input File:** `06_rag_management.sql` (Use `register_performance_fix` procedure)

We must ensure that the AI learns from this incident. You will vectorize the solution and store it in the database.

**👉 Prompt for AI Agent:**
> "Now, let's update the RAG system. Use the `register_performance_fix` procedure defined in `06_rag_management.sql`.
>
> Create a PL/SQL block to register the solutions you just implemented:
> 1. **Category:** 'MISSING_INDEX' / **Desc:** 'Slow case-insensitive search on Customers' / **Solution:** The CREATE INDEX command you used.
> 2. **Category:** 'JOIN_PERFORMANCE' / **Desc:** 'High cost Hash Join on Orders/Logistics' / **Solution:** The FK Index commands.
>
> Execute this block to generate vector embeddings and save them to `perf_knowledge_base`."

---

## 🔍 Step 4: Verification (Vector Search)
**Goal:** Verify that the database can contextually find these solutions.

**👉 Prompt for AI Agent:**
> "Test the RAG capabilities. Run a similarity search query (using `VECTOR_DISTANCE`) to find solutions for the natural language prompt: 'How to optimize slow queries when searching for user emails?'.
>
> Verify if the solution we just registered appears with a high similarity score (low distance)."

---

## 📊 Step 5: Final Report
**Goal:** Summary for stakeholders.

**👉 Prompt for AI Agent:**
> "Generate a summary report in Markdown.
> - List the initial problems found.
> - Describe the applied fixes.
> - Compare the 'Before' and 'After' execution plans (theoretical or observed).
> - Confirm that the knowledge has been successfully offloaded to the RAG system."