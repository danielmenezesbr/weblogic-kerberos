from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from retrying import retry
import traceback
import os
import logging
import sys

logger = logging.Logger('catch_all')

print("Download Oracle")

def download_progress(driver):
    result = False
    try:
        print(str(driver.execute_script('''return document.querySelector("downloads-manager").shadowRoot.querySelectorAll("downloads-item")[0].shadowRoot.querySelector("#description").textContent''')).strip())
        result = driver.execute_script(
            '''return document.querySelector("downloads-manager").shadowRoot.querySelectorAll("downloads-item")[0].shadowRoot.querySelector("#show").offsetParent !== null;''')
    except:
        print(".")

    return result


if (os.environ['ORACLE_SSO_USERNAME'] == ""):
    raise Exception('ORACLE_SSO_USERNAME is empty')

if (os.environ['ORACLE_SSO_PASSWORD'] == ""):
    raise Exception('ORACLE_SSO_PASSWORD is empty')

current_working_dir = os.getcwd()

options = Options()
options.add_argument("--disable-extensions")
options.add_experimental_option(
    'prefs', {
        'download.default_directory': current_working_dir,
        'profile.default_content_settings.popups': 0,
        'download.prompt_for_download': 'false'
    }
)

@retry(stop_max_attempt_number=3)
def download(url, css_link):
    driver = None
    try:
        print("Start download process...")
        driver = webdriver.Chrome(options=options)
        driver.get(url)
        print(driver.title)

        # logic
        WebDriverWait(driver, 20).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, css_link))).click()

        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'a[class="download-file icn-download-locked"]')))

        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'input[name=licenseAccept]')))
        elements = driver.find_elements_by_css_selector('input[name=licenseAccept]')
        elements[1].click()

        element = WebDriverWait(driver, 20).until(EC.presence_of_element_located((By.CSS_SELECTOR, 'div[class="obttn"]')))
        element.click()

        element = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, 'sso_username')))
        driver.execute_script("arguments[0].setAttribute('value', arguments[1])", element,
                              os.environ['ORACLE_SSO_USERNAME'])

        element = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, 'ssopassword')))
        driver.execute_script("arguments[0].setAttribute('value', arguments[1])", element,
                              os.environ['ORACLE_SSO_PASSWORD'])

        WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, 'signin_button'))).click()

        driver.get('chrome://downloads/')

        WebDriverWait(driver, 60 * 60).until(lambda driver: download_progress(driver))
        print("Download done")
        driver.close()
        driver.quit()
    except Exception as e:
        print("Download failed. Exception:")
        print(traceback.format_exception(None,  # <- type(e) by docs, but ignored
                                         e, e.__traceback__),
              file=sys.stderr, flush=True)
        raise Exception("Download failed.")
    finally:
        if driver != None:
            driver.quit()


download("https://www.oracle.com/java/technologies/javase-jce8-downloads.html", 'a[data-lbl="lightbox-open-jce_policy-8.zip"]')
download("https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html", 'a[data-lbl="lightbox-open-jdk-8u151-linux-x64.tar.gz"]')
download("https://www.oracle.com/middleware/technologies/weblogic-server-installers-downloads.html", 'a[data-file="//download.oracle.com/otn/nt/middleware/12c/12213/fmw_12.2.1.3.0_wls_Disk1_1of1.zip"]')