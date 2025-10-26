#!/usr/bin/env python
"""
Simple test script to verify Django app functionality
"""
import os
import sys
import django
from django.test import Client
from django.core.management import execute_from_command_line

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mysite.settings')
django.setup()

from accounts.models import Login

def test_django_app():
    """Test basic Django app functionality"""
    print("Testing Django Application...")
    
    # Test 1: Check if we can create the database tables
    try:
        print("1. Testing database connection...")
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        print("   ✓ Database connection successful")
    except Exception as e:
        print(f"   ✗ Database connection failed: {e}")
        return False
    
    # Test 2: Test model operations
    try:
        print("2. Testing model operations...")
        # Clear any existing test data
        Login.objects.filter(username__startswith='TEST').delete()
        
        # Create a test user
        test_user = Login.objects.create(username='TEST_ITA700', password='TEST_2022PE0000')
        print("   ✓ User creation successful")
        
        # Retrieve the user
        retrieved_user = Login.objects.get(username='TEST_ITA700')
        assert retrieved_user.password == 'TEST_2022PE0000'
        print("   ✓ User retrieval successful")
        
        # Clean up
        test_user.delete()
        print("   ✓ User deletion successful")
        
    except Exception as e:
        print(f"   ✗ Model operations failed: {e}")
        return False
    
    # Test 3: Test views with Django test client
    try:
        print("3. Testing views...")
        client = Client()
        
        # Test login page
        response = client.get('/login/')
        assert response.status_code == 200
        print("   ✓ Login page accessible")
        
        # Test register page
        response = client.get('/register/')
        assert response.status_code == 200
        print("   ✓ Register page accessible")
        
        # Test registration
        response = client.post('/register/', {
            'username': 'TEST_ITA701',
            'password': 'TEST_2022PE0001'
        })
        assert response.status_code == 302  # Redirect after successful registration
        print("   ✓ Registration functionality working")
        
        # Test login
        response = client.post('/login/', {
            'username': 'TEST_ITA701',
            'password': 'TEST_2022PE0001'
        })
        assert response.status_code == 302  # Redirect after successful login
        print("   ✓ Login functionality working")
        
        # Clean up test user
        Login.objects.filter(username='TEST_ITA701').delete()
        
    except Exception as e:
        print(f"   ✗ View testing failed: {e}")
        return False
    
    print("\n✅ All tests passed! Django app is working correctly.")
    return True

if __name__ == '__main__':
    # Run migrations first
    print("Running database migrations...")
    try:
        execute_from_command_line(['manage.py', 'migrate'])
        print("✓ Migrations completed successfully\n")
    except Exception as e:
        print(f"✗ Migration failed: {e}\n")
    
    # Run tests
    test_django_app()