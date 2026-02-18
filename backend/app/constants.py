# Allowed file types for upload
ALLOWED_FILE_TYPES = [
    # Common image formats
    "image/jpeg",
    "image/jpg", 
    "image/png",
    "image/gif",
    "image/webp",
    "image/bmp",
    "image/tiff",
    "image/svg+xml",
    
    # HEIC/HEIF formats (iPhone photos)
    "image/heic",
    "image/heif",
    
    # Video formats
    "video/mp4",
    "video/mpeg",
    "video/quicktime", # .mov files
    "video/x-msvideo", # .avi files
    "video/webm",
    "video/ogg",
    "video/3gpp", # .3gp files
    "video/x-ms-wmv", # .wmv files
    "video/x-flv", # .flv files
    "video/x-matroska", # .mkv files
]

# File extensions for Flask-WTF FileAllowed validator
ALLOWED_FILE_EXTENSIONS = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'svg',
    'heic', 'heif',
    'mp4', 'mpeg', 'mov', 'avi', 'webm', 'ogg', '3gp', 'wmv', 'flv', 'mkv'
]
