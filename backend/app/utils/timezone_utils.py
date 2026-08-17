"""
Timezone utilities for converting UTC timestamps to IST (Indian Standard Time).

All timestamps in the database are stored in UTC.
This module provides utilities to convert them to IST for display purposes.
"""
from datetime import datetime, timedelta, timezone
import logging

logger = logging.getLogger(__name__)

# IST timezone (UTC+05:30)
IST = timezone(timedelta(hours=5, minutes=30))


def convert_to_ist(dt: datetime) -> datetime:
    """
    Convert a datetime object to IST.
    
    Args:
        dt: Datetime object (can be timezone-aware or naive UTC)
        
    Returns:
        Datetime object in IST timezone
    """
    if dt is None:
        return None
    
    try:
        # If the datetime is naive, assume it's UTC
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        
        # Convert to IST
        return dt.astimezone(IST)
    except Exception as e:
        logger.error(f"Error converting datetime to IST: {e}")
        return dt


def datetime_to_ist_isoformat(dt: datetime) -> str:
    """
    Convert a datetime to IST and return as ISO format string.
    
    Args:
        dt: Datetime object (can be timezone-aware or naive UTC)
        
    Returns:
        ISO format string in IST timezone, or None if dt is None
    """
    if dt is None:
        return None
    
    try:
        ist_dt = convert_to_ist(dt)
        # Return ISO format with timezone info
        return ist_dt.isoformat()
    except Exception as e:
        logger.error(f"Error converting datetime to IST isoformat: {e}")
        if dt.tzinfo is None:
            return dt.replace(tzinfo=timezone.utc).isoformat()
        return dt.isoformat()


def datetime_to_ist_display_format(dt: datetime) -> str:
    """
    Convert a datetime to IST and return in readable display format: DD/MM/YYYY HH:mm:ss
    
    Args:
        dt: Datetime object (can be timezone-aware or naive UTC)
        
    Returns:
        Formatted string like "17/08/2024 20:12:18", or empty string if dt is None
    """
    if dt is None:
        return ""
    
    try:
        ist_dt = convert_to_ist(dt)
        # Format as DD/MM/YYYY HH:mm:ss
        return ist_dt.strftime("%d/%m/%Y %H:%M:%S")
    except Exception as e:
        logger.error(f"Error formatting datetime for display: {e}")
        return ""


def datetime_to_ist_date_only(dt: datetime) -> str:
    """
    Convert a datetime to IST and return only the date: DD/MM/YYYY
    
    Args:
        dt: Datetime object (can be timezone-aware or naive UTC)
        
    Returns:
        Formatted string like "17/08/2024", or empty string if dt is None
    """
    if dt is None:
        return ""
    
    try:
        ist_dt = convert_to_ist(dt)
        return ist_dt.strftime("%d/%m/%Y")
    except Exception as e:
        logger.error(f"Error formatting date: {e}")
        return ""


def datetime_to_ist_time_only(dt: datetime) -> str:
    """
    Convert a datetime to IST and return only the time: HH:mm:ss
    
    Args:
        dt: Datetime object (can be timezone-aware or naive UTC)
        
    Returns:
        Formatted string like "20:12:18", or empty string if dt is None
    """
    if dt is None:
        return ""
    
    try:
        ist_dt = convert_to_ist(dt)
        return ist_dt.strftime("%H:%M:%S")
    except Exception as e:
        logger.error(f"Error formatting time: {e}")
        return ""


def convert_dict_timestamps_to_ist(data: dict, timestamp_fields: list = None) -> dict:
    """
    Convert specified timestamp fields in a dictionary to IST.
    
    Args:
        data: Dictionary containing data
        timestamp_fields: List of field names that contain datetime objects.
                         If None, converts all DateTime fields.
        
    Returns:
        Dictionary with converted timestamps
    """
    if data is None:
        return None
    
    try:
        result = data.copy()
        
        # If no fields specified, find all datetime-like fields
        if timestamp_fields is None:
            timestamp_fields = [
                'created_at', 'updated_at', 'timestamp',
                'login_time', 'logout_time',
                'started_at', 'paused_at', 'resumed_at', 'stopped_at', 'completed_at',
                'password_changed_at', 'last_login', 'last_activity',
                'action_time'
            ]
        
        for field in timestamp_fields:
            if field in result and result[field] is not None:
                dt = result[field]
                
                # Handle datetime objects
                if isinstance(dt, datetime):
                    result[field] = datetime_to_ist_isoformat(dt)
                # Handle ISO format strings
                elif isinstance(dt, str):
                    try:
                        dt_obj = datetime.fromisoformat(dt.replace('Z', '+00:00'))
                        result[field] = datetime_to_ist_isoformat(dt_obj)
                    except Exception:
                        # If it can't be parsed, leave it as is
                        pass
        
        return result
    except Exception as e:
        logger.error(f"Error converting dict timestamps to IST: {e}")
        return data
