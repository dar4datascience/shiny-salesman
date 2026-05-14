import subprocess
import time
import os
from playwright.sync_api import sync_playwright
from PIL import Image

APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAMES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "frames")
ASSETS_DIR = os.path.join(APP_DIR, "assets")
GIF_PATH = os.path.join(ASSETS_DIR, "demo.gif")

def main():
    os.makedirs(FRAMES_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)

    # Start the Shiny app in the background
    proc = subprocess.Popen(
        ["R", "-e", f"shiny::runApp('{APP_DIR}', port=7456, launch.browser=FALSE)"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    try:
        # Wait for the app to start
        time.sleep(8)

        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1280, "height": 900})
            page.goto("http://localhost:7456")

            # Wait for initialization
            page.wait_for_selector(".selectize-input", timeout=30000)
            time.sleep(2)

            frames = []

            def screenshot(name):
                path = os.path.join(FRAMES_DIR, f"{name}.png")
                page.screenshot(path=path)
                frames.append(Image.open(path))

            # Initial state
            screenshot("01_initial")

            # Click dark mode toggle
            dark_toggle = page.locator('button[data-theme="light"]')
            if dark_toggle.count() > 0:
                dark_toggle.click()
                time.sleep(1)
                screenshot("02_dark_mode")
                # Toggle back to light
                dark_toggle = page.locator('button[data-theme="dark"]')
                if dark_toggle.count() > 0:
                    dark_toggle.click()
                    time.sleep(1)
                    screenshot("03_light_mode")

            # Select a city via Selectize
            page.click(".selectize-input")
            time.sleep(0.5)
            option = page.locator('.option[data-value="New York, USA"]')
            if option.count() > 0:
                option.click()
                time.sleep(0.5)
            screenshot("04_select_city")

            # Click SOLVE
            solve_btn = page.locator("#go_button")
            if solve_btn.count() > 0:
                solve_btn.click()
                time.sleep(3)
                screenshot("05_solving")
                time.sleep(3)
                screenshot("06_solved")

            browser.close()

        # Compile GIF
        if frames:
            frames[0].save(
                GIF_PATH,
                save_all=True,
                append_images=frames[1:],
                duration=1000,
                loop=0,
            )
            print(f"GIF saved to {GIF_PATH}")
        else:
            print("No frames captured")

    finally:
        proc.terminate()
        proc.wait()

if __name__ == "__main__":
    main()
