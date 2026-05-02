# Question 6: GenAI Clinical Data Assistant

## Overview
AI-powered conversational assistant built with LangChain that allows natural language querying of clinical trial adverse event data.

## Architecture

### Retrieval-Augmented Generation (RAG)
- Converts ADAE clinical data into vector embeddings
- Stores embeddings in ChromaDB vector database
- Retrieves relevant context for each query
- Generates accurate responses using GPT-4

### Key Components
- **LangChain**: LLM orchestration framework
- **OpenAI GPT-4**: Language model for response generation
- **ChromaDB**: Vector database for semantic search
- **ConversationalRetrievalChain**: Context-aware Q&A with memory

## Features
- Natural language queries about adverse events
- Conversation memory (follow-up questions work)
- Source citation from clinical dataset
- Context-aware responses based on retrieved data

## Setup

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure API Key
Create a `.env` file with your OpenAI API key:

**Note:** API key not included in repository for security. Requires OpenAI API access (separate from ChatGPT subscription).

### 3. Run the Assistant
```bash
python3 clinical_assistant.py
```

## Example Queries

- "How many severe adverse events were reported?"
- "What are the most common adverse events in the Placebo group?"
- "Show me all cardiac adverse events"
- "What percentage of adverse events were treatment emergent?"
- "Compare adverse events between Xanomeline and Placebo"

## Technical Implementation

### Data Processing Pipeline
1. Load ADAE dataset from CSV
2. Convert each adverse event to narrative text
3. Split text into chunks (500 chars, 50 char overlap)
4. Generate embeddings using OpenAI's text-embedding-ada-002
5. Store in ChromaDB vector database

### Query Processing
1. User asks question in natural language
2. Question converted to embedding
3. Top 5 most similar AE records retrieved via semantic search
4. Retrieved context + question sent to GPT-4
5. GPT-4 generates response with source citations
6. Conversation history maintained for follow-up questions

## Requirements
- OpenAI API key (paid tier recommended for production use)
- Python 3.8+
- ~1GB disk space for vector database

## Security Note
The `.env` file containing API keys is excluded from version control via `.gitignore` and should never be committed to repositories.
