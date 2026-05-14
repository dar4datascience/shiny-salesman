import subprocess
import time
import os
from playwright.sync_api import sync_playwright
from PIL import Image

APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAMES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "frames")
ASSETS_DIR = os.path.join(APP_DIR, "assets")
GIF_PATH = os.path.join(ASSETS_DIR, "demo.gif")
APP_URL = "http://127.0.0.1:7456"


def wait_for_app():
    """Block until the app responds."""
    import urllib.request
    for _ in range(30):
        try:
            with urllib.request.urlopen(APP_URL, timeout=1):
                return True
        except Exception:
            time.sleep(1)
    return False


def screenshot(page, name, frames):
    path = os.path.join(FRAMES_DIR, f"{name}.png")
    page.screenshot(path=path)
    frames.append(Image.open(path))


def click_shadow_button(page, host_selector, button_selector, timeout=5000):
    """Click a button inside an open shadow DOM."""
    page.evaluate(
        f"""
        ({{
            host: '{host_selector}',
            btn: '{button_selector}'
        }}) => {{
            const el = document.querySelector(host)?.shadowRoot?.querySelector(btn);
            if (el) el.click();
        }}
        """
    )


def main():
    os.makedirs(FRAMES_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)

    proc = subprocess.Popen(
        ["R", "-e", f"shiny::runApp('{APP_DIR}', port=7456, launch.browser=FALSE)"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    try:
        if not wait_for_app():
            print("App did not start in time")
            return

        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1400, "height": 950})
            page.goto(APP_URL)

            # Wait for the map to render
            page.wait_for_selector("#map img, .shiny-plot-output", timeout=30000)
            time.sleep(2)

            frames = []

            # 1. Initial state
            screenshot(page, "01_initial", frames)

            # 2. Toggle dark mode (button lives inside shadow DOM of bslib-input-dark-mode)
            click_shadow_button(
                page,
                "bslib-input-dark-mode",
                'button[data-theme="dark"]',
            )
            time.sleep(1.5)
            screenshot(page, "02_dark_mode", frames)

            # Toggle back to light mode
            click_shadow_button(
                page,
                "bslib-input-dark-mode",
                'button[data-theme="light"]',
            )
            time.sleep(1.5)
            screenshot(page, "03_light_mode", frames)

            # 3. Switch map to USA using selectize
            map_input = page.locator("#map_name-selectized")
            map_input.click()
            time.sleep(0.5)
            usa_option = page.locator('.selectize-dropdown-content .option[data-value="USA"]')
            if usa_option.count() > 0:
                usa_option.click()
                time.sleep(2)
            screenshot(page, "04_usa_map", frames)

            # 4. Click "Set Cities Randomly"
            page.locator("#set_random_cities_2").click()
            time.sleep(2)
            screenshot(page, "05_random_cities", frames)

            # 5. Click SOLVE and capture progress
            page.locator("#go_button").click()
            time.sleep(2)
            screenshot(page, "06_solving", frames)
            time.sleep(4)
            screenshot(page, "07_solved", frames)

            browser.close()

        if frames:
            frames[0].save(
                GIF_PATH,
                save_all=True,
                append_images=frames[1:],
                duration=1500,
                loop=0,
            )
            print(f"GIF saved to {GIF_PATH}")
        else:
            print("No frames captured")

    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    main()
