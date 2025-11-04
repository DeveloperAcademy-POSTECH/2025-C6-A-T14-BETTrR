erDiagram
    Script ||--o{ Sentence : "has many (sentence-based)"
    Script ||--o{ FeedbackSummary : "has many"
    Sentence ||--o{ Chunk : "has many (meaning-based)"
    FeedbackSummary ||--o{ FeedbackDetail : "has many"

    Script {
        Int64 id PK
        String title
        Date createdAt
        Date lastViewedAt
    }
    
    Chunk {
        Int64 id PK
        Int64 sentenceId FK "References Sentence(id)"
        Int orderIndex "sentence 내 순서"
        String englishText
        String koreanText
    }

    Sentence {
        Int64 id PK
        Int64 scriptId FK "References Script(id)"
        Int orderIndex "script 내 순서"
        String englishText
        String koreanText
    }

    FeedbackSummary {
        Int64 id PK
        Int64 scriptId FK "References Script(id)"
        Double totalScore
        Int missingWordCount
        Int addedWordCount
        Int replacedWordCount
        Double practiceDuration
        Date createdAt
    }

    FeedbackDetail {
        Int64 id PK
        Int64 feedbackSummaryId FK "References FeedbackSummary(id)"
        String errorType
        String originalText "Nullable"
        String spokenText "Nullable"
        Double startTime
        Double endTime
    }