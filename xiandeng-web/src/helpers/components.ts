import type { ItemType } from 'ant-design-vue';
import { VueElement } from 'vue';

export function getMenuItem(
    label: VueElement | string,
    key: string,
    icon?: any,
    children?: ItemType[],
    type?: 'group',
  ): ItemType {
    return {
      key,
      icon,
      children,
      label,
      type,
    } as ItemType;
}