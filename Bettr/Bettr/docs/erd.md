erDiagram
    Script ||--o{ Sentence : "has many (sentence-based)"
    Script ||--o{ PracticeSession : "has many"
    Sentence ||--o{ Chunk : "has many (meaning-based)"

    Script {
        Int64 id PK
        String title
        Date createdAt
        Date lastPracticedAt
    }
    
    Chunk {
        Int64 id PK
        Int64 sentenceId FK "References SENTENCE(id)"
        Int orderIndex "sentence 내 순서"
        String englishText
        String koreanText
    }

    Sentence {
        Int64 id PK
        Int64 scriptId FK "References SCRIPT(id)"
        Int orderIndex "script 내 순서"
        String englishText
        String koreanText
    }
    
    PracticeSession {
        Int64 id PK
        Int64 script_id FK "References SCRIPT(id)"
        String recording_path
        Double total_presentation_time
        Date created_at
    }

    FeedbackSummary {
        Int64 id PK
        Int64 practice_session_id FK "References PracticeSession(id)"
        Double total_score
        Int missing_word_count
        Int added_word_count
        Int replaced_word_count
        Date analyzed_at
    }

    FeedbackDetail {
        Int64 id PK
        Int64 feedback_summary_id FK "References FeedbackSummary(id)"
        String error_type
        String original_text "Nullable"
        String spoken_text "Nullable"
        Double start_time
        Double end_time
    }

    %% --- Relationships ---
    PracticeSession ||--|| FeedbackSummary : "has one"
    FeedbackSummary ||--o{ FeedbackDetail : "has many"
