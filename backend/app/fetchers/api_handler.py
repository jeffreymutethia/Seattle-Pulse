import requests 
import config as config
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import TimeoutException
from selenium import webdriver

class APIHandler:
    def get_news_data(self, source):
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }
        response = self.send_request(source, headers=headers)
        with open('/tmp/api_response.txt', 'w', encoding='utf-8') as file:
            file.write(response.text)
        if response:
            return response
        else:
            return None  
    
    def send_request(self, url, params=None, headers=None):
        try:
            response = requests.get(url, params=params, headers=headers)
            if response.status_code == 200:
                return response
            else:
                # Log error here
                print(f"Failed to retrieve data. Status code: {response.status_code}")
                return None
        except requests.RequestException as e:
            # Log exception here
            print(f"Request failed: {e}")
            return None