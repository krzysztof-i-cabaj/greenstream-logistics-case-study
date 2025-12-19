/* * ======================================================================================
 * SCRIPT: 06_rag_management.sql
 * AUTHOR: KCB Kris
 * PL: Procedury RAG: Rejestracja rozwiązań i Wyszukiwanie Kontekstowe
 * EN: RAG Procedures: Solution Registration and Contextual Search
 * ======================================================================================
 */

SET SERVEROUTPUT ON

-- A. PROCEDURE: REGISTER FIX
-- PL: Procedura standaryzująca wpisy do bazy wiedzy. 
--     Automatycznie zamienia tekst na wektor (Embedding).
-- EN: Procedure standardizing entries into knowledge base.
--     Automatically converts text to vector (Embedding).
CREATE OR REPLACE PROCEDURE register_performance_fix(
    p_category    IN VARCHAR2,
    p_sql_id      IN VARCHAR2,
    p_description IN VARCHAR2,
    p_solution    IN CLOB
) IS
    v_combined_text CLOB;
    v_vector        VECTOR(384, FLOAT32);
BEGIN
    -- 1. Context Enrichment
    -- PL: Tworzymy bogatszy kontekst dla modelu językowego
    -- EN: Creating richer context for the language model
    v_combined_text := 'CATEGORY: ' || p_category || '. ISSUE: ' || p_description;

        -- 2. Generate Vector
        -- PL: Wywołanie modelu ONNX załadowanego w bazie
        -- EN: Calling ONNX model loaded inside the database
        SELECT VECTOR_EMBEDDING(DOC_MODEL USING v_combined_text AS DATA)
            INTO v_vector
            FROM dual;

        -- 3. Store in Knowledge Base
        INSERT INTO perf_knowledge_base (issue_category, sql_signature, problem_desc, solution_script, embedding)
        VALUES (p_category, p_sql_id, p_description, p_solution, v_vector);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[RAG] ✓ Solution registered for SQL: ' || p_sql_id);
END;
/

-- B. INITIAL DATA LOAD
-- PL: Załadowanie przykładowej wiedzy "historycznej"
-- EN: Loading sample "historical" knowledge
BEGIN
    register_performance_fix(
        'MISSING_INDEX', 
        'sql_prev_001', 
        'Slow query filtering by generic column caused Full Table Scan.', 
        'CREATE INDEX idx_generic ON table_name(column_name); -- Check cardinality first'
    );
    
    register_performance_fix(
        'LOCKING', 
        'sql_prev_002', 
        'Application hangs due to uncommitted transaction (TX Lock).', 
        'Identify blocker: SELECT * FROM v$session WHERE status = "ACTIVE". Kill blocker if needed.'
    );
    DBMS_OUTPUT.PUT_LINE('[INFO] Knowledge Base initialized.');
END;
/

-- C. SEARCH QUERY EXAMPLE (AI Agent Tool)
-- PL: To zapytanie wykonuje Agent AI, szukając podobnych problemów.
-- EN: This query is executed by AI Agent to find similar issues.
PROMPT [INFO] Testing Similarity Search...

VAR input_problem VARCHAR2(4000);
-- PL: Symulujemy zapytanie o powolne wyszukiwanie klientów
-- EN: Simulating a query about slow customer search
EXEC :input_problem := 'Customers query is extremely slow when searching by email ignoring case.';

SELECT 
    issue_category,
    problem_desc,
    DBMS_LOB.SUBSTR(solution_script, 100, 1) as solution_snippet,
    -- PL: Obliczenie odległości kosinusowej (im bliżej 0, tym bardziej podobne)
    -- EN: Calculating cosine distance (closer to 0 means more similar)
    ROUND(VECTOR_DISTANCE(embedding, VECTOR_EMBEDDING(DOC_MODEL USING :input_problem AS DATA), COSINE), 4) as similarity_score
FROM perf_knowledge_base
ORDER BY similarity_score ASC
FETCH FIRST 3 ROWS ONLY;