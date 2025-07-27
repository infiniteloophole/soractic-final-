# Core Backend Architecture

## Overview
This document defines the complete backend architecture for a token-gated study platform combining AI-powered document analysis, real-time chat, blockchain integration, and decentralized storage.

## Technology Stack

### Core Backend
- **Runtime**: Python 3.11+ with FastAPI
- **Database**: PostgreSQL with pgvector extension
- **Caching**: Redis Cluster
- **Queue**: Celery with Redis broker
- **WebSocket**: FastAPI WebSockets with Redis PubSub

### AI & ML
- **Embeddings**: Sentence Transformers (384-dim vectors)
- **LLM**: OpenAI GPT-4 / Claude (configurable)
- **Vector Search**: pgvector with HNSW indexing
- **Document Processing**: PyMuPDF, pandas, LangChain

### Blockchain & Storage
- **Blockchain**: Solana (SPL tokens, NFTs, program interactions)
- **Decentralized Storage**: Arweave primary, IPFS fallback
- **Wallet Auth**: Solana Sign-In-With-Solana (SIWS)

### External Services
- **Push Notifications**: Firebase Cloud Messaging (FCM), Apple Push Notification Service (APNs)
- **Monitoring**: Prometheus + Grafana
- **Logging**: Structured logging with ELK stack

## Database Schema Design

### Extended Core Models

#### Users Table (Extended)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    name TEXT,
    username TEXT UNIQUE,
    auth_provider TEXT,
    wallet_address TEXT UNIQUE, -- Solana wallet address
    wallet_verified BOOLEAN DEFAULT FALSE,
    reputation_score INTEGER DEFAULT 0,
    total_xp INTEGER DEFAULT 0,
    level_id UUID REFERENCES user_levels(id),
    profile_nft_mint TEXT, -- Profile picture NFT mint address
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP
);
```

#### Study Rooms
```sql
CREATE TABLE study_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    creator_id UUID REFERENCES users(id) ON DELETE SET NULL,
    room_type VARCHAR(20) CHECK (room_type IN ('public', 'token_gated', 'nft_gated', 'private')),
    access_token_mint TEXT, -- SPL token mint address for gating
    access_nft_collection TEXT, -- NFT collection address for gating
    min_token_amount BIGINT DEFAULT 0,
    max_participants INTEGER DEFAULT 50,
    is_active BOOLEAN DEFAULT TRUE,
    room_nft_mint TEXT, -- Minted NFT for this room
    arweave_metadata_tx TEXT, -- Room metadata on Arweave
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_study_rooms_type ON study_rooms(room_type);
CREATE INDEX idx_study_rooms_creator ON study_rooms(creator_id);
```

#### Room Participants
```sql
CREATE TABLE room_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES study_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('owner', 'moderator', 'member')),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_banned BOOLEAN DEFAULT FALSE,
    UNIQUE(room_id, user_id)
);

CREATE INDEX idx_room_participants_room ON room_participants(room_id);
CREATE INDEX idx_room_participants_user ON room_participants(user_id);
```

#### Chat Messages (Extended)
```sql
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES study_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'document_share', 'highlight', 'system')),
    content TEXT NOT NULL,
    reply_to_id UUID REFERENCES chat_messages(id),
    document_id UUID REFERENCES pdf_uploads(id), -- For document-related messages
    highlight_data JSONB, -- For highlighted text with context
    nft_mint TEXT, -- If message was minted as NFT
    arweave_tx TEXT, -- Arweave transaction ID for NFT metadata
    reactions JSONB DEFAULT '{}', -- User reactions {user_id: emoji}
    is_pinned BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_messages_room ON chat_messages(room_id, created_at DESC);
CREATE INDEX idx_chat_messages_user ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_document ON chat_messages(document_id);
```

#### Achievements & Reputation
```sql
CREATE TABLE user_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level INTEGER UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    min_xp INTEGER NOT NULL,
    max_xp INTEGER,
    badge_image_url TEXT,
    perks JSONB DEFAULT '[]'
);

CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    xp_reward INTEGER DEFAULT 0,
    badge_image_url TEXT,
    nft_collection TEXT, -- Soulbound NFT collection
    requirements JSONB, -- Achievement unlock conditions
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nft_mint TEXT, -- Soulbound NFT mint address
    transaction_signature TEXT,
    UNIQUE(user_id, achievement_id)
);
```

#### NFT Highlights
```sql
CREATE TABLE nft_highlights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE,
    document_id UUID REFERENCES pdf_uploads(id),
    highlight_text TEXT NOT NULL,
    context_before TEXT,
    context_after TEXT,
    page_number INTEGER,
    coordinates JSONB, -- Highlight position data
    nft_mint TEXT UNIQUE NOT NULL,
    arweave_metadata_tx TEXT,
    ipfs_backup_hash TEXT,
    mint_transaction_signature TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_nft_highlights_user ON nft_highlights(user_id);
CREATE INDEX idx_nft_highlights_document ON nft_highlights(document_id);
```

#### Document Library (Extended)
```sql
-- Extend existing pdf_uploads table
ALTER TABLE pdf_uploads ADD COLUMN IF NOT EXISTS arweave_tx TEXT;
ALTER TABLE pdf_uploads ADD COLUMN IF NOT EXISTS ipfs_hash TEXT;
ALTER TABLE pdf_uploads ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;
ALTER TABLE pdf_uploads ADD COLUMN IF NOT EXISTS tags JSONB DEFAULT '[]';
ALTER TABLE pdf_uploads ADD COLUMN IF NOT EXISTS download_count INTEGER DEFAULT 0;
ALTER TABLE pdf_uploads ADD COLUMN IF NOT EXISTS file_size_bytes BIGINT;
ALTER TABLE pdf_uploads ADD COLUMN IF NOT EXISTS mime_type VARCHAR(100);

CREATE TABLE document_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES pdf_uploads(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    room_id UUID REFERENCES study_rooms(id) ON DELETE CASCADE,
    permission_type VARCHAR(20) CHECK (permission_type IN ('read', 'write', 'admin')),
    granted_by UUID REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    UNIQUE(document_id, user_id, room_id)
);
```

#### Push Notifications
```sql
CREATE TABLE notification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) CHECK (platform IN ('web', 'ios', 'android')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, token)
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50),
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC);
```

## API Architecture

### Core API Structure
```
/api/v1/
├── auth/
│   ├── wallet/connect
│   ├── wallet/verify
│   ├── wallet/disconnect
│   └── siws/challenge
├── users/
│   ├── profile
│   ├── achievements
│   ├── reputation
│   └── leaderboard
├── rooms/
│   ├── create
│   ├── join
│   ├── leave
│   ├── list
│   └── {room_id}/
│       ├── messages
│       ├── participants
│       └── documents
├── documents/
│   ├── upload
│   ├── library
│   ├── share
│   └── {doc_id}/
│       ├── chat
│       ├── highlights
│       └── permissions
├── nft/
│   ├── mint-highlight
│   ├── mint-room
│   └── collections
├── notifications/
│   ├── register-token
│   ├── list
│   └── mark-read
└── websocket/
    └── rooms/{room_id}
```

## WebSocket Architecture

### Connection Management
- **Endpoint**: `/ws/rooms/{room_id}`
- **Authentication**: JWT token or wallet signature
- **Authorization**: Room access validation (token/NFT gating)

### Message Types
```python
# Incoming message types
class WSMessageType(Enum):
    CHAT_MESSAGE = "chat_message"
    TYPING_START = "typing_start"
    TYPING_STOP = "typing_stop"
    DOCUMENT_SHARE = "document_share"
    HIGHLIGHT_CREATE = "highlight_create"
    REACTION_ADD = "reaction_add"
    SOCRATIC_QUERY = "socratic_query"

