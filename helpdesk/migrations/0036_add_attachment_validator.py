# Generated by Django 3.2.7 on 2021-10-05 10:21

from django.db import migrations, models
import helpdesk.models
import helpdesk.validators


class Migration(migrations.Migration):
    dependencies = [
        ("helpdesk", "0035_alter_email_on_ticket_change"),
    ]

    operations = [
        migrations.AlterField(
            model_name="followupattachment",
            name="file",
            field=models.FileField(
                max_length=1000,
                upload_to=helpdesk.models.attachment_path,
                validators=[helpdesk.validators.validate_file_extension],
                verbose_name="File",
            ),
        ),
        migrations.AlterField(
            model_name="kbiattachment",
            name="file",
            field=models.FileField(
                max_length=1000,
                upload_to=helpdesk.models.attachment_path,
                validators=[helpdesk.validators.validate_file_extension],
                verbose_name="File",
            ),
        ),
    ]
