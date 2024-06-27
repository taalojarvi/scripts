import requests
from bs4 import BeautifulSoup
import urllib.robotparser
import time  # for sleep between requests

def check_url(url):
  """
  Checks if a URL is working by sending a GET request with a User-Agent header.

  Args:
      url: The URL to check.

  Returns:
      True if the URL responds with a successful status code, False otherwise.
  """
  headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36'}
  try:
    response = requests.get(url, headers=headers)
    response.raise_for_status()  # Raise exception for unsuccessful status codes
    return True
  except requests.exceptions.RequestException:
    return False

def find_urls(base_url, max_depth=5):
  """
  Crawls a website to find all sub-URLs using links from the HTML, with a maximum depth limit.

  Args:
      base_url: The base URL of the website.
      max_depth: The maximum depth of recursion for crawling (default: 2).

  Returns:
      A list of all discovered sub-URLs.
  """
  all_urls = []
  visited_urls = set()
  robots_parser = urllib.robotparser.RobotFileParser()
  robots_parser.set_url(f"{base_url}/robots.txt")
  robots_parser.read()

  # Fetch initial response
  response = requests.get(base_url)
  if response.status_code == 200:
    soup = BeautifulSoup(response.content, 'html.parser')
  else:
    print(f"Error retrieving {base_url}")
    return []

  # Extract links from the HTML
  for link in soup.find_all('a', href=True):
    url = link['href']

    # Check if URL is relative and starts with a slash
    if url.startswith('/'):
      url = f"{base_url}{url}"
    elif not url.startswith('http'):
      continue  # Skip non-http links

    # Check robots.txt for allowed URLs and limit depth
    if robots_parser.can_fetch("*", url) and max_depth > 0:
      if url not in visited_urls:
        visited_urls.add(url)
        print(url)
        all_urls.append(url)
        # Recursively crawl discovered sub-URLs with reduced depth
        sub_urls = find_urls(url, max_depth-1)
        all_urls.extend(sub_urls)
        time.sleep(0.1)  # Add a small delay between requests

  return all_urls

def main():
  """
  Prompts user for a website URL, crawls the website with a depth limit, and checks for working sub-URLs.
  """
  base_url = "http://www.efluniversity.ac.in/images/documents/"
  # Find all URLs on the website
  all_urls = find_urls(base_url)

  # Check functionality of each URL
  working_urls = [url for url in all_urls if check_url(url)]

  print("Found URLs:")
  for url in all_urls:
    print(url)

  print("\nWorking URLs:")
  for url in working_urls:
    print(url)

if __name__ == "__main__":
  main()
