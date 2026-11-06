"""Play Store screenshots from the real web build with sample data.

1. flutter build web --release, then serve build/web on 127.0.0.1:8768.
2. dart run tool/store_screenshot_state.dart progress > tool/state_progress.json
   dart run tool/store_screenshot_state.dart earned > tool/state_earned.json
3. python tool/capture_store_screenshots.py docs/images/play-store
   (needs Python Playwright and Microsoft Edge).
"""
import json, os, sys
from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
URL = "http://127.0.0.1:8768/"
W, H, DPR = 360, 720, 3  # 1080 x 2160, Play's 2:1 limit; whole-number ratio
STATE = {k: open(os.path.join(HERE, f"state_{k}.json"), encoding="utf-8").read().strip()
         for k in ("progress", "earned")}
TABS = {"Today": 60, "Plan": 180, "Journey": 300}


def shoot(p, name, state, time, scheme, steps):
    browser = p.chromium.launch(channel="msedge", headless=True)
    ctx = browser.new_context(viewport={"width": W, "height": H}, device_scale_factor=DPR,
                              color_scheme=scheme, is_mobile=True, has_touch=True)
    ctx.add_init_script(f"localStorage.setItem('daylock.state.v2', {json.dumps(json.dumps(STATE[state]))});")
    page = ctx.new_page()
    page.clock.install(time=time)
    page.goto(URL)
    page.wait_for_timeout(5000)
    page.evaluate("() => document.querySelector('flt-semantics-placeholder')?.click()")
    page.wait_for_timeout(600)
    for kind, val in steps:
        if kind == "tab":
            page.mouse.click(TABS[val], H - 40)
        elif kind == "label":
            page.locator(f'flt-semantics[aria-label="{val}"]').first.click(force=True)
        elif kind == "text":
            page.locator("flt-semantics").get_by_text(val, exact=True).last.click(force=True)
        elif kind == "has":
            page.locator("flt-semantics").filter(has_text=val).last.click(force=True)
        elif kind == "tap":
            page.mouse.click(*val)
        elif kind == "type":
            page.keyboard.type(val, delay=25)
        elif kind == "scroll":
            page.mouse.move(W / 2, H / 2)
            page.mouse.wheel(0, val)
        page.wait_for_timeout(1200)
    page.mouse.move(1, H / 2)  # away from scrollbars and tooltips
    page.wait_for_timeout(1800)
    page.screenshot(path=os.path.join(OUT, name))
    print("saved", name)
    browser.close()


with sync_playwright() as p:
    shoot(p, "1-today.png", "progress", "2026-11-13T09:40:00", "dark", [])
    shoot(p, "2-freedom-earned.png", "earned", "2026-11-13T18:30:00", "dark", [])
    shoot(p, "3-plan.png", "progress", "2026-11-13T20:30:00", "dark", [("tab", "Plan")])
    shoot(p, "4-add-commitment.png", "progress", "2026-11-13T20:30:00", "dark",
          [("tab", "Plan"), ("has", "Add a commitment"), ("tap", (180, 456)), ("type", "Meditate for 10 minutes"),
           ("text", "Mind")])
    shoot(p, "5-journey.png", "progress", "2026-11-13T21:00:00", "dark", [("tab", "Journey")])
    shoot(p, "6-journey-weeks.png", "progress", "2026-11-13T21:00:00", "dark",
          [("tab", "Journey"), ("scroll", 700), ("scroll", 700), ("scroll", 700)])
    shoot(p, "7-settings.png", "progress", "2026-11-13T12:00:00", "dark",
          [("tap", (322, 38))])
    shoot(p, "8-today-light.png", "progress", "2026-11-13T12:30:00", "light", [])
