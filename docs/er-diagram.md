# Whisperia — ER Diagram & Database Design

## Entity Relationship Diagram

```mermaid
erDiagram
    USERS {
        NUMBER UserID PK
        VARCHAR2 Username UK
        VARCHAR2 Email UK
        VARCHAR2 PasswordHash
        VARCHAR2 Role
        DATE JoinDate
    }

    CATEGORIES {
        NUMBER CategoryID PK
        VARCHAR2 CategoryName UK
    }

    QUESTIONS {
        NUMBER QuestionID PK
        NUMBER UserID FK
        NUMBER CategoryID FK
        VARCHAR2 Title
        CLOB Description
        DATE CreatedAt
    }

    ANSWERS {
        NUMBER AnswerID PK
        NUMBER QuestionID FK
        NUMBER UserID FK
        CLOB AnswerText
        DATE CreatedAt
    }

    TAGS {
        NUMBER TagID PK
        VARCHAR2 TagName UK
    }

    QUESTIONTAGS {
        NUMBER QuestionID FK
        NUMBER TagID FK
    }

    VOTES {
        NUMBER VoteID PK
        NUMBER UserID FK
        NUMBER AnswerID FK
        VARCHAR2 VoteType
        DATE CreatedAt
    }

    BOOKMARKS {
        NUMBER BookmarkID PK
        NUMBER UserID FK
        NUMBER QuestionID FK
        DATE CreatedAt
    }

    NOTIFICATIONS {
        NUMBER NotificationID PK
        NUMBER UserID FK
        VARCHAR2 Message
        NUMBER IsRead
        DATE CreatedAt
    }

    REPORTS {
        NUMBER ReportID PK
        NUMBER UserID FK
        NUMBER QuestionID FK_nullable
        NUMBER AnswerID FK_nullable
        VARCHAR2 Reason
        VARCHAR2 Status
        DATE CreatedAt
    }

    USERS ||--o{ QUESTIONS : "asks"
    USERS ||--o{ ANSWERS : "posts"
    USERS ||--o{ VOTES : "casts"
    USERS ||--o{ BOOKMARKS : "saves"
    USERS ||--o{ NOTIFICATIONS : "receives"
    USERS ||--o{ REPORTS : "submits"
    CATEGORIES ||--o{ QUESTIONS : "contains"
    QUESTIONS ||--o{ ANSWERS : "has"
    QUESTIONS ||--o{ QUESTIONTAGS : "tagged_with"
    QUESTIONS ||--o{ BOOKMARKS : "bookmarked_by"
    TAGS ||--o{ QUESTIONTAGS : "applied_to"
    ANSWERS ||--o{ VOTES : "receives"
    QUESTIONS ||--o{ REPORTS : "reported_as"
    ANSWERS ||--o{ REPORTS : "reported_as"
```

## Relationships

| Relationship | Type | Description |
|-------------|------|-------------|
| Users → Questions | 1:N | One user can ask many questions |
| Users → Answers | 1:N | One user can post many answers |
| Users → Votes | 1:N | One user can cast many votes |
| Users → Bookmarks | 1:N | One user can save many bookmarks |
| Users → Notifications | 1:N | One user receives many notifications |
| Users → Reports | 1:N | One user can submit many reports |
| Categories → Questions | 1:N | One category contains many questions |
| Questions → Answers | 1:N | One question has many answers |
| Questions ↔ Tags | M:N | Many-to-many via QuestionTags junction table |
| Answers → Votes | 1:N | One answer receives many votes |

## Normalization (3NF Proof)

### First Normal Form (1NF)
- All columns contain atomic values (no repeating groups)
- Each table has a primary key
- Tags are stored in a separate table rather than as a comma-separated list

### Second Normal Form (2NF)
- All non-key attributes are fully functionally dependent on the entire primary key
- QuestionTags composite key `(QuestionID, TagID)` — no partial dependencies

### Third Normal Form (3NF)
- No transitive dependencies exist
- CategoryName depends only on CategoryID (not stored in Questions)
- Username depends only on UserID (not duplicated in Questions/Answers)
- TagName depends only on TagID (not stored in QuestionTags)

## Candidate Keys

| Table | Candidate Keys |
|-------|---------------|
| Users | UserID (PK), Username, Email |
| Categories | CategoryID (PK), CategoryName |
| Tags | TagID (PK), TagName |
| Votes | VoteID (PK), (UserID, AnswerID) |
| Bookmarks | BookmarkID (PK), (UserID, QuestionID) |
