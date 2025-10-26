# Generated migration for updated Login model

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='login',
            name='username',
            field=models.CharField(max_length=50, unique=True),
        ),
        migrations.AlterField(
            model_name='login',
            name='password',
            field=models.CharField(max_length=100),
        ),
        migrations.AddField(
            model_name='login',
            name='created_at',
            field=models.DateTimeField(auto_now_add=True, null=True),
        ),
        migrations.AlterModelTable(
            name='login',
            table='login',
        ),
    ]