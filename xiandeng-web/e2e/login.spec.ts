import { test, expect } from '@playwright/test';

test.describe('登录流程', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('登录页面加载成功', async ({ page }) => {
    // 验证登录卡片存在
    await expect(page.locator('.box-card')).toBeVisible();
  });

  test('切换到手机号密码登录', async ({ page }) => {
    await page.click('text=手机号密码登录');
    // 使用更精确的 label 定位
    await expect(page.getByLabel('手机号')).toBeVisible();
    await expect(page.getByLabel('密码')).toBeVisible();
  });

  test('手机号输入框可交互', async ({ page }) => {
    await page.click('text=手机号密码登录');
    const phoneInput = page.getByLabel('手机号');
    await expect(phoneInput).toBeEnabled();
  });

  test('密码输入框可交互', async ({ page }) => {
    await page.click('text=手机号密码登录');
    const passwordInput = page.getByLabel('密码');
    await expect(passwordInput).toBeEnabled();
  });

  test('微信登录Tab默认激活', async ({ page }) => {
    await expect(page.getByRole('tab', { name: '微信登录' })).toBeVisible();
  });
});