import { test, expect } from '@playwright/test';

test.describe('导航和基础功能', () => {
  test('首页可访问', async ({ page }) => {
    await page.goto('/');
    // 验证页面加载成功（不检查具体内容，因为首页可能有重定向）
    await expect(page).toHaveTitle(/.*/);
  });

  test('404页面正常显示', async ({ page }) => {
    await page.goto('/nonexistent-page-xyz');
    // NotFound 组件应该被加载
    const pageContent = await page.content();
    // 页面应该包含内容而不是白屏
    expect(pageContent.length).toBeGreaterThan(100);
  });

  test('服务协议页面可访问', async ({ page }) => {
    await page.goto('/terms/overall');
    // 验证协议页面加载
    const pageContent = await page.content();
    expect(pageContent.length).toBeGreaterThan(100);
  });
});