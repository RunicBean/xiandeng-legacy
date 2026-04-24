import { test, expect } from '@playwright/test';

test.describe('注册流程', () => {
  test('注册页面正常加载', async ({ page }) => {
    await page.goto('/signup/testref');
    await expect(page.locator('text=注册')).toBeVisible();
  });

  test('手机号输入框可见', async ({ page }) => {
    await page.goto('/signup/testref');
    await expect(page.locator('input').first()).toBeVisible();
  });

  test('协议复选框可见', async ({ page }) => {
    await page.goto('/signup/testref');
    await expect(page.locator('text=服务协议')).toBeVisible();
  });
});