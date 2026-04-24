import { test, expect } from '@playwright/test';

// These tests require the full E2E environment to be running
// Start with: ./e2e/scripts/start-e2e-env.sh start

test.describe('注册流程 - 完整E2E测试', () => {
  test('注册页面正确加载', async ({ page }) => {
    await page.goto('/signup/TESTAGENT001X');

    // 等待页面加载 - 检查 h1 标签
    await expect(page.locator('h1')).toContainText('注册', { timeout: 10000 });
  });

  test('注册表单元素完整显示', async ({ page }) => {
    await page.goto('/signup/TESTAGENT001X');

    // 手机号输入框 - 使用更精确的选择器
    await expect(page.locator('input').first()).toBeVisible();

    // 密码输入框（代理注册需要）
    await expect(page.locator('input[type="password"]').first()).toBeVisible();

    // 协议复选框
    await expect(page.locator('text=服务协议')).toBeVisible();
  });

  test('注册表单验证 - 空手机号', async ({ page }) => {
    await page.goto('/signup/TESTAGENT001X');

    // 勾选协议
    await page.locator('input[type="checkbox"]').check();

    // 点击下一步
    await page.click('button:has-text("下一步")');

    // 应该显示验证错误 - ant-design 表单错误
    await expect(page.locator('.ant-form-item-explain-error').first()).toBeVisible({ timeout: 5000 });
  });

  test('注册表单验证 - 未勾选协议', async ({ page }) => {
    await page.goto('/signup/TESTAGENT001X');

    // 填写手机号
    await page.locator('input').first().fill('13999999999');

    // 不勾选协议，点击下一步
    await page.click('button:has-text("下一步")');

    // 应该显示协议错误 - ant-design 表单错误
    await expect(page.locator('.ant-form-item-explain-error').first()).toBeVisible({ timeout: 5000 });
  });

  test('无效邀请码提示', async ({ page }) => {
    await page.goto('/signup/INVALIDCODE');

    // 等待验证 - Ant Design message toast
    await page.waitForTimeout(2000);

    // 应该显示无效邀请码提示 (message.error)
    await expect(page.locator('.ant-message')).toBeVisible({ timeout: 5000 });
  });

  test('学生注册流程加载', async ({ page }) => {
    await page.goto('/signup/TESTSTUDENT00');

    // 等待页面加载
    await expect(page.locator('h1')).toContainText('注册', { timeout: 10000 });

    // 应该显示学生身份选择
    await expect(page.locator('text=学生')).toBeVisible();
    await expect(page.locator('text=家长')).toBeVisible();
  });

  test('注册表单填写', async ({ page }) => {
    await page.goto('/signup/TESTAGENT001X');

    // 等待页面加载
    await page.waitForLoadState('networkidle');

    // 填写手机号
    await page.locator('input').first().fill('13999999999');

    // 验证手机号已填入
    await expect(page.locator('input').first()).toHaveValue('13999999999');
  });
});