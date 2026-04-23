import { logCommonMessage } from "@/api/request/system";
import { WindowSize } from "./constants";

function getPrefixUrl() {
  if (import.meta.env.MODE == "development") {
    if (import.meta.env["VITE_ENABLE_LOCAL_DOMAIN"] == "1") {
      return `https://${import.meta.env["VITE_WEB_PREFIX"]}`
    }
    return `http://localhost:5173`
  } else {
    return `https://${import.meta.env["VITE_WEB_PREFIX"]}`
  }
}

let prefixUrl = getPrefixUrl()
let wsPrefixUrl = prefixUrl.replace(/^https/, "wss").replace(/^http/, "ws")

function buildWebUrl(path: string) {
    return prefixUrl + path
}

function appendOrgPrefixUrl(path: string, orgName?: string | string[]) {
    return (orgName ? "/org/" + orgName : "") + path
}

function appendOrgPrefixUrlWithQuery(path: string, orgName?: string | string[], query?: Record<string, string>) {
    return {path: (orgName ? "/org/" + orgName : "") + path, query}
}

function buildBackendUrl(path: string) {
    return buildWebUrl("/server/api/v1" + path)
}

function isFromWechatClient() {
  console.log(window.navigator);
  logCommonMessage(window.navigator.userAgent);

    return (
      window.navigator.userAgent.indexOf("Weixin") >= 0 ||
      window.navigator.userAgent.indexOf("MicroMessenger") >= 0 ||
    window.navigator.userAgent.indexOf("wechatdevtools") >= 0)
}

async function copyToClipboard(text: string) {
    try {
      await navigator.clipboard.writeText(text);
      alert('复制成功！');
    } catch (err) {
      console.error('复制失败: ', err);
      alert('复制失败！');
    }
  }

function checkWindowSize(
) {
    // 获取当前视窗宽度
    const width = window.innerWidth;


    // Tailwind 的默认断点
    if (width >= 1280) {
      // 大型屏幕
      return WindowSize.Large
    } else if (width >= 768) {
      // 中型屏幕
      return WindowSize.Medium
    } else {
      // 小型屏幕
      return WindowSize.Small
    }
}


export {

    prefixUrl,
    wsPrefixUrl,
    buildWebUrl,
    buildBackendUrl,
    appendOrgPrefixUrl,
    appendOrgPrefixUrlWithQuery,
    isFromWechatClient,
    copyToClipboard,
    checkWindowSize,
}
