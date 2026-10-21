import os
import re

files_with_dio = [
    "lib/app/data/services/filter_service.dart",
    "lib/app/data/services/force_update_service.dart",
    "lib/app/modules/users/users_controller.dart",
    "lib/app/modules/users/user_profile_news_controller.dart",
    "lib/app/modules/newslist/newslist_controller.dart",
    "lib/app/modules/create_news/create_news_controller.dart",
]

for file_path in files_with_dio:
    with open(file_path, 'r') as f:
        content = f.read()

    # Replace dio.Dio()
    content = content.replace('dio.Dio()', 'dio.Dio()..interceptors.add(dio.LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true))')
    
    # Replace Dio() but careful not to replace it if it's already modified
    content = re.sub(r'(?<!\.)Dio\(\)(?!\.\.)', 'Dio()..interceptors.add(LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true))', content)

    with open(file_path, 'w') as f:
        f.write(content)

with open("lib/app/data/services/api_service.dart", 'r') as f:
    content = f.read()

content = content.replace('LogInterceptor(requestBody: true, responseBody: true)', 'LogInterceptor(request: true, requestHeader: true, requestBody: true, responseHeader: true, responseBody: true, error: true)')

with open("lib/app/data/services/api_service.dart", 'w') as f:
    f.write(content)

print("Dio updated.")
