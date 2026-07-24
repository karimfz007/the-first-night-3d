import { expect, test } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";

const evidence = join(process.cwd(), "docs", "evidence", "web-control-repair");

async function waitForGame(page) {
  await page.waitForFunction(
    () => window.__tfn?.engineReady && window.__tfn?.gameReady,
    undefined,
    { timeout: 60_000 }
  );
}

async function runtime(page) {
  return page.evaluate(() => structuredClone(window.__tfn));
}

async function tapNormalized(page, point) {
  const viewport = page.viewportSize();
  await page.touchscreen.tap(point[0] * viewport.width, point[1] * viewport.height);
}

async function holdNormalized(page, point, duration = 650) {
  const viewport = page.viewportSize();
  const client = await page.context().newCDPSession(page);
  const touch = { x: point[0] * viewport.width, y: point[1] * viewport.height, id: 41, radiusX: 8, radiusY: 8 };
  await client.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [touch] });
  await page.waitForTimeout(duration);
  await client.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
  await client.detach();
}

async function dragTouch(page, start, end, id = 51) {
  const client = await page.context().newCDPSession(page);
  await client.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: start.x, y: start.y, id, radiusX: 8, radiusY: 8 }]
  });
  await client.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [{ x: end.x, y: end.y, id, radiusX: 8, radiusY: 8 }]
  });
  await page.waitForTimeout(250);
  await client.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
  await client.detach();
}

async function assertViewport(page) {
  const layout = await page.evaluate(() => {
    const canvas = document.querySelector("#canvas");
    const box = canvas.getBoundingClientRect();
    return {
      viewport: [window.innerWidth, window.innerHeight],
      canvas: [box.x, box.y, box.width, box.height],
      overflow: [
        document.documentElement.scrollWidth - document.documentElement.clientWidth,
        document.documentElement.scrollHeight - document.documentElement.clientHeight
      ]
    };
  });
  expect(layout.canvas[2]).toBeGreaterThanOrEqual(layout.viewport[0] - 2);
  expect(layout.canvas[3]).toBeGreaterThanOrEqual(layout.viewport[1] - 2);
  expect(layout.overflow[0]).toBeLessThanOrEqual(0);
  expect(layout.overflow[1]).toBeLessThanOrEqual(0);
}

test.beforeAll(async () => {
  await mkdir(evidence, { recursive: true });
});

test("desktop viewport, settings, focus, and responsive recovery", async ({ page }, testInfo) => {
  test.skip(testInfo.project.name !== "desktop-chromium");
  await page.goto("/");
  await waitForGame(page);
  await assertViewport(page);

  let state = await runtime(page);
  expect(state.settingsButtonVisible).toBe(true);
  expect(state.focusPromptVisible).toBe(true);
  await page.screenshot({ path: join(evidence, "desktop-initial.png") });

  await page.mouse.click(state.settingsButton[0] * 1440, state.settingsButton[1] * 900);
  await expect.poll(async () => (await runtime(page)).settingsOpen).toBe(true);
  expect(await page.evaluate(() => document.pointerLockElement)).toBeNull();
  await page.screenshot({ path: join(evidence, "desktop-settings.png") });

  state = await runtime(page);
  await page.mouse.click(state.settingsButton[0] * 1440, state.settingsButton[1] * 900);
  await expect.poll(async () => (await runtime(page)).settingsOpen).toBe(false);

  await page.mouse.click(720, 450);
  await expect.poll(async () => page.evaluate(() => document.pointerLockElement?.id ?? null)).toBe("canvas");
  await expect.poll(async () => (await runtime(page)).controlFocused).toBe(true);
  await page.keyboard.press("Escape");
  await expect.poll(async () => page.evaluate(() => document.pointerLockElement)).toBeNull();
  await expect.poll(async () => (await runtime(page)).focusPromptVisible).toBe(true);

  await page.setViewportSize({ width: 1280, height: 800 });
  await assertViewport(page);
  state = await runtime(page);
  expect(state.settingsButton[0]).toBeGreaterThan(0.8);
  expect(state.settingsButton[1]).toBeLessThan(0.2);
});

