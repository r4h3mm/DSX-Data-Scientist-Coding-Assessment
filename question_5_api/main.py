"""
Question 5: FastAPI Clinical Data API

Objective: Create a REST API to query adverse event data from ADAE dataset
Endpoints:
    - GET /: Root endpoint with API info
    - GET /adverse-events: Get all adverse events with optional filters
    - GET /adverse-events/{usubjid}: Get adverse events for a specific subject
    - GET /summary: Get summary statistics of adverse events
"""

from fastapi import FastAPI, Query, HTTPException
from typing import Optional, List
import pandas as pd
from pathlib import Path

# Initialize FastAPI app
app = FastAPI(
    title="Clinical Trial Adverse Events API",
    description="API for querying adverse event data from clinical trials",
    version="1.0.0"
)

# Load ADAE dataset
DATA_PATH = Path(__file__).parent / "adae.csv"
try:
    adae_df = pd.read_csv(DATA_PATH)
    print(f"Loaded {len(adae_df)} adverse event records")
except FileNotFoundError:
    raise RuntimeError(f"Data file not found: {DATA_PATH}")


@app.get("/")
def root():
    """Root endpoint - API information"""
    return {
        "message": "Clinical Trial Adverse Events API",
        "version": "1.0.0",
        "total_records": len(adae_df),
        "endpoints": {
            "/adverse-events": "Get all adverse events (supports filtering)",
            "/adverse-events/{usubjid}": "Get adverse events for a specific subject",
            "/summary": "Get summary statistics"
        }
    }


@app.get("/adverse-events")
def get_adverse_events(
    usubjid: Optional[str] = Query(None, description="Filter by subject ID"),
    aeterm: Optional[str] = Query(None, description="Filter by adverse event term"),
    aesev: Optional[str] = Query(None, description="Filter by severity (MILD/MODERATE/SEVERE)"),
    actarm: Optional[str] = Query(None, description="Filter by treatment arm"),
    limit: int = Query(100, description="Maximum number of records to return", le=1000)
):
    """
    Get adverse events with optional filtering
    
    Query Parameters:
        - usubjid: Filter by subject ID
        - aeterm: Filter by adverse event term (partial match)
        - aesev: Filter by severity
        - actarm: Filter by treatment arm
        - limit: Maximum number of records (default: 100, max: 1000)
    """
    df = adae_df.copy()
    
    # Apply filters
    if usubjid:
        df = df[df['USUBJID'] == usubjid]
    
    if aeterm:
        df = df[df['AETERM'].str.contains(aeterm, case=False, na=False)]
    
    if aesev:
        df = df[df['AESEV'] == aesev.upper()]
    
    if actarm:
        df = df[df['ACTARM'].str.contains(actarm, case=False, na=False)]
    
    # Limit results
    df = df.head(limit)
    
    # Select key columns for response
    columns_to_return = [
        'USUBJID', 'AETERM', 'AESEV', 'AESOC', 'AEREL',
        'AESTDTC', 'AEENDTC', 'ACTARM', 'TRTEMFL'
    ]
    
    # Filter to only include columns that exist
    columns_to_return = [col for col in columns_to_return if col in df.columns]
    
    result_df = df[columns_to_return]
    
    return {
        "count": len(result_df),
        "data": result_df.to_dict(orient="records")
    }


@app.get("/adverse-events/{usubjid}")
def get_adverse_events_by_subject(usubjid: str):
    """
    Get all adverse events for a specific subject
    
    Path Parameters:
        - usubjid: Subject ID (e.g., "01-701-1015")
    """
    subject_aes = adae_df[adae_df['USUBJID'] == usubjid]
    
    if len(subject_aes) == 0:
        raise HTTPException(
            status_code=404,
            detail=f"No adverse events found for subject {usubjid}"
        )
    
    # Select key columns
    columns_to_return = [
        'USUBJID', 'AETERM', 'AESEV', 'AESOC', 'AEREL',
        'AESTDTC', 'AEENDTC', 'AESEQ'
    ]
    columns_to_return = [col for col in columns_to_return if col in subject_aes.columns]
    
    return {
        "usubjid": usubjid,
        "total_adverse_events": len(subject_aes),
        "data": subject_aes[columns_to_return].to_dict(orient="records")
    }


@app.get("/summary")
def get_summary(
    group_by: str = Query("AESEV", description="Group by field (AESEV, AESOC, ACTARM)")
):
    """
    Get summary statistics of adverse events
    
    Query Parameters:
        - group_by: Field to group by (AESEV, AESOC, or ACTARM)
    """
    valid_groups = ["AESEV", "AESOC", "ACTARM"]
    
    if group_by not in valid_groups:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid group_by parameter. Must be one of: {valid_groups}"
        )
    
    # Count by group
    summary = adae_df[group_by].value_counts().to_dict()
    
    # Calculate percentages
    total = len(adae_df)
    summary_with_pct = {
        key: {
            "count": count,
            "percentage": round((count / total) * 100, 2)
        }
        for key, count in summary.items()
    }
    
    return {
        "total_records": total,
        "grouped_by": group_by,
        "summary": summary_with_pct
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
