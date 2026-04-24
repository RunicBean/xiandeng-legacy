import { test, expect } from '@playwright/test';

// These tests require the full E2E environment to be running
// Start with: ./e2e/scripts/start-e2e-env.sh start

test.describe('登录流程 - 完整E2E测试', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('手机号密码登录 - 空手机号应显示错误', async ({ page }) => {
    await page.click('text=手机号密码登录');

    // 不填写手机号，直接点击登录
    await page.getByLabel('密码').fill('TestPassword123');
    await page.click('button:has-text("登录")');

    // 应该显示验证错误
    await expect(page.locator('.ant-form-item-explain-error').first()).toBeVisible({ timeout: 5000 });
  });

  test('手机号密码登录 - 空密码应显示错误', async ({ page }) => {
    await page.click('text=手机号密码登录');

    await page.getByLabel('手机号').fill('13800138001');
    await page.click('button:has-text("登录")');

    // 应该显示验证错误
    await expect(page.locator('.ant-form-item-explain-error').first()).toBeVisible({ timeout: 5000 });
  });

  test('手机号密码登录 - 错误密码应显示错误通知', async ({ page }) => {
    await page.click('text=手机号密码登录');

    await page.getByLabel('手机号').fill('13800138001');
    await page.getByLabel('密码').fill('WrongPassword123');
    await page.click('button:has-text("登录")');

    // 等待并检查错误通知出现 (ant-design-vue notification)
    await expect(page.locator('.ant-notification')).toBeVisible({ timeout: 5000 });
  });

  test('微信登录Tab显示二维码', async ({ page }) => {
    // 默认应该在微信登录Tab
    await expect(page.getByRole('tab', { name: '微信登录' })).toBeVisible();

    // 应该显示二维码容器
    await expect(page.locator('.wx-qrcode-container')).toBeVisible();
  });

  test('Tab切换正常', async ({ page }) => {
    // 默认微信登录Tab激活
    const wxTab = page.getByRole('tab', { name: '微信登录' });
    await expect(wxTab).toHaveAttribute('aria-selected', 'true');

    // 切换到手机号密码登录
    await page.click('text=手机号密码登录');
    const phoneTab = page.getByRole('tab', { name: '手机号密码登录' });
    await expect(phoneTab).toHaveAttribute('aria-selected', 'true');

    // 切换回微信登录
    await page.click('text=微信登录');
    await expect(wxTab).toHaveAttribute('aria-selected', 'true');
  });

  test('登录页面所有元素可交互', async ({ page }) => {
    await page.click('text=手机号密码登录');

    // 检查表单元素
    const phoneInput = page.getByLabel('手机号');
    const passwordInput = page.getByLabel('密码');
    const loginButton = page.locator('button:has-text("登录")');

    await expect(phoneInput).toBeEnabled();
    await expect(passwordInput).toBeEnabled();
    await expect(loginButton).toBeEnabled();

    // 输入数据
    await phoneInput.fill('13800138001');
    await passwordInput.fill('TestPassword123');

    // 验证数据已填入
    await expect(phoneInput).toHaveValue('13800138001');
    await expect(passwordInput).toHaveValue('TestPassword123');
  });
});