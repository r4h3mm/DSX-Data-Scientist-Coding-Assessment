# Question 5: FastAPI Clinical Data API

## Overview
REST API built with FastAPI to query adverse event data from clinical trials.

## Features
- **GET /**: API information and available endpoints
- **GET /adverse-events**: Query adverse events with optional filters (usubjid, aeterm, aesev, actarm, limit)
- **GET /adverse-events/{usubjid}**: Get all adverse events for a specific subject
- **GET /summary**: Summary statistics grouped by severity, SOC, or treatment arm

## Installation

```bash
pip install -r requirements.txt
```

## Running the API

```bash
python3 main.py
```

The API will be available at `http://localhost:8000`

## Interactive Documentation

Visit `http://localhost:8000/docs` for auto-generated interactive API documentation.

## Example Queries

- Get 10 adverse events: `http://localhost:8000/adverse-events?limit=10`
- Filter by severity: `http://localhost:8000/adverse-events?aesev=SEVERE`
- Summary by treatment: `http://localhost:8000/summary?group_by=ACTARM`