"""
Question 6: GenAI Clinical Data Assistant using LangChain
==========================================================
Objective: Create an AI-powered assistant that can answer questions about
           clinical trial adverse event data using natural language.

Architecture:
    - LangChain for LLM orchestration
    - OpenAI GPT-4 as the language model
    - ChromaDB for vector storage (RAG pattern)
    - Conversational retrieval chain for context-aware responses

Features:
    - Natural language queries about adverse events
    - Context-aware conversations with memory
    - Retrieval-Augmented Generation (RAG) for accuracy
    - Source citation from the clinical dataset
"""

import os
import pandas as pd
from pathlib import Path
from typing import List, Dict
from dotenv import load_dotenv

# LangChain imports
from langchain.vectorstores import Chroma
from langchain.embeddings import OpenAIEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chat_models import ChatOpenAI
from langchain.chains import ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory
from langchain.schema import Document

# Load environment variables
load_dotenv()

class ClinicalDataAssistant:
    """
    AI Assistant for querying clinical trial adverse event data.
    
    Uses LangChain's RAG (Retrieval-Augmented Generation) pattern to:
    1. Convert clinical data into embeddings
    2. Store embeddings in a vector database (ChromaDB)
    3. Retrieve relevant context for user queries
    4. Generate accurate, source-cited responses using GPT-4
    """
    
    def __init__(self, data_path: str = "../question_5_api/adae.csv"):
        """
        Initialize the clinical data assistant.
        
        Args:
            data_path: Path to the ADAE CSV file
        """
        self.data_path = Path(__file__).parent / data_path
        self.vectorstore = None
        self.qa_chain = None
        self.chat_history = []
        
        # Validate API key
        if not os.getenv("OPENAI_API_KEY"):
            raise ValueError(
                "OPENAI_API_KEY not found. Please set it in .env file.\n"
                "Example: OPENAI_API_KEY=sk-..."
            )
        
        print("Initializing Clinical Data Assistant...")
        self._load_and_process_data()
        self._setup_qa_chain()
        print("Assistant ready!")
    
    def _load_and_process_data(self):
        """
        Load ADAE data and convert to vector embeddings for RAG.
        
        Steps:
        1. Load CSV data
        2. Convert each adverse event record to text
        3. Split text into chunks
        4. Generate embeddings using OpenAI
        5. Store in ChromaDB vector database
        """
        print("Loading adverse event data...")
        
        # Load ADAE dataset
        if not self.data_path.exists():
            raise FileNotFoundError(f"Data file not found: {self.data_path}")
        
        df = pd.read_csv(self.data_path)
        print(f"Loaded {len(df)} adverse event records")
        
        # Convert each AE record to a text document
        documents = []
        for idx, row in df.iterrows():
            # Create a narrative description of each adverse event
            text = f"""
            Subject: {row.get('USUBJID', 'Unknown')}
            Adverse Event: {row.get('AETERM', 'Unknown')}
            Severity: {row.get('AESEV', 'Unknown')}
            System Organ Class: {row.get('AESOC', 'Unknown')}
            Relationship to Drug: {row.get('AEREL', 'Unknown')}
            Treatment Arm: {row.get('ACTARM', 'Unknown')}
            Start Date: {row.get('AESTDTC', 'Unknown')}
            End Date: {row.get('AEENDTC', 'Unknown')}
            Treatment Emergent: {row.get('TRTEMFL', 'Unknown')}
            """
            
            # Create LangChain Document with metadata
            doc = Document(
                page_content=text.strip(),
                metadata={
                    "usubjid": str(row.get('USUBJID', '')),
                    "aeterm": str(row.get('AETERM', '')),
                    "aesev": str(row.get('AESEV', '')),
                    "actarm": str(row.get('ACTARM', ''))
                }
            )
            documents.append(doc)
        
        print(f"Created {len(documents)} text documents")
        
        # Split documents into chunks for better retrieval
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=500,
            chunk_overlap=50
        )
        splits = text_splitter.split_documents(documents)
        print(f"Split into {len(splits)} chunks")
        
        # Create embeddings and vector store
        print("Generating embeddings (this may take a moment)...")
        embeddings = OpenAIEmbeddings()
        
        self.vectorstore = Chroma.from_documents(
            documents=splits,
            embedding=embeddings,
            persist_directory="./chroma_db"
        )
        print("Vector database created")
    
    def _setup_qa_chain(self):
        """
        Set up the conversational QA chain with memory.
        
        Components:
        - ChatOpenAI: GPT-4 language model
        - ConversationBufferMemory: Maintains conversation history
        - ConversationalRetrievalChain: Combines retrieval + generation
        """
        # Initialize GPT-4 model
        llm = ChatOpenAI(
            model_name="gpt-4",
            temperature=0,  # Deterministic for clinical data
            max_tokens=500
        )
        
        # Set up conversation memory
        memory = ConversationBufferMemory(
            memory_key="chat_history",
            return_messages=True,
            output_key="answer"
        )
        
        # Create conversational retrieval chain
        self.qa_chain = ConversationalRetrievalChain.from_llm(
            llm=llm,
            retriever=self.vectorstore.as_retriever(
                search_kwargs={"k": 5}  # Retrieve top 5 relevant chunks
            ),
            memory=memory,
            return_source_documents=True,
            verbose=True
        )
    
    def ask(self, question: str) -> Dict[str, any]:
        """
        Ask a question about the clinical data.
        
        Args:
            question: Natural language question
            
        Returns:
            Dictionary containing:
                - answer: The AI-generated response
                - sources: List of source documents used
        """
        if not self.qa_chain:
            raise RuntimeError("QA chain not initialized")
        
        # Get response from the chain
        result = self.qa_chain({"question": question})
        
        # Extract answer and sources
        response = {
            "answer": result["answer"],
            "sources": [
                {
                    "content": doc.page_content[:200] + "...",
                    "metadata": doc.metadata
                }
                for doc in result.get("source_documents", [])
            ]
        }
        
        return response
    
    def chat(self):
        """
        Interactive chat interface for the assistant.
        """
        print("\n" + "="*60)
        print("Clinical Trial Data Assistant")
        print("="*60)
        print("Ask questions about adverse events in natural language.")
        print("Type 'quit' or 'exit' to end the conversation.\n")
        
        while True:
            # Get user input
            user_input = input("You: ").strip()
            
            # Check for exit
            if user_input.lower() in ['quit', 'exit', 'q']:
                print("\nGoodbye!")
                break
            
            if not user_input:
                continue
            
            # Get response
            try:
                result = self.ask(user_input)
                print(f"\nAssistant: {result['answer']}\n")
                
                # Optionally show sources
                if result['sources']:
                    print(f"(Based on {len(result['sources'])} source documents)")
                
            except Exception as e:
                print(f"\nError: {str(e)}\n")


def main():
    """
    Main function to run the clinical data assistant.
    
    Example queries to try:
    - "How many severe adverse events were reported?"
    - "What are the most common adverse events in the Placebo group?"
    - "Show me cardiac adverse events"
    - "What percentage of AEs were treatment emergent?"
    """
    try:
        # Initialize assistant
        assistant = ClinicalDataAssistant()
        
        # Start interactive chat
        assistant.chat()
        
    except FileNotFoundError as e:
        print(f"\nError: {e}")
        print("Make sure you've completed Question 5 and the adae.csv file exists.")
    except ValueError as e:
        print(f"\nError: {e}")
        print("\nTo run this assistant:")
        print("1. Create a .env file in this directory")
        print("2. Add your OpenAI API key: OPENAI_API_KEY=sk-...")
        print("3. Run the script again")
    except Exception as e:
        print(f"\nUnexpected error: {e}")


if __name__ == "__main__":
    main()