test("Android landscape exposes bounded multitouch controls", async ({ page }, testInfo) => {
  test.skip(testInfo.project.name !== "android-landscape");
  await page.goto("/");
  await waitForGame(page);
  await assertViewport(page);
  let state = await runtime(page);
  await page.screenshot({ path: join(evidence, "mobile-full-screen-layout.png") });
  await page.screenshot({ path: join(evidence, "mobile-joystick-and-actions.png") });
  expect(state.mobileControlsVisible).toBe(true);
  expect(state.joystick[0]).toBeGreaterThan(state.joystick[2]);
  expect(state.joystick[0] + state.joystick[2]).toBeLessThan(0.5);
  expect(state.joystick[1]).toBeGreaterThan(state.joystick[3]);
  expect(state.joystick[1] + state.joystick[3]).toBeLessThan(1);
  expect(state.lookRegion[0]).toBeGreaterThanOrEqual(0.5);
  expect(state.hotbarFirst[0]).toBeGreaterThan(0);
  expect(state.hotbarFirst[0]).toBeLessThan(1);

  const client = await page.context().newCDPSession(page);
  const move = { x: state.joystick[0] * 915, y: state.joystick[1] * 412, id: 1, radiusX: 10, radiusY: 10 };
  const look = { x: 0.72 * 915, y: 0.42 * 412, id: 2, radiusX: 10, radiusY: 10 };
  await client.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [move, look] });
  await client.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [
      { ...move, y: move.y - 45 },
      { ...look, x: look.x + 35 }
    ]
  });
  await expect.poll(async () => {
    const input = await runtime(page);
    return input.moveTouchActive && input.lookTouchActive;
  }).toBe(true);
  await client.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
  await client.detach();

  await tapNormalized(page, state.settingsButton);
  await expect.poll(async () => (await runtime(page)).settingsOpen).toBe(true);
  await tapNormalized(page, state.settingsButton);
  await expect.poll(async () => (await runtime(page)).settingsOpen).toBe(false);

  for (const viewport of [
    { width: 740, height: 360 },
    { width: 1024, height: 600 },
    { width: 412, height: 740 },
    { width: 915, height: 412 }
  ]) {
    await page.setViewportSize(viewport);
    await assertViewport(page);
    await expect.poll(async () => {
      const resized = await runtime(page);
      return resized.mobileControlsVisible
        && resized.joystick[0] > 0
        && resized.joystick[0] < 1
        && resized.joystick[1] > 0
        && resized.joystick[1] < 1
        && resized.hotbarFirst[0] > 0
        && resized.hotbarFirst[0] < 1;
    }).toBe(true);
  }

  const backgroundPage = await page.context().newPage();
  await backgroundPage.goto("about:blank");
  await backgroundPage.bringToFront();
  await backgroundPage.close();
  await page.bringToFront();
  await expect.poll(async () => (await runtime(page)).mobileControlsVisible).toBe(true);
  state = await runtime(page);
  await holdNormalized(page, [state.joystick[0], state.joystick[1] - state.joystick[3] * 0.5], 250);
  await expect.poll(async () => (await runtime(page)).moveTouchActive).toBe(false);
});

test("touch hotbar enters, cancels, and completes campfire placement", async ({ page }, testInfo) => {
  test.skip(testInfo.project.name !== "android-landscape");
  test.setTimeout(180_000);
  await page.goto("/?tfn_test=placement");
  await waitForGame(page);
  await expect.poll(async () => (await runtime(page)).fixtureReady).toBe(true);

  let state = await runtime(page);
  await tapNormalized(page, state.hotbarFirst);
  await expect.poll(async () => (await runtime(page)).placementMode).toBe(true);
  state = await runtime(page);
  expect(state.placementPiece).toBe("campfire");
  expect(state.placementInstructionsVisible).toBe(true);
  expect(state.mobilePlacementControlsVisible).toBe(true);
  expect(state.placementButtons).toHaveLength(3);

  await tapNormalized(page, state.placementButtons[1]);
  await expect.poll(async () => (await runtime(page)).placementMode).toBe(false);
  state = await runtime(page);
  await tapNormalized(page, state.hotbarFirst);
  await expect.poll(async () => (await runtime(page)).placementMode).toBe(true);

  await dragTouch(page, { x: 0.72 * 915, y: 0.28 * 412 }, { x: 0.72 * 915, y: 0.82 * 412 });
  await expect.poll(async () => (await runtime(page)).placementValid).toBe(true);
  await page.screenshot({ path: join(evidence, "fire-placement-preview.png") });

  state = await runtime(page);
  await tapNormalized(page, state.placementButtons[0]);
  await expect.poll(async () => (await runtime(page)).firePlacedCount).toBe(1);
  await expect.poll(async () => (await runtime(page)).placementMode).toBe(false);
  await page.screenshot({ path: join(evidence, "successfully-placed-fire.png") });

  state = await runtime(page);
  await holdNormalized(page, state.actionButtons.interact);
  await holdNormalized(page, state.actionButtons.interact);
  await expect.poll(async () => (await runtime(page)).fireLit).toBe(true);
});
