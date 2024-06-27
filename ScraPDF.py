import requests
from bs4 import BeautifulSoup
import os

def download_file(url, filename):
    """Downloads a file from the specified URL and saves it with the given filename.

    Args:
        url (str): The URL of the file to download.
        filename (str): The name of the file to save.
    """

    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()  # Raise an exception for failed downloads

        with open(filename, 'wb') as f:
            for chunk in response.iter_content(1024):
                f.write(chunk)

        print(f"Downloaded: {filename}")
    except requests.exceptions.RequestException as e:
        print(f"Error downloading {filename}: {e}")

def check_robots_txt(url):
    """Checks the website's robots.txt for download restrictions.

    Args:
        url (str): The base URL of the website.

    Returns:
        bool: True if downloading is allowed, False otherwise.
    """

    robots_url = f"{url}/robots.txt"
    try:
        response = requests.get(robots_url)
        if response.status_code == 200:
            content = response.text
            for line in content.splitlines():
                if line.lower().startswith("disallow: "):
                    disallowed_path = line.split()[1]
                    if disallowed_path in url:
                        print(f"Downloading from {url} is disallowed by robots.txt")
                        return True
        else:
            print(f"robots.txt not found or inaccessible at {robots_url}")
    except requests.exceptions.RequestException as e:
        print(f"Error checking robots.txt: {e}")

    return True

def download_images_and_pdfs(url):
    """Downloads PDFs, JPGs, and PNGs from the specified URL and its subpages.

    Args:
        url (str): The base URL of the website to crawl.
    """

    if not check_robots_txt(url):
        return

    visited = set()  # Keep track of visited URLs to avoid duplicates

    def crawl(url):
        if url in visited:
            return

        visited.add(url)

        try:
            response = requests.get(url)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')

            for link in soup.find_all('a'):
                href = link.get('href')
                if href and (href.endswith('.pdf') or href.endswith(('.jpg', '.png'))):
                    download_url = f"{url}/{href}" if not href.startswith('http') else href
                    filename = os.path.basename(download_url)
                    download_file(download_url, filename)

            for img in soup.find_all('img'):
                src = img.get('src')
                if src and (src.endswith('.jpg') or src.endswith('.png')):
                    download_url = f"{url}/{src}" if not src.startswith('http') else src
                    filename = os.path.basename(download_url)
                    download_file(download_url, filename)

            # Recursively crawl subpages (be mindful of crawl depth and politeness)
            for link in soup.find_all('a', href=True):
                subpage_url = link['href']
                if subpage_url.startswith(url) and subpage_url not in visited:
                    crawl(subpage_url)

        except requests.exceptions.RequestException as e:
            print(f"Error crawling {url}: {e}")

    crawl(url)

# Example usage (replace with the actual website URL)
website_url = "https://www.efluniversity.ac.in/images/Meet A Leading Light/"
download_images_and_pdfs(website_url)
