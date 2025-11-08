"""
Web-specific database operations for chat sessions and user preferences.
"""

import json
import sqlite3
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class UserPreferences(BaseModel):
    """User preferences model."""

    user_id: str = "default_user"
    name: Optional[str] = None
    theme: str = "system"  # system, light, dark
    model: str = "gpt-4o"
    temperature: float = 0.7
    max_tokens: int = 1500
    onboarded: bool = False
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class ChatSession(BaseModel):
    """Chat session model."""

    id: Optional[int] = None
    user_id: str = "default_user"
    title: str
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    message_count: int = 0


class ChatMessage(BaseModel):
    """Chat message model."""

    id: Optional[int] = None
    session_id: int
    role: str  # user, assistant, system
    content: str
    timestamp: Optional[str] = None


class WebDatabase:
    """Manages web-specific database operations."""

    def __init__(self, db_path: str = "data/lifeline_web.db"):
        """
        Initialize web database connection.

        Args:
            db_path: Path to SQLite database file
        """
        self.db_path = db_path
        self._ensure_database()

    def _ensure_database(self):
        """Create database and tables if they don't exist."""
        with sqlite3.connect(self.db_path) as conn:
            # User preferences table
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS user_preferences (
                    user_id TEXT PRIMARY KEY,
                    name TEXT,
                    theme TEXT DEFAULT 'system',
                    model TEXT DEFAULT 'gpt-4o',
                    temperature REAL DEFAULT 0.7,
                    max_tokens INTEGER DEFAULT 1500,
                    onboarded BOOLEAN DEFAULT 0,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """
            )

            # Chat sessions table
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS chat_sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES user_preferences(user_id)
                )
            """
            )

            # Chat messages table
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS chat_messages (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id INTEGER NOT NULL,
                    role TEXT NOT NULL,
                    content TEXT NOT NULL,
                    timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
                )
            """
            )

            # Create indexes
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_session_user ON chat_sessions(user_id)"
            )
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_message_session ON chat_messages(session_id)"
            )
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_message_timestamp ON chat_messages(timestamp)"
            )

            conn.commit()

    # User Preferences Methods
    def get_user_preferences(self, user_id: str = "default_user") -> Optional[UserPreferences]:
        """Get user preferences."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(
                "SELECT * FROM user_preferences WHERE user_id = ?", (user_id,)
            )
            row = cursor.fetchone()
            if row:
                return UserPreferences(**dict(row))
            return None

    def create_user_preferences(self, prefs: UserPreferences) -> UserPreferences:
        """Create or update user preferences."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                """
                INSERT OR REPLACE INTO user_preferences
                (user_id, name, theme, model, temperature, max_tokens, onboarded, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    prefs.user_id,
                    prefs.name,
                    prefs.theme,
                    prefs.model,
                    prefs.temperature,
                    prefs.max_tokens,
                    prefs.onboarded,
                    datetime.now().isoformat(),
                ),
            )
            conn.commit()
        return self.get_user_preferences(prefs.user_id)

    def update_user_preferences(
        self, user_id: str = "default_user", **kwargs
    ) -> Optional[UserPreferences]:
        """Update specific user preference fields."""
        valid_fields = ["name", "theme", "model", "temperature", "max_tokens", "onboarded"]
        updates = {k: v for k, v in kwargs.items() if k in valid_fields}

        if not updates:
            return self.get_user_preferences(user_id)

        set_clause = ", ".join([f"{k} = ?" for k in updates.keys()])
        values = list(updates.values()) + [datetime.now().isoformat(), user_id]

        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                f"UPDATE user_preferences SET {set_clause}, updated_at = ? WHERE user_id = ?",
                values,
            )
            conn.commit()

        return self.get_user_preferences(user_id)

    # Chat Session Methods
    def create_session(self, user_id: str = "default_user", title: str = "New Chat") -> int:
        """Create a new chat session."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                """
                INSERT INTO chat_sessions (user_id, title)
                VALUES (?, ?)
                """,
                (user_id, title),
            )
            conn.commit()
            return cursor.lastrowid

    def get_session(self, session_id: int) -> Optional[ChatSession]:
        """Get a chat session by ID."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(
                """
                SELECT s.*, COUNT(m.id) as message_count
                FROM chat_sessions s
                LEFT JOIN chat_messages m ON s.id = m.session_id
                WHERE s.id = ?
                GROUP BY s.id
                """,
                (session_id,),
            )
            row = cursor.fetchone()
            if row:
                return ChatSession(**dict(row))
            return None

    def get_user_sessions(self, user_id: str = "default_user", limit: int = 50) -> list[ChatSession]:
        """Get all sessions for a user."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(
                """
                SELECT s.*, COUNT(m.id) as message_count
                FROM chat_sessions s
                LEFT JOIN chat_messages m ON s.id = m.session_id
                WHERE s.user_id = ?
                GROUP BY s.id
                ORDER BY s.updated_at DESC
                LIMIT ?
                """,
                (user_id, limit),
            )
            return [ChatSession(**dict(row)) for row in cursor.fetchall()]

    def update_session_title(self, session_id: int, title: str) -> bool:
        """Update session title."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "UPDATE chat_sessions SET title = ?, updated_at = ? WHERE id = ?",
                (title, datetime.now().isoformat(), session_id),
            )
            conn.commit()
            return cursor.rowcount > 0

    def delete_session(self, session_id: int) -> bool:
        """Delete a chat session and all its messages."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("DELETE FROM chat_sessions WHERE id = ?", (session_id,))
            conn.commit()
            return cursor.rowcount > 0

    # Chat Message Methods
    def add_message(self, session_id: int, role: str, content: str) -> int:
        """Add a message to a session."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                """
                INSERT INTO chat_messages (session_id, role, content)
                VALUES (?, ?, ?)
                """,
                (session_id, role, content),
            )
            # Update session timestamp
            conn.execute(
                "UPDATE chat_sessions SET updated_at = ? WHERE id = ?",
                (datetime.now().isoformat(), session_id),
            )
            conn.commit()
            return cursor.lastrowid

    def get_session_messages(self, session_id: int, limit: Optional[int] = None) -> list[ChatMessage]:
        """Get all messages for a session."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            sql = """
                SELECT * FROM chat_messages
                WHERE session_id = ?
                ORDER BY timestamp ASC
            """
            params = [session_id]

            if limit:
                sql += " LIMIT ?"
                params.append(limit)

            cursor = conn.execute(sql, params)
            return [ChatMessage(**dict(row)) for row in cursor.fetchall()]

    def clear_session_messages(self, session_id: int) -> int:
        """Clear all messages in a session."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("DELETE FROM chat_messages WHERE session_id = ?", (session_id,))
            conn.commit()
            return cursor.rowcount

    # Statistics
    def get_total_sessions(self, user_id: str = "default_user") -> int:
        """Get total number of sessions."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "SELECT COUNT(*) FROM chat_sessions WHERE user_id = ?", (user_id,)
            )
            return cursor.fetchone()[0]

    def get_total_messages(self, user_id: str = "default_user") -> int:
        """Get total number of messages."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                """
                SELECT COUNT(m.id)
                FROM chat_messages m
                JOIN chat_sessions s ON m.session_id = s.id
                WHERE s.user_id = ?
                """,
                (user_id,),
            )
            return cursor.fetchone()[0]