# Outgoing message types
class WSBroadcastType(Enum):
    NEW_MESSAGE = "new_message"
    USER_JOINED = "user_joined"
    USER_LEFT = "user_left"
    TYPING_STATUS = "typing_status"
    DOCUMENT_SHARED = "document_shared"
    HIGHLIGHT_CREATED = "highlight_created"
    ACHIEVEMENT_EARNED = "achievement_earned"
    SOCRATIC_RESPONSE = "socratic_response"
```

### Redis PubSub Channels
- `room:{room_id}:messages` - Chat messages
- `room:{room_id}:presence` - User presence updates
- `room:{room_id}:documents` - Document sharing events
- `global:notifications` - System-wide notifications

## AI Integration Architecture

### RAG Pipeline
1. **Document Processing**
   - PDF/CSV parsing and chunking
   - Embedding generation (384-dim vectors)
   - Storage in pgvector with metadata

2. **Query Processing**
   - Query embedding generation
   - Vector similarity search
   - Context retrieval and ranking

3. **Response Generation**
   - Multi-turn conversation memory
   - Source attribution
   - Socratic questioning integration

### Socratic AI Assistant
- **Context Awareness**: Room-specific document context
- **Follow-up Questions**: Generated based on conversation flow
- **Learning Style Adaptation**: User behavior analysis
- **Progress Tracking**: Knowledge gap identification

## Blockchain Integration

### Solana Program Integration
- **Token Verification**: SPL token balance checks for room access
- **NFT Verification**: Collection ownership validation
- **Message Minting**: Highlight NFT creation with Arweave metadata
- **Achievement NFTs**: Soulbound token minting for accomplishments

### Transaction Flow
1. **Room Access**: Verify token/NFT holdings
2. **Highlight Minting**: Create NFT with Arweave metadata
3. **Achievement Unlocking**: Mint soulbound NFT
4. **Reputation Updates**: On-chain reputation tracking

## Storage Architecture

### Arweave Integration
- **Primary Storage**: Documents, NFT metadata, room configurations
- **Permanent Storage**: Guaranteed data persistence
- **GraphQL Queries**: Efficient data retrieval

### IPFS Fallback
- **Redundancy**: Backup for Arweave data
- **Faster Access**: Lower latency for frequently accessed content
- **Gateway Integration**: Multiple IPFS gateways

## Caching Strategy

### Redis Cluster Setup
- **Session Storage**: User sessions and WebSocket connections
- **Cache Layers**: Document embeddings, user permissions
- **PubSub**: Real-time message broadcasting
- **Rate Limiting**: API endpoint protection

### Cache Invalidation
- **Document Updates**: Clear related embeddings and permissions
- **Room Changes**: Invalidate participant lists and access tokens
- **User Updates**: Refresh profile and achievement caches

## Security Architecture

### Authentication & Authorization
- **Multi-layer Auth**: Traditional JWT + Wallet signatures
- **SIWS Integration**: Solana wallet authentication
- **Permission Matrix**: Role-based access control
- **Rate Limiting**: Per-user and per-endpoint limits

### Data Protection
- **Encryption**: At-rest and in-transit encryption
- **Sensitive Data**: Wallet private keys never stored
- **Audit Logging**: All critical operations logged
- **GDPR Compliance**: Data deletion and export capabilities

## Monitoring & Observability

### Metrics Collection
- **Performance**: API response times, WebSocket latency
- **Business**: Room activity, document uploads, NFT mints
- **System**: Database connections, Redis cluster health
- **Blockchain**: Transaction success rates, token balances

### Alerting
- **Critical**: Database failures, WebSocket disconnections
- **Warning**: High response times, cache misses
- **Info**: Achievement unlocks, room milestones

This architecture provides a scalable, secure foundation for your token-gated study platform with comprehensive AI, blockchain, and real-time communication capabilities.
