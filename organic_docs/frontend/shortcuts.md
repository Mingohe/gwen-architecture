# 快捷键系统模块 - 前端文档

> **返回**: [文档首页](../../README.md)

## 目录

- [1. 概述](#1-概述)
- [2. 系统架构](#2-系统架构)
- [3. 快捷键列表](#3-快捷键列表)
- [4. 组件说明](#4-组件说明)
- [5. Hook 使用说明](#5-hook-使用说明)
- [6. 作用域管理](#6-作用域管理)
- [7. 扩展开发](#7-扩展开发)
- [8. 注意事项](#8-注意事项)

---

## 1. 概述

### 1.1 模块边界与目的

快捷键系统是GWEN系统的全局功能模块，负责：

- **全局快捷键管理**: 统一的快捷键注册和管理机制
- **快捷键帮助面板**: 可视化展示所有可用快捷键（Ctrl+/ 或 Cmd+/）
- **命令面板**: 快速访问系统功能（Ctrl+K 或 Cmd+K）
- **作用域管理**: 支持全局/任务/笔记等不同作用域的快捷键
- **跨平台支持**: 自动识别 Windows/Linux/macOS 并使用对应修饰键

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **核心库**: @vueuse/core (useMagicKeys)
- **UI组件**: Ant Design Vue
- **状态管理**: Pinia

### 1.3 核心特性

- ✅ 全局快捷键管理
- ✅ 快捷键帮助面板（Ctrl+/ 或 Cmd+/）
- ✅ 命令面板（Ctrl+K 或 Cmd+K）
- ✅ 跨平台支持（Windows/Linux/macOS）
- ✅ 作用域管理（全局/任务/笔记等）
- ✅ 国际化支持
- ✅ 暗色主题支持

---

## 2. 系统架构

### 2.1 核心文件结构

```
src/
├── hooks/web/
│   ├── useShortcuts.ts          # 全局快捷键管理 Hook
│   ├── useTaskShortcuts.ts      # 任务管理快捷键 Hook
│   └── useNoteShortcuts.ts      # 笔记管理快捷键 Hook
├── components/Shortcut/
│   ├── ShortcutHelp.vue         # 快捷键帮助面板
│   └── CommandPalette.vue       # 命令面板
├── settings/
│   └── shortcutSetting.ts       # 快捷键配置
├── enums/
│   └── shortcutEnum.ts          # 快捷键枚举定义
└── layouts/default/
    └── index.vue                 # 全局快捷键注册入口
```

### 2.2 核心 Hook

#### 2.2.1 useShortcuts

**路径**: `src/hooks/web/useShortcuts.ts`

**功能**: 全局快捷键管理核心 Hook

**API**:
```typescript
interface UseShortcutsReturn {
  register: (key: ShortcutKeyEnum, handler: () => void, scope?: string) => void
  unregister: (key: ShortcutKeyEnum) => void
  isRegistered: (key: ShortcutKeyEnum) => boolean
  getAllShortcuts: () => ShortcutConfig[]
  getShortcutsByScope: (scope: string) => ShortcutConfig[]
}
```

#### 2.2.2 useTaskShortcuts

**路径**: `src/hooks/web/useTaskShortcuts.ts`

**功能**: 任务管理快捷键 Hook

**API**:
```typescript
interface TaskShortcutHandlers {
  onCreateTask?: () => void | Promise<void>
  onNextTask?: () => void | Promise<void>
  onPrevTask?: () => void | Promise<void>
  onOpenTask?: () => void | Promise<void>
  onCloseTask?: () => void | Promise<void>
  onExpandTask?: () => void | Promise<void>
  onCollapseTask?: () => void | Promise<void>
  onLayoutSingle?: () => void | Promise<void>
  onLayoutDouble?: () => void | Promise<void>
}
```

#### 2.2.3 useNoteShortcuts

**路径**: `src/hooks/web/useNoteShortcuts.ts`

**功能**: 笔记管理快捷键 Hook

**API**:
```typescript
interface NoteShortcutHandlers {
  onCreateNote?: () => void | Promise<void>
  onSaveNote?: () => void | Promise<void>
  onDeleteNote?: () => void | Promise<void>
  onNextNote?: () => void | Promise<void>
  onPrevNote?: () => void | Promise<void>
  onToggleEditMode?: () => void | Promise<void>
  onRequestEdit?: () => void | Promise<void>
  onReleaseEdit?: () => void | Promise<void>
  onShareNote?: () => void | Promise<void>
  // ... 更多处理器
}
```

---

## 3. 快捷键列表

### 3.1 全局快捷键

| 快捷键 | 功能 | 优先级 | 作用域 |
|--------|------|--------|--------|
| `Ctrl+/` 或 `Cmd+/` | 打开快捷键帮助面板 | 高 | global |
| `Ctrl+K` 或 `Cmd+K` | 打开命令面板 | 高 | global |
| `Ctrl+Shift+P` 或 `Cmd+Shift+P` | 全局搜索 | 高 | global |
| `Ctrl+Shift+K` 或 `Cmd+Shift+K` | 打开快速笔记 | 高 | global |
| `Ctrl+S` 或 `Cmd+S` | 保存当前内容 | 高 | global |
| `Ctrl+Z` 或 `Cmd+Z` | 撤销 | 高 | global |
| `Ctrl+Shift+Z` 或 `Cmd+Shift+Z` | 重做 | 高 | global |
| `Escape` | 取消/关闭 | 高 | global |

### 3.2 任务管理快捷键

| 快捷键 | 功能 | 优先级 | 作用域 |
|--------|------|--------|--------|
| `Alt+N` | 创建新任务 | 高 | global |
| `Ctrl+Enter` 或 `Cmd+Enter` | 完成/发布任务 | 高 | task |
| `J` 或 `↓` | 选择下一个任务 | 高 | task |
| `K` 或 `↑` | 选择上一个任务 | 高 | task |
| `Enter` | 打开任务详情 | 高 | task |
| `Escape` | 关闭任务详情 | 高 | task |
| `[` | 展开任务树 | 中 | task |
| `]` | 收起任务树 | 中 | task |
| `Alt+1` | 切换单列布局 | 中 | task |
| `Alt+2` | 切换双列布局 | 中 | task |
| `Ctrl+M` 或 `Cmd+M` | 为选中任务创建会议 | 高 | task |
| `Ctrl+Shift+G` 或 `Cmd+Shift+G` | 进入选中任务的会议 | 高 | task |
| `Ctrl+Alt+I` 或 `Cmd+Alt+I` | 为选中任务创建 Issue | 高 | task |

### 3.3 笔记管理快捷键

| 快捷键 | 功能 | 优先级 | 作用域 |
|--------|------|--------|--------|
| `Ctrl+Alt+N` 或 `Cmd+Alt+N` | 新建笔记 | 高 | note |
| `Ctrl+S` 或 `Cmd+S` | 保存笔记 | 高 | note |
| `Delete` | 删除笔记 | 中 | note |
| `Alt+↑` | 上一个笔记 | 中 | note |
| `Alt+↓` | 下一个笔记 | 中 | note |
| `Ctrl+F` 或 `Cmd+F` | 搜索笔记 | 高 | note |
| `Ctrl+E` 或 `Cmd+E` | 切换编辑/预览模式 | 高 | note |
| `Ctrl+Shift+E` 或 `Cmd+Shift+E` | 请求编辑权限 | 高 | note |
| `Ctrl+Shift+L` 或 `Cmd+Shift+L` | 释放编辑权限 | 中 | note |
| `Ctrl+Shift+S` 或 `Cmd+Shift+S` | 分享笔记 | 中 | note |
| `Ctrl+Shift+1` 或 `Cmd+Shift+1` | 切换到全部笔记 | 低 | note |
| `Ctrl+Shift+2` 或 `Cmd+Shift+2` | 切换到任务笔记 | 低 | note |
| `Ctrl+Shift+3` 或 `Cmd+Shift+3` | 切换到灵感笔记 | 低 | note |
| `Ctrl+Shift+4` 或 `Cmd+Shift+4` | 切换到其他笔记 | 低 | note |

### 3.4 会议管理快捷键

| 快捷键 | 功能 | 优先级 | 作用域 |
|--------|------|--------|--------|
| `Ctrl+M` 或 `Cmd+M` | 创建会议 | 高 | meeting |
| `Ctrl+Shift+G` 或 `Cmd+Shift+G` | 加入会议 | 高 | meeting |

### 3.5 Issue 管理快捷键

| 快捷键 | 功能 | 优先级 | 作用域 |
|--------|------|--------|--------|
| `Ctrl+Alt+I` 或 `Cmd+Alt+I` | 创建 Issue | 高 | issue |

---

## 4. 组件说明

### 4.1 ShortcutHelp - 快捷键帮助面板

**路径**: `src/components/Shortcut/ShortcutHelp.vue`

**功能**: 显示所有可用快捷键的列表，支持搜索和分类查看

**Props**:
```typescript
interface Props {
  open: boolean  // 控制面板显示/隐藏
}
```

**Events**:
- `@close`: 关闭面板时触发

**使用示例**:
```vue
<template>
  <ShortcutHelp :open="showHelp" @close="showHelp = false" />
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useShortcuts } from '/@/hooks/web/useShortcuts'
import { ShortcutKeyEnum } from '/@/enums/shortcutEnum'

const showHelp = ref(false)
const { register } = useShortcuts()

onMounted(() => {
  register(
    ShortcutKeyEnum.HELP,
    () => {
      showHelp.value = !showHelp.value
    },
    'global'
  )
})
</script>
```

### 4.2 CommandPalette - 命令面板

**路径**: `src/components/Shortcut/CommandPalette.vue`

**功能**: 类似 VS Code 的命令面板，快速访问系统功能

**Props**:
```typescript
interface Props {
  open: boolean  // 控制面板显示/隐藏
}
```

**Events**:
- `@close`: 关闭面板时触发
- `@execute`: 执行命令时触发，参数为命令 ID

**使用示例**:
```vue
<template>
  <CommandPalette
    :open="showCommand"
    @close="showCommand = false"
    @execute="handleCommand"
  />
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useShortcuts } from '/@/hooks/web/useShortcuts'
import { ShortcutKeyEnum } from '/@/enums/shortcutEnum'

const showCommand = ref(false)
const { register } = useShortcuts()

const handleCommand = (commandId: string) => {
  console.log('Execute command:', commandId)
  showCommand.value = false
}

onMounted(() => {
  register(
    ShortcutKeyEnum.COMMAND_PALETTE,
    () => {
      showCommand.value = !showCommand.value
    },
    'global'
  )
})
</script>
```

---

## 5. Hook 使用说明

### 5.1 全局快捷键注册

```typescript
import { useShortcuts } from '/@/hooks/web/useShortcuts'
import { ShortcutKeyEnum } from '/@/enums/shortcutEnum'

const { register, unregister } = useShortcuts()

onMounted(() => {
  // 注册快捷键
  register(
    ShortcutKeyEnum.QUICK_NOTE,
    () => {
      console.log('Open quick note')
      // 打开快速笔记逻辑
    },
    'global' // 作用域
  )
})

onUnmounted(() => {
  // 注销快捷键
  unregister(ShortcutKeyEnum.QUICK_NOTE)
})
```

### 5.2 任务管理快捷键

```typescript
import { useTaskShortcuts } from '/@/hooks/web/useTaskShortcuts'

const taskShortcuts = useTaskShortcuts({
  onCreateTask: () => {
    // 创建任务逻辑 (Alt+N)
    console.log('Create task')
  },
  onNextTask: () => {
    // 下一个任务 (J 或 ↓)
    currentIndex.value++
  },
  onPrevTask: () => {
    // 上一个任务 (K 或 ↑)
    currentIndex.value--
  },
  onOpenTask: () => {
    // 打开任务详情 (Enter)
    openTaskDetail(selectedTask.value)
  },
  onLayoutSingle: () => {
    // 切换单列布局 (Alt+1)
    setLayout('single')
  },
  onLayoutDouble: () => {
    // 切换双列布局 (Alt+2)
    setLayout('double')
  },
})
```

### 5.3 笔记管理快捷键

```typescript
import { useNoteShortcuts } from '/@/hooks/web/useNoteShortcuts'

const noteShortcuts = useNoteShortcuts({
  onCreateNote: () => {
    // 创建笔记 (Ctrl+Alt+N)
    createNewNote()
  },
  onSaveNote: () => {
    // 保存笔记 (Ctrl+S)
    saveCurrentNote()
  },
  onToggleEditMode: () => {
    // 切换编辑/预览模式 (Ctrl+E)
    isEditMode.value = !isEditMode.value
  },
  onSearchNote: () => {
    // 搜索笔记 (Ctrl+F)
    showSearchBox.value = true
  },
})
```

---

## 6. 作用域管理

### 6.1 作用域类型

快捷键系统支持以下作用域：

- `global`: 全局作用域，任何时候都可用
- `task`: 任务管理作用域，仅在任务页面激活
- `note`: 笔记管理作用域，仅在笔记页面激活
- `meeting`: 会议管理作用域
- `issue`: Issue 管理作用域

### 6.2 作用域切换

页面切换时会自动重置作用域为 `global`，特定页面的快捷键需要在组件挂载时注册对应作用域的快捷键。

### 6.3 输入框保护

在输入框、文本域等可编辑元素中，某些快捷键会被自动禁用，但保留以下快捷键：

- `Ctrl+S`: 保存
- `Ctrl+Z`: 撤销
- `Ctrl+Shift+Z`: 重做
- `Escape`: 取消

---

## 7. 扩展开发

### 7.1 添加新快捷键

#### 步骤 1: 添加枚举

在 `src/enums/shortcutEnum.ts` 中添加枚举：

```typescript
export enum ShortcutKeyEnum {
  // ... existing keys
  CUSTOM_NEW_ACTION = 'shortcut.custom.newAction',
}
```

#### 步骤 2: 添加配置

在 `src/settings/shortcutSetting.ts` 中添加配置：

```typescript
{
  key: ShortcutKeyEnum.CUSTOM_NEW_ACTION,
  keys: 'ctrl+shift+n,command+shift+n',
  description: '执行自定义操作',
  category: ShortcutCategoryEnum.GLOBAL,
  priority: ShortcutPriorityEnum.HIGH,
  scope: 'global',
}
```

#### 步骤 3: 注册使用

在组件中注册并使用：

```typescript
import { useShortcuts } from '/@/hooks/web/useShortcuts'
import { ShortcutKeyEnum } from '/@/enums/shortcutEnum'

const { register, unregister } = useShortcuts()

onMounted(() => {
  register(
    ShortcutKeyEnum.CUSTOM_NEW_ACTION,
    () => {
      console.log('Custom action triggered')
      // 执行自定义操作
    },
    'global'
  )
})

onUnmounted(() => {
  unregister(ShortcutKeyEnum.CUSTOM_NEW_ACTION)
})
```

### 7.2 创建模块专用 Hook

如果需要为特定模块创建快捷键 Hook，参考 `useTaskShortcuts.ts` 的实现：

```typescript
import { useShortcuts } from '/@/hooks/web/useShortcuts'
import { ShortcutKeyEnum } from '/@/enums/shortcutEnum'

export interface CustomShortcutHandlers {
  onCustomAction?: () => void | Promise<void>
}

export function useCustomShortcuts(handlers: CustomShortcutHandlers = {}) {
  const { register, unregister } = useShortcuts()

  onMounted(() => {
    if (handlers.onCustomAction) {
      register(
        ShortcutKeyEnum.CUSTOM_ACTION,
        handlers.onCustomAction,
        'custom'
      )
    }
  })

  onUnmounted(() => {
    unregister(ShortcutKeyEnum.CUSTOM_ACTION)
  })
}
```

---

## 8. 注意事项

### 8.1 浏览器兼容性

- 某些快捷键可能与浏览器默认行为冲突，已通过 `preventDefault()` 处理
- 避免使用浏览器保留的快捷键（如 `Ctrl+W` 关闭标签页）

### 8.2 操作系统差异

- 自动识别 macOS 并使用 `Cmd` 键，其他系统使用 `Ctrl` 键
- 快捷键配置中需要同时指定 `ctrl+key` 和 `command+key`

### 8.3 性能考虑

- 使用防抖避免重复触发
- 及时注销不需要的快捷键，避免内存泄漏

### 8.4 快捷键冲突

- 同一作用域内避免重复的快捷键组合
- 使用优先级机制处理冲突（高优先级覆盖低优先级）

### 8.5 输入框保护

- 在可编辑元素中，大部分快捷键会被禁用
- 保留的快捷键：保存、撤销、重做、取消

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

