from django.db import models

class Login(models.Model):
    username = models.CharField(max_length=50, unique=True)  # Roll No (e.g., ITA700)
    password = models.CharField(max_length=100)             # Admission No (e.g., 2022PE0000)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'login'
    
    def __str__(self):
        return self.username