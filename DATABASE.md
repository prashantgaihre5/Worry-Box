# Database Schema (LocalStorage)

Since Worry Box does not use a traditional relational or NoSQL database, this document outlines the JSON schema used within the browser's `localStorage`.

## Key: `worryBox_data`
Stores the main application state and the array of worries.

```json
{
  "unlockTime": "2026-08-04T18:00:00.000Z",
  "worries": [
    {
      "id": "1691173829102-abc",
      "text": "What if I fail the presentation?",
      "createdAt": "2026-08-04T14:30:29.102Z",
      "status": "locked" // "locked", "released", "archived"
    }
  ],
  "history": []
}
```

## Schema Details
- `unlockTime`: An ISO 8601 string representing when the box opens.
- `worries`: An array of worry objects.
  - `id`: A unique identifier (timestamp + random string).
  - `text`: The user's input string.
  - `createdAt`: Timestamp of creation.
  - `status`: Tracks the lifecycle of the worry.
