#!/usr/bin/env python
"""
Setup script for Django application
"""
import os
import sys
import subprocess

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"Running: {description}")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✓ {description} completed successfully")
        if result.stdout:
            print(f"Output: {result.stdout.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ {description} failed")
        print(f"Error: {e.stderr.strip()}")
        return False

def main():
    """Setup Django application"""
    print("Django Application Setup")
    print("=" * 40)
    
    # Change to django_app directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Install requirements
    if not run_command("pip install -r requirements.txt", "Installing Python dependencies"):
        print("Failed to install dependencies. Please install manually:")
        print("pip install -r requirements.txt")
        return
    
    # Run migrations
    if not run_command("python manage.py migrate", "Running database migrations"):
        print("Failed to run migrations. Please run manually:")
        print("python manage.py migrate")
        return
    
    # Create superuser (optional)
    print("\nOptional: Create a Django admin superuser")
    create_superuser = input("Do you want to create a superuser? (y/n): ").lower().strip()
    if create_superuser == 'y':
        run_command("python manage.py createsuperuser", "Creating superuser")
    
    print("\n" + "=" * 40)
    print("Setup completed!")
    print("\nTo start the development server, run:")
    print("  python manage.py runserver")
    print("  or")
    print("  python run_server.py")
    print("\nTo test the application, run:")
    print("  python test_app.py")
    print("\nApplication URLs:")
    print("  Login: http://127.0.0.1:8000/login/")
    print("  Register: http://127.0.0.1:8000/register/")
    print("  Admin: http://127.0.0.1:8000/admin/")

if __name__ == '__main__':
    main()