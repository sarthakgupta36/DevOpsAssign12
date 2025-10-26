#!/usr/bin/env python
"""
Script to run Django development server with proper setup
"""
import os
import sys
from django.core.management import execute_from_command_line

def main():
    """Run the Django development server"""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mysite.settings')
    
    print("Starting Django development server...")
    print("Make sure to run migrations first if you haven't already:")
    print("  python manage.py migrate")
    print("\nServer will be available at: http://127.0.0.1:8000/")
    print("Press Ctrl+C to stop the server\n")
    
    try:
        execute_from_command_line(['manage.py', 'runserver', '0.0.0.0:8000'])
    except KeyboardInterrupt:
        print("\nServer stopped.")

if __name__ == '__main__':
    main()