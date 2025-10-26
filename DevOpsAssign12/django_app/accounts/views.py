from django.shortcuts import render, redirect
from django.contrib import messages
from django.db import IntegrityError
from .models import Login

def register_view(request):
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '').strip()
        
        if not username or not password:
            messages.error(request, 'Both username and password are required.')
            return render(request, 'register.html')
        
        try:
            # Check if user already exists
            if Login.objects.filter(username=username).exists():
                messages.error(request, 'User already exists. Please choose a different username.')
                return render(request, 'register.html')
            
            # Create new user
            Login.objects.create(username=username, password=password)
            messages.success(request, 'Registration successful! You can now log in.')
            return redirect('login')
            
        except IntegrityError:
            messages.error(request, 'User already exists. Please choose a different username.')
            return render(request, 'register.html')
        except Exception as e:
            messages.error(request, 'An error occurred during registration. Please try again.')
            return render(request, 'register.html')
    
    return render(request, 'register.html')


def login_view(request):
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '').strip()
        
        if not username or not password:
            messages.error(request, 'Both username and password are required.')
            return render(request, 'login.html')
        
        try:
            # Authenticate user
            user = Login.objects.get(username=username, password=password)
            request.session['username'] = user.username
            return redirect('home')
            
        except Login.DoesNotExist:
            messages.error(request, 'Invalid credentials. Please try again.')
            return render(request, 'login.html')
        except Exception as e:
            messages.error(request, 'An error occurred during login. Please try again.')
            return render(request, 'login.html')

    return render(request, 'login.html')


def home_view(request):
    username = request.session.get('username')
    if not username:
        messages.info(request, 'Please log in to access the home page.')
        return redirect('login')
    
    return render(request, 'home.html', {'username': username})


def logout_view(request):
    request.session.flush()
    messages.success(request, 'You have been logged out successfully.')
    return redirect('login')
