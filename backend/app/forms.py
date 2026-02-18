from flask_wtf import FlaskForm
from flask_wtf.file import FileField, FileAllowed
from wtforms import StringField, PasswordField, BooleanField, SubmitField, TextAreaField, HiddenField
from wtforms.validators import DataRequired, Email, EqualTo, ValidationError
from wtforms import SelectField
from .models import User
from .constants import ALLOWED_FILE_EXTENSIONS

class RegistrationForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    password2 = PasswordField(
        'Repeat Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register')

class LoginForm(FlaskForm):
    email = StringField('Email'
                        , validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    remember_me = BooleanField('Remember Me')
    submit = SubmitField('Sign In')

class UserContentForm(FlaskForm):
    title = StringField('Title', validators=[DataRequired()])
    body = TextAreaField('Story', validators=[DataRequired()])
    submit = SubmitField('Post Story')
    thumbnail = FileField('Thumbnail', validators=[FileAllowed(ALLOWED_FILE_EXTENSIONS, 'File type not allowed!')])
    location = SelectField('Location', choices=[
        ('', 'Select a location'),
        ('Ballard', 'Ballard'),
        ('Belltown', 'Belltown'),
        ('Bellevue', 'Bellevue'),
        ('Capitol Hill', 'Capitol Hill'),
        ('Central District', 'Central District'),
        ('Fremont', 'Fremont'),
        ('Green Lake', 'Green Lake'),
        ('Georgetown', 'Georgetown'),
        ('Kirkland', 'Kirkland'),
        ('Magnolia', 'Magnolia'),
        ('Queen Anne', 'Queen Anne'),
        ('Rainier Valley', 'Rainier Valley'),
        ('Redmond', 'Redmond'),
        ('Pioneer Square', 'Pioneer Square'),
        ('South Lake Union', 'South Lake Union'),
        ('University District', 'University District'),
        ('West Seattle', 'West Seattle')
    ])

    
class CommentForm(FlaskForm):
    content = TextAreaField('Comment', validators=[DataRequired()])
    content_type = HiddenField()  
    content_id = HiddenField() 
    submit = SubmitField('Post Comment')
    location = StringField('Location')   

class EditProfileForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    confirm_password = PasswordField('Confirm Password',
                                     validators=[DataRequired(), EqualTo('password')])
    profile_picture = FileField('Update Profile Picture', validators=[FileAllowed(ALLOWED_FILE_EXTENSIONS, 'File type not allowed!')])
    submit = SubmitField('Update')

class RequestPasswordForm(FlaskForm):
    email = StringField('Email Id', validators=[DataRequired(), Email()])
    submit = SubmitField('Request Password')

    def validate_email(self, email):
        user = User.query.filter_by(email=email.data).first()
        if not user:
            raise ValidationError('There is no account with this email, you need to register.')


class ResetPasswordForm(FlaskForm):
    password = PasswordField('New Password', validators=[DataRequired()])
    confirm_password = PasswordField('Confirm New Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Reset Password')