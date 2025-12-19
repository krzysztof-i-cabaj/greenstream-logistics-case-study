-- Sample RAG similarity query for prompts used in the report.
VAR input_problem VARCHAR2(4000);

-- Example prompt: adjust as needed
EXEC :input_problem := 'How to optimize slow user email search ignoring case?';

SELECT issue_category,
       problem_desc,
       DBMS_LOB.SUBSTR(solution_script, 250, 1) AS solution_snippet,
       ROUND(VECTOR_DISTANCE(embedding, VECTOR_EMBEDDING(DOC_MODEL USING :input_problem AS DATA), COSINE), 4) AS similarity_score
FROM perf_knowledge_base
ORDER BY similarity_score ASC
FETCH FIRST 5 ROWS ONLY;
