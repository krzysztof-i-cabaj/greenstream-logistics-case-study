# 🤖 Przepływ Pracy Agenta AI: Strojenie Wydajności GreenStream Logistics

**Rola:** Senior Oracle DBA & Ekspert ds. Tuningu Wydajności
**Środowisko:** Oracle Database 23ai (włączone AI Vector Search)
**Narzędzia:** VSCode, GitHub Copilot/Cursor, Model Context Protocol (MCP) via `sql -mcp`

---

## 🎯 Cel
Twoim celem jest analiza wąskich gardeł wydajności w bazie danych **GreenStream Logistics**, wdrożenie optymalizacji (indeksowanie, przepisywanie zapytań) oraz udokumentowanie rozwiązań w **Bazie Wiedzy RAG** (`perf_knowledge_base`) przy użyciu Wektorów (Vector Embeddings).

---

## 🛠️ Krok 1: Diagnoza i Analiza
**Plik Wejściowy:** `05_bad_performance_scenarios.sql`

System doświadcza spowolnień podczas zdarzeń o dużym obciążeniu (np. Black Friday).
1.  Uruchom scenariusze z pliku `05_bad_performance_scenarios.sql` używając narzędzia MCP.
2.  Przeanalizuj **Plany Wykonania** (`EXPLAIN PLAN`).
3.  Zidentyfikuj przyczyny źródłowe (np. `TABLE ACCESS FULL`, brakujące predykaty, wysoki koszt `COST`, `SORT ORDER BY` na dużych zbiorach danych).

**👉 Prompt dla Agenta AI:**
> "Połącz się z bazą danych używając MCP. Przeczytaj i wykonaj zapytania SQL z pliku `05_bad_performance_scenarios.sql`. Dla każdego zapytania przeanalizuj Plan Wykonania (Explain Plan). Wylistuj konkretne wąskie gardła wydajności (np. Full Table Scans, iloczyny kartezjańskie, nieindeksowane klucze obce). Jeszcze ich nie naprawiaj; dostarcz jedynie raport diagnostyczny."

---

## 🚀 Krok 2: Wdrożenie (Naprawa)
**Plik Wyjściowy:** `07_performance_fixes.sql`

Na podstawie swojej diagnozy stwórz skrypt naprawczy.
* **Scenariusz 1 (Wyszukiwanie Email):** Zapytanie używa `UPPER(email)`. Standardowe indeksy nie zadziałają. Zasugeruj **Indeks Funkcyjny** (Function-Based Index).
* **Scenariusz 2 (Złączenia/Joins):** Tabele są łączone po ID bez indeksów. Zasugeruj standardowe **Indeksy B-Tree** na kolumnach kluczy obcych, aby umożliwić `NESTED LOOPS` zamiast `HASH JOIN`.
* **Scenariusz 3 (Stronicowanie/Pagination):** Zapytanie sortuje *wszystkie* wiersze przed pobraniem pierwszych 10. Zasugeruj indeks wspierający eliminację sortowania (Top-N Optimization).

**👉 Prompt dla Agenta AI:**
> "Na podstawie diagnozy wygeneruj nowy plik SQL o nazwie `07_performance_fixes.sql`. Napisz instrukcje DDL tworzące niezbędne indeksy, aby naprawić Scenariusze 1, 2 i 3. Dodaj komentarze wyjaśniające, *dlaczego* wybrano dany indeks (np. 'Indeks funkcyjny wspierający wyszukiwanie bez uwzględniania wielkości liter'). Wykonaj te poprawki."

---

## 🧠 Krok 3: Zasilenie Bazy Wiedzy RAG
**Plik Wejściowy:** `06_rag_management.sql` (Użyj procedury `register_performance_fix`)

Musimy upewnić się, że AI uczy się na tym incydencie. Zwektoryzujesz rozwiązanie i zapiszesz je w bazie danych.

**👉 Prompt dla Agenta AI:**
> "Teraz zaktualizujmy system RAG. Użyj procedury `register_performance_fix` zdefiniowanej w `06_rag_management.sql`.
>
> Stwórz blok PL/SQL rejestrujący wdrożone rozwiązania:
> 1. **Kategoria:** 'MISSING_INDEX' / **Opis:** 'Wolne wyszukiwanie bez uwzględniania wielkości liter w Customers' / **Rozwiązanie:** Użyta komenda CREATE INDEX.
> 2. **Kategoria:** 'JOIN_PERFORMANCE' / **Opis:** 'Kosztowny Hash Join na Orders/Logistics' / **Rozwiązanie:** Komendy indeksów FK.
>
> Wykonaj ten blok, aby wygenerować wektory (embeddings) i zapisać je w `perf_knowledge_base`."

---

## 🔍 Krok 4: Weryfikacja (Wyszukiwanie Wektorowe)
**Cel:** Zweryfikuj, czy baza danych potrafi kontekstowo odnaleźć te rozwiązania.

**👉 Prompt dla Agenta AI:**
> "Przetestuj możliwości RAG. Uruchom zapytanie wyszukujące podobieństwo (używając `VECTOR_DISTANCE`), aby znaleźć rozwiązania dla promptu w języku naturalnym: 'Jak zoptymalizować wolne zapytania podczas szukania emaili użytkowników?'.
>
> Zweryfikuj, czy rozwiązanie, które właśnie zarejestrowaliśmy, pojawia się z wysokim wynikiem podobieństwa (niski dystans)."

---

## 📊 Krok 5: Raport Końcowy
**Cel:** Podsumowanie dla interesariuszy.

**👉 Prompt dla Agenta AI:**
> "Wygeneruj raport podsumowujący w Markdown.
> - Wylistuj początkowe problemy.
> - Opisz zastosowane poprawki.
> - Porównaj plany wykonania 'Przed' i 'Po' (teoretyczne lub zaobserwowane).
> - Potwierdź, że wiedza została pomyślnie przekazana do systemu RAG."